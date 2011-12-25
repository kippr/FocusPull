class ApplicationController < ActionController::Base
  protect_from_forgery
  helper_method :focus, :focus_config, :mode
  
  def login=( login )
    session[ :login ] = login
  end
  
  def login
    session[ :login ] || raise( "Missing login" )
  end
  
  def focus
    time( "Getting focus for #{login.name}" ) do
      @focus ||= FocusStore.where( :username => login.name ).first.focus
      mode == :Project ? project_based_focus : context_based_focus
    end
  end

  def mode
    focus_config.mode
  end

  def context_based_focus
    @focus.extend( ContextBasedFocus )
  end

  def project_based_focus
    @focus.extend( ProjectBasedFocus )
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
    defaults.mode = choices[ :mode ]
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
      logger.info " --> Starting '#{msg}'"
      res = yield
      end_time = Time.now
      logger.info " <-- Done '#{msg}', took #{end_time - start_time} secs"
      res
  end
  
end

module ContextBasedFocus

  def children
    contexts
  end

end

module ProjectBasedFocus

  def children
    super
  end

end
