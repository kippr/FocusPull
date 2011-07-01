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
      
      prepare_for_retrieve
      
      download_archive

      parse_archive
    
      redirect_to :controller => "maps", :action => "list"
      
    end
  end
  
  def prepare_for_retrieve
    #todo: what is the best way to log in a rails app?
    self.login = Login.new( params[ :login ] )
  
    self.directory = "archives/#{Time.now.strftime("%Y.%m.%d")}"
    FileUtils.rm_rf( directory )
    FileUtils.mkpath( directory )
  end
  
  def download_archive
    archive = Focus::ArchivePull.download_archive( login.name, login.password )

    archive.save("#{directory}/#{filename}")
    logger.debug "Saved #{filename}"
  end
  
  def parse_archive
    parser = Focus::FocusParser.new( directory, filename, login.name)
    store_focus( parser.parse )
    session[ :focus_user ]= login.name

    info "Archive retrieved and processed successfully"    
  end
  
    def login=( login )
      session[ :login ] = login
    end
    
    def login
      session[ :login ] || raise( "Missing login" )
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
