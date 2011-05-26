require 'focus'

class MapsController < ApplicationController
  
  def send_simple_map
    options = {  }

    log = Logger.new(STDOUT)

    log.info "Saving simple map"
    focus = session[ :focus ]
    simple_map = Focus::MindMapFactory.create_simple_map focus, options
  
    send_data simple_map, :type => 'application/freemind'
  
  end
  
end