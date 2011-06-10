class ApplicationController < ActionController::Base
  protect_from_forgery
  
  def info msg
    logger.info "#{self.class.name} was told: #{msg}"
    notice = Notice.new( msg )
    flash[:notice] ||= []
    flash[:notice] << notice
  end
  
end
