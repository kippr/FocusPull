require File.join(File.dirname(__FILE__), '../src/focus')

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

  def self.create_simple_map focus
    factory = self.new( focus, :HIGHLIGHT_ACTIVE_TASKS => false )
    factory.create_map( MapFilter.new )
  end
  
  def self.create_delta_map focus, start_date, end_date, filter_option = :both_new_and_done
    factory = self.new( focus, :FOLD_TASKS => false )
    factory.create_map( TemporalFilter.new( start_date, end_date, filter_option ) )
  end
  
  def self.create_meta_map focus
    factory = self.new( focus, :FOLD_TASKS => false, :FORMATTING => false, 
      :WEIGHT_EDGES => false, :ADD_ICONS => false )
    factory.create_meta_map
  end

  def default_options
    { 
      :FORMATTING => true, 
      :FOLD_TASKS => true, 
      :HIGHLIGHT_ACTIVE_TASKS => true,
      :WEIGHT_EDGES => true,
      :ADD_ICONS => true
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
    @focus.traverse( nil, push, pop )
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
      v << TaskCollapser.new( @stack, @filter ) if @options[ :FOLD_TASKS ]
      v << IconStamper.new( @stack, @filter, @options[ :HIGHLIGHT_ACTIVE_TASKS ] ) if @options[ :ADD_ICONS ]
      v << Edger.new( @stack, @filter ) if @options[ :WEIGHT_EDGES ]
      v << AttributeStamper.new( @stack )
      v << PositionStamper.new( @stack )
    end  
    
    def add_meta_info
      visitor = MetaVisitor.new
      @focus.traverse( nil, lambda{ |a, b| visitor.accept b } )
      data = visitor.counts
      
      @stack << add_child( "node", :TEXT => "Meta" )
      @stack << add_child( "node", :TEXT => "By status", :POSITION => "right" )
      add_meta_items data, "Projects", "Active" => "active", "Done" => "done", "On Hold" => "inactive", "Dropped" => "dropped"
      add_meta_items data, "Tasks", "Active" => "active", "Done" => "done"
      @stack.pop
      
      @stack << add_child( "node", :TEXT => "Taskless projects", :POSITION => "left" )
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
      
      aged_tasks = data["Tasks-aged"]
      @stack << add_child( "node", :TEXT => "Aged tasks (#{aged_tasks.size})", :POSITION => "left", :FOLDED => 'true' )
      aged_tasks.each do | item |
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
    kids = this_folder.select{ | kid | kid != this_folder && @filter.include?( kid ) }
    childless = kids.all?( &:is_folder? )
    element['COLOR'] = childless ? '#bfd8e5' : '#006699' 
  end
  
  def visit_project project
    if project.on_hold? || project.dropped?
      element['COLOR'] = "#666666"
      add_child "font", :ITALIC => 'true', :NAME => 'SansSerif', :SIZE => '12' 
    end
    # this fades projects only included because kids are accepted, when they themselves 
    # aren't (accept tests only self, include? also tests kids)
    element['COLOR'] = "#666666" unless @filter.accept project
  end
  
  def visit_task task
    element['COLOR'] = "#444444"
    add_child "font", :NAME => "SansSerif", :SIZE => "9"
  end
  
end

class TaskCollapser
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
  
  def initialize( stack, filter, highlight_active_tasks )
    super( stack )
    @filter = filter
    @highlight_active_tasks = highlight_active_tasks
  end
  
  def visit_project project
    add_active_icon if @highlight_active_tasks && is_a_new( project )
    add_on_hold_icon if project.on_hold?
    add_dropped_icon if project.dropped?
    add_done_icon if project.done?
  end
  
  def visit_task task
    add_active_icon if @highlight_active_tasks && is_a_new( task )
    add_done_icon if task.done?
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
  
  def initialize( stack, filter )
    super( stack )
    @weight_calculator = WeightCalculator.new( filter )
  end
  
  def accept item
    weight = weigh item
    add_child "edge", :COLOR => to_colour( weight ), :WIDTH => weight <= 18 ? 1 : 2    
  end
  
  def weigh item
    item.inject( 0 ) do | weight, child |
      weight + @weight_calculator.accept( child )
    end
  end
  
  def to_colour( weight )
    case 
      when (weight == 0)
        '#cccccc'
      when (weight <= 3)
        '#000044'
      when (weight <= 9)
        '#000088'
      when (weight <= 12)
        '#0000aa'
      else
        '#0000ff'
      end
  end
  
end

class WeightCalculator
  include VisitorMixin
  
  def initialize( filter )
    @filter = filter
  end
  
  def accept item
    @filter.accept( item ) ? item.visit( self ) : 0
  end
  
  def visit_project project
    project.active? ? 3 : 0
  end

  def visit_task task
    task.active? ? 1 : 0
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
  
  def visit_task task
    add_status_for task
    add_dates_for task
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

  def visit_task task
    track( "Tasks", task )
    @counts["Tasks-aged"] << task if task.age >= MindMapFactory::TASK_AGED && !task.done?
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
    @dates_for = @@filter_options[ filter_option ]#|| raise 
    #todo: seems kinda ugly?
    @label_prefix = {
      :new_only => "Created in ", :done_only => "Completed in "
      }[filter_option] || ""
  end
  
  def visit_project project
    included_in_range? project
  end
  
  def visit_task task
    included_in_range? task
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
