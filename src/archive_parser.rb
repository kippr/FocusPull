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
  end

  def parse
    focus = Focus.new
    foreach_archive_xml do | content |
      #@log.debug( content )
      xml = Nokogiri::XML( content )
      #@log.debug( xml )
      projects = xml.xpath( '//xmlns:task/xmlns:project/..' ).map do | projectTaskNode |
        @log.debug( "Found node: #{projectTaskNode}")
        Project.new( projectTaskNode.xpath( './xmlns:name' ).first.content )
      end
      focus.projects = projects
    end
    focus
  end

  private
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

