class ApplicationController < ActionController::Base
  protect_from_forgery
  
  def info msg
    puts "#{self.class.name} was told: #{msg}"
    notice = Notice.new( msg )
    flash[:notice] ||= []
    flash[:notice] << notice
    
    session[:messages] ||= []
    session[:messages] << notice
    
  end
  
end
