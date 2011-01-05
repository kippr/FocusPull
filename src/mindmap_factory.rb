require File.join(File.dirname(__FILE__), '../src/focus')

module VisitorMixin
  
  def accept item
    item.visit self
  end

  def method_missing name, *args, &block
    if name.to_s.start_with? "visit"
      visit_default *args
    else
      super name, *args, &block
    end
  end
  
  def visit_default item
  end
  
end

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

  def self.create_simple_map focus
    self.new( focus ).create_map( MapFilter.new )
  end
  
  def self.create_delta_map focus, start_date, end_date
    factory = self.new( focus, :FOLD_TASKS => false, :HIGHLIGHT_ACTIVE_TASKS => true )
    factory.create_map( TemporalFilter.new( start_date, end_date ) )
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
    add_meta_info
    doc
  end
  
  private    
  
    def add_meta_info
      visitor = MetaVisitor.new
      @focus.traverse( nil, lambda{ |a, b| visitor.accept b } )
      data = visitor.counts
      
      # todo: don't like the push & pop
      @stack << @stack.last.children.last

      node = add_child "node", :TEXT => "Meta", :COLOR => '#555555', :FOLDED => 'true'
      add_child "edge", :WIDTH => 'thin', :COLOR => '#555555'
      @stack << node

      @stack << add_child( "node", :TEXT => "Projects" )
      @stack << add_child( "node", :TEXT => "Active: #{data['projects-active']}" )
      @stack.pop
      @stack << add_child( "node", :TEXT => "Done: #{data['projects-done']}" )
      @stack.pop
      @stack << add_child( "node", :TEXT => "On Hold: #{data['projects-inactive']}" )
      @stack.pop
      @stack << add_child( "node", :TEXT => "Dropped: #{data['projects-dropped']}" )
      @stack.pop
      @stack.pop

      @stack << add_child( "node", :TEXT => "Tasks" )
      @stack << add_child( "node", :TEXT => "Active: #{data['tasks-active']}" )
      @stack.pop
      @stack << add_child( "node", :TEXT => "Done: #{data['tasks-done']}" )
      @stack.pop
      @stack.pop

      @stack.pop
    end
    
    
    def default_options
      { 
        :FOLD_TASKS => true, 
        :HIGHLIGHT_ACTIVE_TASKS => false
      }
    end
  
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
      v << Formatter.new( @stack, @filter )
      v << TaskCollapser.new( @stack, @filter ) if @options[ :FOLD_TASKS ]
      v << IconStamper.new( @stack, @filter, @options[ :HIGHLIGHT_ACTIVE_TASKS ] )
      v << Edger.new( @stack, @filter )
      v << AttributeStamper.new( @stack )
      v << PositionStamper.new( @stack )
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
    element['TEXT'] = @filter.label( focus )
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
    @counts = Hash.new(0)
  end
  
  def visit_project project
    count( "projects", project )
  end

  def visit_task task
    count( "tasks", task )
  end
  
  def count type, item
    @counts["#{type}-#{item.status}"] += 1
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
    item.name
  end
  
end

class TemporalFilter < MapFilter
  
  def initialize start_date, end_date
    @start = Date.parse( start_date )
    @end = Date.parse( end_date )
  end
  
  def visit_project project
    starts_or_ends_in_range project
  end
  
  def visit_task task
    starts_or_ends_in_range task
  end
  
  def starts_or_ends_in_range item
    in_range( item.created_date ) || in_range( item.completed_date )
  end
  
  def in_range date
    date && @start <= date && date <= @end
  end
  
  def label item
    "#{item.name} #{@start}..#{@end}"
  end
  
end
