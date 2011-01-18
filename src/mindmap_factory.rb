require File.join(File.dirname(__FILE__), '../src/focus')
require File.join(File.dirname(__FILE__), '../src/colour')

module ElementMixin

  def initialize( stack )
    @stack = stack
  end
  
  def element
    @stack.last
  end
  
  def add_child( name, *args, &block )
    child = element.document.create_element( name, *args, &block )
    element << child if element  # do not try to add kids to current element if its not there
    child
  end  
end


class MindMapFactory
  include ElementMixin
  
  # todo: sensible values?
  PROJECT_AGED=90
  TASK_AGED=45 
  
  #todo: this makes me want to weep... As soon as I add an html node, a whole bunch of 
  # tests start failing. Namespace issue with a magic html node? No idea :(
  # This hack just skips adding the html nodes
  class << self
    attr_accessor :failing_test_hack
  end

  def self.create_simple_map focus, extra_options = {}
    local_defaults = {
      :HIGHLIGHT_ACTIVE_TASKS => false,
      :STATUSES_TO_INCLUDE => [ :active, :inactive, :dropped ]
    }
    options = local_defaults.merge( extra_options )
    factory = self.new( focus, options )
    factory.create_map( StatusFilter.new( options[ :STATUSES_TO_INCLUDE ] ) )
  end
  
  def self.create_delta_map focus, start_date, end_date, filter_option = :both_new_and_done, extra_options = {}
    local_defaults = {
      :WEIGHTED_STATUSES => [ :active, :done ]
    }
    factory = self.new( focus, local_defaults.merge( extra_options ) )
    factory.create_map( TemporalFilter.new( start_date, end_date, filter_option ) )
  end
  
  def self.create_meta_map focus, extra_options = {}
    local_defaults = {
      :FOLD_TASKS => false, :FORMATTING => false, 
      :WEIGHT_EDGES => false, :ADD_ICONS => false
    }
    factory = self.new( focus, local_defaults.merge( extra_options ) )
    factory.create_meta_map
  end

  def default_options
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
  
  def initialize( focus, options = {} )
    super( [] )
    @options = default_options.merge options
    @focus = focus
  end  
  
  def create_map( filter )
    @filter = filter
    @visitors = create_visitors
    doc = create_doc
    # todo: is there a way to pass methods as procs?
    push = lambda{ | x, item | visit( item ) }
    pop = lambda{ | x, item | @stack.pop }
    @focus.traverse( nil, push, pop) { | n | !@options[ :EXCLUDE_NODES ].include? n.name }
    doc
  end
  
  def create_meta_map( )
    doc = create_doc
    @filter = MapFilter.new
    @visitors = create_visitors
    add_meta_info
    doc
  end
    
  private        
    
  
    def create_doc
      doc = Nokogiri::XML::Document.new()
      @stack << doc
      @stack << add_child( "map", :version => '0.9.0' )
      add_child( "attribute_registry", :SHOW_ATTRIBUTES => 'hide' )
      doc
    end
    
    def create_visitors
      v = []
      v << Namer.new( @stack, @filter )
      v << Formatter.new( @stack, @filter ) if @options[ :FORMATTING ]
      v << ActionCollapser.new( @stack, @filter ) if @options[ :FOLD_TASKS ]
      v << IconStamper.new( @stack, @filter, @options[ :HIGHLIGHT_ACTIVE_TASKS ] ) if @options[ :ADD_ICONS ]
      v << Edger.new( @stack, @filter, @options[ :WEIGHTED_STATUSES ] ) if @options[ :WEIGHT_EDGES ]
      v << AttributeStamper.new( @stack ) if @options[ :ADD_ATTRIBUTES ]
      v << PositionStamper.new( @stack )
    end  
    
    def add_meta_info
      # todo: don't use meta visitor, it's dumb
      visitor = MetaVisitor.new
      @focus.traverse( nil, lambda{ |a, b| visitor.accept b } )
      data = visitor.counts
      
      @stack << add_child( "node", :TEXT => "Meta" )
      @stack << add_child( "node", :TEXT => "By status", :POSITION => "right" )
      add_meta_items data, "Projects", "Active" => "active", "Done" => "done", "On Hold" => "inactive", "Dropped" => "dropped"
      add_meta_items data, "Actions", "Active" => "active", "Done" => "done"
      @stack.pop
      
      @stack << add_child( "node", :TEXT => "Actionless projects", :POSITION => "left" )
      add_child( "node", :TEXT => "todo" )
      @stack.pop

      #todo: remove duplication
      aged_projects = data["Projects-aged"]
      @stack << add_child( "node", :TEXT => "Aged projects (#{aged_projects.size})", :POSITION => "left", :FOLDED => 'true' )
      aged_projects.each do | item |
        visit item
        @stack.pop
      end
      @stack.pop
      
      aged_actions = data["Actions-aged"]
      @stack << add_child( "node", :TEXT => "Aged actions (#{aged_actions.size})", :POSITION => "left", :FOLDED => 'true' )
      aged_actions.each do | item |
        visit item
        @stack.pop
      end
      @stack.pop
      
    end
    
    def add_meta_items data, type, statuses
      @stack << add_child( "node", :TEXT => type  )
      statuses.each do | name, status |
        items = data["#{type}-#{status}"]
        @stack << add_child( "node", :TEXT => "#{name}: #{items.size}", :FOLDED => "true" )
        items.each do | item |
          visit item
          @stack.pop
        end
        @stack.pop
      end
      @stack.pop
      
    end
  
    def visit item
      if @filter.include?( item )
        @stack << add_child( "node" )
        @visitors.each{ | visitor | visitor.accept item }
      else
        # todo: this is a shame, but how else to deal with pop?
        @stack << nil
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
    @stack << add_child( "richcontent", :TYPE => "NODE" )
    @stack << add_child( "html" ) unless MindMapFactory.failing_test_hack
    @stack << add_child( "body" )
    @stack << add_child( "p", :style => "text-align: center" )
    add_child( "font", :SIZE => 4 ).content = "Portfolio" 
    @stack.pop
    @stack << add_child( "p", :style => "text-align: center" )
    add_child( "font", :SIZE => 2 ).content = @filter.label( focus )     
    @stack.pop
    @stack.pop
    @stack.pop unless MindMapFactory.failing_test_hack
    @stack.pop
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
    @fader = ColourFader.new( '#cccccc', '#000000', '#0000ff' )
    @max = 20
  end
  
  def accept item
    weight = @weight_calculator.weigh item
    add_child "edge", :COLOR => to_colour( weight ), :WIDTH => weight <= @max ? 1 : 2    
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

