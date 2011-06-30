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
  
  def custom_delta
    from = parse_date( "map", "from" )
    to = parse_date( "map", "to" )
    type = params[ "commit" ] == "Completed" ? :all_done : :new_projects 
    show_weights = params[ "show weights" ]
    exclude = params[ "exclude" ].split( "," ).collect(&:strip)
    options = options().merge({ :EXCLUDE_NODES => exclude, :APPEND_WEIGHTS => show_weights })
    send_map Focus::MindMapFactory.create_delta_map( focus, from.to_s, to.to_s, type, options )
  end
  
  private
    def options
      options = { :EXCLUDE_NODES => [ 'Personal' ] }
      #options = { :EXCLUDE_NODES => [  ] }
    end
    
    def send_map( map_contents )
      send_data map_contents, :type => 'application/freemind'
    end
    
    def from
      8.days.ago.to_s
    end
    
    def to
      Date.today.to_s
    end
    
    def parse_date( obj_name, field_name )
      Date.civil( params[ obj_name ][ "#{field_name}(1i)"].to_i,
                  params[ obj_name ][ "#{field_name}(2i)"].to_i,
                  params[ obj_name ][ "#{field_name}(3i)"].to_i)
    end
end