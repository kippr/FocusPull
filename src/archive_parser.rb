require 'rubygems'
require 'logger'

  @log = Logger.new(STDOUT)

  def unpack_archive( directory, filename, username)
    @log.debug("untarring #{directory}/#{filename} for #{username}")
    command = "tar xf #{directory}/#{filename}"
    success = system(command)
    raise "Could not untar #{filename}" unless success && $?.exitstatus == 0
    
    FileUtils.mv(username, directory)
    
    @log.debug("unzipping entries in archive, #{directory}/#{username}/OmniFocus.ofocus/")
    Dir.foreach("#{directory}/#{username}/OmniFocus.ofocus/") do | file |
      if( /\.zip$/ =~ file )
        @log.debug("Found zip file #{file}")
      end
    end
    
    @log.debug("Cleaning up afterwards")
    FileUtils.rm_r("#{directory}/#{username}")
    return "Ok"
  end
  
  def parse( directory, filename, username )
    unpack_archive( directory, filename, username )
  end

