class MessagesController < ApplicationController
  
  def current
    render :partial => 'shared/notice', :locals => { :msg => [ "notice", "notice-#{Time.now.to_i}", "Hello - #{Time.now}" ] }
  end
  
end