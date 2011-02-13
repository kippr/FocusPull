module ElementMixin

  def initialize( stack )
    @stack = stack
  end
  
  def element
    @stack.last
  end
  
  def add_child( name, *args )
    child = element.document.create_element( name, *args )
    element << child
    if block_given?
      @stack << child
      yield
      @stack.pop
    end
    child
  end  
end


class MindMapFactory
  
  # todo: sensible values?
  AGED_PROJECTS=90
  AGED_ACTIONS=45 
  APPEND_WEIGHTS=false # used to eyeball weighting
  
  #todo: this makes me want to weep... As soon as I add an html node, a whole bunch of 
  # tests start failing. Namespace issue with a magic html node? No idea :(
  # This hack just skips adding the html nodes
  class << self
    attr_accessor :failing_test_hack
  end

  # todo: refactor duplication
  def self.create_simple_map focus, user_options = {}
    simple_options = {
      :HIGHLIGHT_ACTIVE_TASKS => false,
      :STATUSES_TO_INCLUDE => [ :active, :inactive, :dropped ]
    }
    options = default_options.merge( simple_options ).merge( user_options )
    filter = StatusFilter.new( options[ :STATUSES_TO_INCLUDE ] )
    simple_map focus, filter, options
  end
  
  def self.create_delta_map focus, start_date, end_date, filter_option = :both_new_and_done, user_options = {}
    delta_options = { :WEIGHTED_STATUSES => [ :active, :done ] }
    filter = TemporalFilter.new( start_date, end_date, filter_option )
    options = default_options.merge( delta_options ).merge( user_options )
    simple_map focus, filter, options
  end
  
  def self.create_meta_map focus, user_options = {}
    meta_options = {
      :FOLD_TASKS => false, 
      :FORMATTING => false, 
      :WEIGHT_EDGES => false, 
      :ADD_ICONS => false
    }
    options = default_options.merge( meta_options ).merge( user_options )
    stack = [create_doc]
    visitors = create_visitors( stack, MapFilter.new, options )
    map = MetaMap.new( stack, focus, visitors )
    map.create
  end

  def self.default_options
    { 
      :FORMATTING => true, 
      :FOLD_TASKS => true, 
      :HIGHLIGHT_ACTIVE_TASKS => true,
      :WEIGHT_EDGES => true,
      :WEIGHTED_STATUSES => [ :active ],
      :ADD_ICONS => true,
      :ADD_ATTRIBUTES => false,
      :EXCLUDE_NODES => []
    }
  end
      
  private   
  
    def self.simple_map focus, filter, options
      stack = [create_doc]
      visitors = create_visitors( stack, filter, options )
      map = SimpleMap.new( stack, focus, visitors, filter, options[ :EXCLUDE_NODES ] )
      map.create
    end
  
    def self.create_doc
      doc = Nokogiri::XML::Document.new()
      map = doc.create_element( "map", :version => '0.9.0' )
      doc << map
      map << doc.create_element( "attribute_registry", :SHOW_ATTRIBUTES => 'hide' )
      map
    end
    
    def self.create_visitors( stack, filter, options )
      v = []
      v << Namer.new( stack, filter )
      v << Formatter.new( stack, filter ) if options[ :FORMATTING ]
      v << ActionCollapser.new( stack, filter ) if options[ :FOLD_TASKS ]
      v << IconStamper.new( stack, filter, options[ :HIGHLIGHT_ACTIVE_TASKS ] ) if options[ :ADD_ICONS ]
      v << Edger.new( stack, filter, options[ :WEIGHTED_STATUSES ] ) if options[ :WEIGHT_EDGES ]
      v << AttributeStamper.new( stack ) if options[ :ADD_ATTRIBUTES ]
      v << PositionStamper.new( stack )
    end  
end

#todo: options needed?
class SimpleMap
  include ElementMixin
  
  def initialize( stack, focus, visitors, filter, nodes_to_exclude )
    super( stack )
    @focus = focus
    @visitors = visitors
    @filter = filter
    @nodes_to_exclude = nodes_to_exclude
  end
  
  def create
    push = lambda{ | x, item | visit( item ) }
    pop = lambda{ | x, item | @stack.pop }
    @focus.traverse( nil, push, pop) { | n | !@nodes_to_exclude.include? n.name }
    @stack.first
  end
  
  def visit item
    if @filter.include?( item )
      @stack << add_child( "node" )
      @visitors.each{ | visitor | visitor.accept item }
    else
      # this is a shame, but how else to deal with pop?
      @stack << nil
    end
  end
  
end
  
