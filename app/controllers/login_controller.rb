require 'focus'

class LoginController < ApplicationController
    
  def form
    if session[ :focus ]
      redirect_to :controller => "maps", :action => "list"
    else
      @login = Login.new({})
    end
  end
  
  def retrieve_archive
    if !params[ :login ]
      session[ :focus ] = nil
      session[ :focus_date ] = nil
      redirect_to :controller => 'login', :action => 'form'
    else
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
      session[ :focus_date ] = Time.now.strftime("%Y.%m.%d %H:%M")
      flash[:notice] = "Archive retrieved and processed successfully"
    
      redirect_to :controller => "maps", :action => "list"
    end
  end

end
