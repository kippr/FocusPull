require 'focus'

class MapsController < ApplicationController
  
  def send_simple_map
    send_map Focus::MindMapFactory.create_simple_map( focus )
  end
  
  def send_delta_map
    
  end
  
  private
    def focus
      session[ :focus ]
    end
    
    def send_map( map_contents )
      send_data map_contents, :type => 'application/freemind'
    end
  
end