class MetaMap
  include ElementMixin

  def initialize( stack, focus, visitors )
    super( stack )
    @focus = focus
    @visitors = visitors
  end

  def create
    add_child( "node", :TEXT => "Meta" ) do
        
      add_child( "node", :TEXT => "By status", :POSITION => "right" ) do
        add_by_status :projects, :active, :done, :inactive, :dropped
        add_by_status :actions, :active, :done
      end
      
      add_child( "node", :TEXT => "Actionless projects", :POSITION => "left", :FOLDED => 'true' ) do
        @focus.projects.select{ |p| p.active? && p.children.empty? }.each{ |p| add_item_node p }
      end

      add_aged :projects
      add_aged :actions
        
    end
    @stack.first
  end

  private
  
    def add_by_status item_type, *statuses
      add_child( "node", :TEXT => item_type.capitalize  ) do
        statuses.each do | status |
          items = @focus.send( item_type ).select{ |n| n.status == status }
          add_child( "node", :TEXT => "#{status.capitalize}: #{items.size}", :FOLDED => "true" ) do
            items.each do | item |
              add_item_node item
            end
          end
        end
      end
    end
    
    def add_aged item_type
      old_age = MindMapFactory.const_get "AGED_#{item_type.upcase}"
      aged = @focus.send( item_type ).select{  |i| i.age >= old_age && !i.done?}
      add_child( "node", :TEXT => "Aged #{item_type} (#{aged.size})", :POSITION => "left", :FOLDED => 'true' ) do
        aged.each do | item |
          add_item_node item
        end
      end
    end
      
    
    def add_item_node item
      add_child( "node" ) do
        @visitors.each{ | visitor | visitor.accept item }
      end
    end
end


class Namer 
  include ElementMixin, VisitorMixin

  def initialize( stack, filter )
    super( stack )
    @filter = filter
  end
  
  def visit_default item
    element['TEXT'] = item.name
  end
  
  def visit_focus focus
    add_child( "richcontent", :TYPE => "NODE" ) do
      @stack << add_child( "html" ) unless MindMapFactory.failing_test_hack
      add_child( "body" ) do
        add_child( "p", :style => "text-align: center" ) do
          add_child( "font", :SIZE => 4 ).content = "Portfolio" 
        end
        add_child( "p", :style => "text-align: center" ) do
          add_child( "font", :SIZE => 2 ).content = @filter.label( focus )     
        end
      end
      @stack.pop unless MindMapFactory.failing_test_hack
    end
  end
  
end

class Formatter
  include ElementMixin, VisitorMixin
  
  def initialize( stack, filter )
    super( stack )
    @filter = filter
  end
  
  def visit_folder this_folder
    element['STYLE'] = 'bubble'
    kids = this_folder.select{ | kid | kid != this_folder && @filter.include?( kid ) }
    childless = kids.all?( &:is_folder? )
    element['COLOR'] = childless ? '#bfd8e5' : '#006699' 
  end
  
  def visit_project project
    element['STYLE'] = 'fork'
    if project.on_hold? || project.dropped?
      element['COLOR'] = "#666666"
      add_child "font", :ITALIC => 'true', :NAME => 'SansSerif', :SIZE => '12' 
    end
    # this fades projects only included because kids are accepted, when they themselves 
    # aren't (accept tests only self, include? also tests kids)
    element['COLOR'] = "#666666" unless @filter.accept project
  end
  
  def visit_action action
    element['STYLE'] = 'fork'
    element['COLOR'] = "#444444"
    add_child "font", :NAME => "SansSerif", :SIZE => "9"
  end
  
end

class ActionCollapser
  include ElementMixin, VisitorMixin
  
  def initialize( stack, filter )
    super( stack )
    @filter = filter
  end
  
  def visit_project project
    element['FOLDED'] = 'true' if project.any?{ | kid | kid != project && @filter.include?( kid ) }
  end
  
end

class IconStamper
  include ElementMixin, VisitorMixin
  
  def initialize( stack, filter, highlight_active_actions )
    super( stack )
    @filter = filter
    @highlight_active_actions = highlight_active_actions
  end
  
  def visit_project project
    add_active_icon if @highlight_active_actions && is_a_new( project )
    add_on_hold_icon if project.on_hold?
    add_dropped_icon if project.dropped?
    add_done_icon if project.done?
  end
  
  def visit_action action
    add_active_icon if @highlight_active_actions && is_a_new( action )
    add_done_icon if action.done?
  end
  
  def is_a_new item
    item.active? && @filter.accept( item )
  end
  
  def add_active_icon
    add_child "icon", :BUILTIN => 'idea'
  end

  def add_dropped_icon
    add_child "icon", :BUILTIN => 'button_cancel'
  end

  def add_on_hold_icon
    add_child "icon", :BUILTIN => 'stop-sign'
  end

  def add_done_icon
    add_child "icon", :BUILTIN => 'button_ok'
  end
  
end

