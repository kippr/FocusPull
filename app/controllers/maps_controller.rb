require 'focus'

class MapsController < ApplicationController
  
  def send_simple_map
    send_map Focus::MindMapFactory.create_simple_map( focus, options )
  end
  
  def send_delta_map
    send_map Focus::MindMapFactory.create_delta_map( focus, from, to, :both_new_and_done, options )
  end
  
  def send_done_map
    send_map Focus::MindMapFactory.create_delta_map( focus, from, to, :all_done, options )
  end
  
  def send_new_project_map
    send_map Focus::MindMapFactory.create_delta_map( focus, from, to, :new_projects, options )
  end
  
  def send_meta_map
    send_map Focus::MindMapFactory.create_meta_map( focus, options )
  end
  
  private
    def focus
      session[ :focus ]
    end
    
    def options
      options = { :EXCLUDE_NODES => [ 'Personal' ] }
    end
    
    def send_map( map_contents )
      send_data map_contents, :type => 'application/freemind'
    end
    
    def from
      25.days.ago.to_s
    end
    
    def to
      22.days.ago.to_s
      #Date.today.to_s
    end
  
end