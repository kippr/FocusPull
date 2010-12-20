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
  end

  def parse
    foreach_archive_xml do | content |
      xml = Nokogiri::XML( content )
      
      parse_tasks( xml ) 
      
    end
    
    @focus
  end

  private
    
    def parse_tasks( xml )
      xml.xpath( '/xmlns:omnifocus/xmlns:task' ).each do | taskNode |
        @log.debug( "Found node: #{taskNode}")
        name = taskNode.xpath( './xmlns:name' ).first.content
        project = taskNode.at_xpath( './xmlns:project' )
        unless project.nil?
          @focus.add_project( Project.new( name ) ) 
        end
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