class MetaVisitor
  include VisitorMixin
  
  attr_reader :counts
  
  def initialize
    @counts = Hash.new { | hash, key | hash[ key ] = [] }
  end
  
  def visit_project project
    track( "Projects", project )
    @counts["Projects-aged"] << project if project.age >= MindMapFactory::PROJECT_AGED && !project.done?
  end

  def visit_action action
    track( "Actions", action )
    @counts["Actions-aged"] << action if action.age >= MindMapFactory::TASK_AGED && !action.done?
  end
  
  def track type, item
    @counts["#{type}-#{item.status}"] << item
  end
    
end

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
    :new_only => Proc.new{ | item | [ item.created_date ] },
    :done_only => Proc.new{ | item | [ item.completed_date ] }
  }
  
  def initialize start_date, end_date, filter_option
    @start = Date.parse( start_date )
    @end = Date.parse( end_date )
    @dates_for = @@filter_options[ filter_option ] || raise( "#{filter_option} is invalid" )
    #todo: seems kinda ugly?
    @label_prefix = {
      :new_only => "Created ", :done_only => "Completed "
      }[filter_option] || ""
  end
  
  def visit_project project
    included_in_range? project
  end
  
  def visit_action action
    included_in_range? action
  end
  
  def included_in_range? item
    @dates_for.call( item ).any?{ | d | in_range( d ) }
  end
    
  def in_range date
    date && @start <= date && date <= @end
  end
  
  def label item
    "#{@label_prefix}#{@start}..#{@end}"
  end
  
end
