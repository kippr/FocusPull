class MessagesController < ApplicationController
  
  def current
    render :partial => 'shared/notice', :locals => { :msg => Notice.new( "Hello-#{Time.now}" ) }
  end
  
end