class Edger
  include ElementMixin
  
  def initialize( stack, filter, statuses_to_weight )
    super( stack )
    @weight_calculator = WeightCalculator.new( filter, statuses_to_weight )
    @fader = ColourFader.new_with_zero( '#cccccc', '#00ff33', '#ffff00' )
    @max = 20
  end
  
  def accept item
    weight = @weight_calculator.weigh item
    add_child "edge", :COLOR => to_colour( weight ), :WIDTH => weight <= @max ? 1 : 2
    element['TEXT'] = "#{element['TEXT']} %2.2f" % weight if MindMapFactory::APPEND_WEIGHTS
  end
    
  def to_colour( weight )
    col_max = @max * 0.75
    weight = [ weight, col_max ].min.to_f
    ratio = weight / col_max
    @fader.at ratio
  end
  
end

# Weighs each item in the tree, returning a percentage for each item
# This percentage is the relative weight of this branch to overall tree weight
# N.B. not all nodes contribute: projects are heavier than actions, folders are not weighed
# Additionally, only items accepted by @filter contribute weight
class WeightCalculator
  include VisitorMixin
  
  def initialize( filter, statuses_to_weight )
    @filter = filter
    @statuses_to_weight = StatusFilter.new( statuses_to_weight )
  end
  
  def weigh item
    # assumption: we will always start at root
    # so run once 'unweighted' to get total tree, then run again
    @total = weigh_subtree( item ) + 0.00001 unless @total # avoid div by zero
    # actual run, with total definitely set
    weight = weigh_subtree( item )
    # don't let the subtree actually get a higher weight than the 'raw' weight in case of small trees
    [ weight / @total * 100, weight ].min
  end
  
  def weigh_subtree item
    item.inject( 0 ) do | weight, child |
      weight + accept( child )
    end
  end
    
  def accept item
    @filter.accept( item ) && @statuses_to_weight.accept( item ) ? item.visit( self ) : 0
  end
  
  def visit_project project
    3
  end

  def visit_action action
    1
  end
  
  def visit_default item
    0
  end
  
end

class AttributeStamper
  include ElementMixin, VisitorMixin
  
  def visit_project project
    add_status_for project
    add_dates_for project
  end
  
  def visit_action action
    add_status_for action
    add_dates_for action
  end
  
  def add_status_for item
    add_child "attribute", :NAME => 'status', :VALUE => item.status
  end
  
  def add_dates_for item
    add_child( "attribute", :NAME => 'created', :VALUE => item.created_date.to_s )
    add_child( "attribute", :NAME => 'updated', :VALUE => item.updated_date.to_s ) if item.updated_date
    add_child( "attribute", :NAME => 'completed', :VALUE => item.completed_date.to_s ) if item.done?
  end
    
end

class PositionStamper
  include ElementMixin
  
  def accept item
    stamp_position if item.parent && item.parent.is_root?
  end
  
  def stamp_position
    element['POSITION'] = next_pos
  end
  
  def next_pos
    @pos = @pos == "right" ? "left" : "right"
  end
  
end

# todo: does visitor make sense for filters?
class MapFilter
  include VisitorMixin
  
  def include? item
    item.any?{ | c | self.accept( c ) }
  end
  
  def visit_default item
    true
  end
    
  def label item
    Date.today
  end
  
end

class StatusFilter < MapFilter
  
  def initialize statuses_to_include
    @statuses_to_include = statuses_to_include
  end
  
  def visit_project project
    @statuses_to_include.include? project.status
  end

  def visit_action action
    @statuses_to_include.include? action.status
  end
    
end

class TemporalFilter < MapFilter
  
  @@filter_options = 
  {
    :both_new_and_done => Proc.new{ | item | [ item.created_date, item.completed_date ] },
    :all_new => Proc.new{ | item | item.done? ? [] : [ item.created_date ] },
    :new_projects => Proc.new{ | item | item.done? ? [] : [ item.created_date ] },
    :all_done => Proc.new{ | item | [ item.completed_date ] }
  }
  
  def initialize start_date, end_date, filter_option
    @filter_option = filter_option
    @start = Date.parse( start_date )
    @end = Date.parse( end_date )
    @dates_for = @@filter_options[ filter_option ] || raise( "#{filter_option} is invalid" )
  end
  
  def visit_project project
    included_in_range?( project ) && ( !@filter_option.to_s.include?( "new_" ) || !project.done?)
  end
  
  def visit_action action
    @filter_option != :new_projects && included_in_range?( action )
  end
  
  def included_in_range? item
    @dates_for.call( item ).any?{ | d | in_range( d ) }
  end
    
  def in_range date
    date && @start <= date && date <= @end
  end
  
  def label item
    label_prefix = case @filter_option
      when :new_projects then "New projects "
      when :all_new then "Created "
      when :all_done then "Completed "
      else ""
    end
    "#{label_prefix}#{@start}..#{@end}"
  end
  
end
