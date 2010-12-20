require 'rubygems'
require 'logger'
require 'zip/zipfilesystem'
require 'nokogiri'

require File.join(File.dirname(__FILE__), 'focus')



class FocusParser

  def initialize( directory, filename, username )
    @log = Logger.new(STDOUT)
    
    @directory = directory
    @filename = filename
    @username = username
    
    @focus = Focus.new
    @refs = Hash.new
  end

  def parse
    foreach_archive_xml do | content |
      xml = Nokogiri::XML( content )
      
      parse_tasks( xml ) 
      
      parse_folders( xml )
      
    end
    
    resolve_links
    
    @focus
  end

  private
    
    #todo: remove duplication with parse_folders
    def parse_tasks( xml )
      xml.xpath( '/xmlns:omnifocus/xmlns:task' ).each do | taskNode |
        @log.debug( "Found node: #{taskNode}")
        name = taskNode.at_xpath( './xmlns:name' ).content
        projectNode = taskNode.at_xpath( './xmlns:project' )
        unless projectNode.nil?
          project = Project.new( name )
          
          statusNode = projectNode.at_xpath( './xmlns:status' )
          project.status = statusNode.content unless statusNode.nil?
          
          track_links( project, projectNode )
          
          @focus.add_project( project ) 
        end
      end
    end
    
    def parse_folders( xml )
      xml.xpath('/xmlns:omnifocus/xmlns:folder').each do | folderNode |
        @log.debug( "Found folder: #{folderNode} with id #{folderNode.attr( "id")}" )
        
        name = folderNode.at_xpath( './xmlns:name' ).content
        folder = Folder.new( name )
        track_links( folder, folderNode )        
    
        @focus.add_folder( folder )
      end
    end
    
    # This is going to need cleanup, esp when we get to tasks, where path is different
    def track_links( folder, folderNode )
      #keep track of links for parent <-> kids
      parentLink = folderNode.at_xpath( './xmlns:folder/@idref' )
      @log.debug( "Found parent link to #{parentLink}" )
      # need the 'or' for project nodes, which are structured as sub-els of tasks
      @refs[ folderNode.attr( "id") || folderNode.parent.attr('id')]  = folder 
      folder.parent = parentLink && parentLink.content   
    end
    
    def resolve_links
      @log.debug( "Resolving links for #{@refs}")
      @refs.each_pair do | id, node |
        # replace the string key ref we stored on each node with the actual parent
        node.parent = @refs[ node.parent ]
        # then add a backlink, registering child with parent
        node.parent.children << node unless node.parent.nil?
      end
    end
    
    def foreach_archive_xml
      @log.debug( "untarring #{@directory}/#{@filename} for #{@username}" )
      begin
        command = "tar xf #{@directory}/#{@filename}"
        success = system( command )
        raise "Could not untar #{@filename}" unless success && $?.exitstatus == 0
        
        FileUtils.mv( @username, @directory )
        
        @log.debug( "unzipping entries in archive, #{@directory}/#{@username}/OmniFocus.ofocus/" )
        full_path = "#{@directory}/#{@username}/OmniFocus.ofocus"
        Dir.foreach( full_path ) do | file |
          if( /\.zip$/ =~ file )
            @log.debug("Found zip file #{file}")
            Zip::ZipFile.open( "#{full_path}/#{file}" ) do |zipfile|
              yield zipfile.file.read( "contents.xml" )
            end
          end
        end
        return "Ok"
      ensure
        @log.debug("Cleaning up afterwards")
        FileUtils.rm_r("#{@directory}/#{@username}")
      end
    end
  
end

