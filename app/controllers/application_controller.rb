class ApplicationController < ActionController::Base
  protect_from_forgery
  helper_method :focus, :focus_config
  
  def login=( login )
    session[ :login ] = login
  end
  
  def login
    session[ :login ] || raise( "Missing login" )
  end
  
  def focus
    time("Getting focus for #{login.name}") { @focus ||= FocusStore.where( :username => login.name ).first.focus }
  end

  def store_focus focus
    record = FocusStore.find_or_create_by_username( login.name )
    record.focus = focus
    record.save
    # todo: use focus updated attribute instead
    session[ :focus_date ] = Time.now.strftime("%Y.%m.%d %H:%M")
  end
  
  def focus_config
    session[ :focus_config ] ||= FocusConfig.new
  end

  def save_config choices
    defaults = focus_config
    defaults.exclusions = choices[ :exclude ]
    defaults.period_start = choices[ :from ]
    session[ :focus_config ] = defaults 
  end

  def info msg
    logger.info "#{self.class.name} was told: #{msg}"
    notice = Notice.new( msg )
    flash[:notice] ||= []
    flash[:notice] << notice
  end
  
  def time msg
      start_time = Time.now
      logger.debug " --> Starting '#{msg}'"
      res = yield
      end_time = Time.now
      logger.debug " <-- Done '#{msg}', took #{end_time - start_time} secs"
      res
  end
  
end
