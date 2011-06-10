class ApplicationController < ActionController::Base
  protect_from_forgery
  
  def focus
    session[ :focus ]
  end

  def focus=
    session[ :focus ] = focus
    session[ :focus_date ] = Time.now.strftime("%Y.%m.%d %H:%M")
  end
  
  def info msg
    logger.info "#{self.class.name} was told: #{msg}"
    notice = Notice.new( msg )
    flash[:notice] ||= []
    flash[:notice] << notice
  end
  
end
