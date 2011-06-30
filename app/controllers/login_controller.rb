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
      info "Released archive, please login again"
      redirect_to :controller => 'login', :action => 'form'
    else
      #todo: what is the best way to log in a rails app?
      login = Login.new( params[ :login ] )
    
      directory = "archives/#{Time.now.strftime("%Y.%m.%d")}"
      FileUtils.rm_rf(directory)
      FileUtils.mkpath(directory)
      filename = "omnisync.tar"

      archive = Focus::ArchivePull.download_archive( login.name, login.password )

      archive.save("#{directory}/#{filename}")
      logger.debug "Saved #{filename}"

      parser = Focus::FocusParser.new( directory, filename, login.name)
      store_focus( parser.parse )
      session[ :focus_user ]= login.name

      info "Archive retrieved and processed successfully"    
      
    
      redirect_to :controller => "maps", :action => "list"
    end
  end  

end
