class MapsController < ApplicationController

  def list
    @focus = focus
  end
  
  def send_simple_map
    send_map Focus::MindMapFactory.create_simple_map( focus, options )
  end
  
  def send_delta_map
    send_map Focus::MindMapFactory.create_delta_map( focus, from, to, :both_new_and_done, options ), "Recent-changes-#{period_description}.mm"
  end
  
  def send_done_map
    send_map Focus::MindMapFactory.create_delta_map( focus, from, to, :all_done, options ), "Recently-completed-#{period_description}.mm"
  end
  
  def send_new_project_map
    send_map Focus::MindMapFactory.create_delta_map( focus, from, to, :new_projects, options ), "Recently-added-projects-#{period_description}.mm"
  end
  
  def send_meta_map
    send_map Focus::MindMapFactory.create_meta_map( focus, options )
  end
  
  def custom_map
    from = parse_date( "map", "from" )
    to = parse_date( "map", "to" )
    choices = { :from => from, :to => to, :exclude => params[ :exclude ] }
    type = case params[ "commit" ] 
      #todo: this feels wrong
      when "Save as site-wide defaults"
        save_config choices
        return redirect_to :controller => :maps, :action => :list
      when "Completed"
        :all_done
      when "New projects"
        :new_projects 
      else :all
      end 
    show_weights = params[ "show weights" ]
    exclude = params[ "exclude" ].split( "," ).collect(&:strip)
    options = options().merge({ :EXCLUDE_NODES => exclude, :APPEND_WEIGHTS => show_weights })
    if type == :all
      send_map Focus::MindMapFactory.create_simple_map( focus, options )
    else
      send_map Focus::MindMapFactory.create_delta_map( focus, from, to, type, options )
    end
  end
    
  private
    def options
      { :EXCLUDE_NODES => focus_config.exclusions }
    end
    
    def send_map map_contents, filename = nil
      options = { :type => 'application/freemind' }
      options[ :filename ] = filename unless filename.nil?
      send_data map_contents, options
    end

    def period_description
      "#{from}_#{to}"
    end
    
    def from
     focus_config.period_start.to_s
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
