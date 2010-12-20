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
    
    @focus
  end

  private
    
    def parse_tasks( xml )
      xml.xpath( '/xmlns:omnifocus/xmlns:task' ).each do | taskNode |
        @log.debug( "Found node: #{taskNode}")
        name = taskNode.at_xpath( './xmlns:name' ).content
        projectNode = taskNode.at_xpath( './xmlns:project' )
        unless projectNode.nil?
          project = Project.new( name )
          
          statusNode = projectNode.at_xpath( './xmlns:status' )
          project.status = statusNode.content unless statusNode.nil?
          
          @focus.add_project( project ) 
        end
      end
    end
    
    def parse_folders( xml )
      xml.xpath('/xmlns:omnifocus/xmlns:folder').each do | folderNode |
        @log.debug( "Found folder: #{folderNode}" )
        name = folderNode.at_xpath( './xmlns:name' ).content
        folder = Folder.new( name )
        @focus.add_folder( folder )
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

