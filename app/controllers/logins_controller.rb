require 'focus'

class LoginsController < ApplicationController
    
  def index
    @login = Login.new({})
  end
  
  def create
    
    #todo: what is the best way to log in a rails app?
    log = Logger.new(STDOUT)
    login = Login.new( params[ :login ] )
    puts @login.inspect
    
    directory = "archives/#{Time.now.strftime("%Y.%m.%d")}"
    FileUtils.rm_rf(directory)
    FileUtils.mkpath(directory)
    filename = "omnisync.tar"

    archive = Focus::ArchivePull.download_archive( login.name, login.password )
    archive.save("#{directory}/#{filename}")
    log.info("Saved #{filename} into #{directory}")

    parser = Focus::FocusParser.new( directory, filename, login.name)
    focus = parser.parse
    
    session[ :focus] = focus
    session[ :focus_date ] = directory
    flash[:notice] = "Archive retrieved and processed successfully"
  end

end
