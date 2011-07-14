class LoginController < ApplicationController
    
  def form
    if session[ :focus ]
      redirect_to :controller => "maps", :action => "list"
    else
      @login = Login.new({})
    end
  end
  
  def release_archive
    reset_session
    info "Released archive, please login again"
    redirect_to :controller => 'login', :action => 'form'
  end
  
  def prepare_for_retrieve
    #todo: what is the best way to log in a rails app?
    self.login = Login.new( params[ :login ] )
  
    self.directory = "archives/#{Time.now.strftime("%Y.%m.%d")}"
    FileUtils.rm_rf( directory )
    FileUtils.mkpath( directory )
    
    render :xml => "<li>Logged in; Starting download...</li>"
  end
  
  def download_archive
    archive = Focus::ArchivePull.download_archive( login.name, login.password )

    archive.save("#{directory}/#{filename}")
    logger.debug "Saved #{filename}"
    render :xml => "<li>Download complete; Parsing...</li>"
  end
  
  def parse_archive
    logger.debug "Starting parsing"    
    parser = Focus::FocusParser.new( directory, filename, login.name)
    session[ :focus_user ]= login.name
    store_focus( parser.parse )

    info "Archive retrieved and processed successfully"    
    
    redirect_to :controller => "maps", :action => "list"    
  end
      
    def directory=( dir )
      session[ :directory ] = dir
    end
    
    def directory
      session[ :directory ] || raise( "Missing directory" )
    end
    
    def filename
      "omnisync.tar"
    end
    

end
