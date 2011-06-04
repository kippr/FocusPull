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
      reset_session
      redirect_to :controller => 'login', :action => 'form'
    else
      #todo: what is the best way to log in a rails app?
      login = Login.new( params[ :login ] )
    
      directory = "archives/#{Time.now.strftime("%Y.%m.%d")}"
      FileUtils.rm_rf(directory)
      FileUtils.mkpath(directory)
      filename = "omnisync.tar"

      archive = Focus::ArchivePull.download_archive( login.name, login.password, self )
      archive.save("#{directory}/#{filename}")
      info "Saved #{filename}"

      parser = Focus::FocusParser.new( directory, filename, login.name)
      focus = parser.parse
    
      session[ :focus] = focus
      session[ :focus_date ] = Time.now.strftime("%Y.%m.%d %H:%M")
      session[ :focus_user ]= login.name
      
      info "Archive retrieved and processed successfully"
    
      redirect_to :controller => "maps", :action => "list"
    end
  end
  
  def info msg
    puts "Controller was told: #{msg}"
    flash[:notice] ||= []
    flash[:notice] << msg
  end

end
