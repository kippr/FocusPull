require File.join(File.dirname(__FILE__), '../src/focus')

class MindMapFactory

  def self.create_simple_map focus
    self.new( focus ).create_map( MapFilter.new )
  end
  
  def self.create_delta_map focus, start_date, end_date
    self.new( focus ).create_map( TemporalFilter.new( start_date, end_date ) )
  end

  def initialize( focus )
    @focus = focus
  end  
  
  def create_map( filter )
    @filter = filter
    @stack = []
    @visitors = create_visitors
    doc = Nokogiri::XML::Document.new()
    root = doc.create_element( "map", :version => '0.9.0' )
    doc << root
    root << doc.create_element( "attribute_registry", :SHOW_ATTRIBUTES => 'hide' )
    @stack << root
    # todo: is there a way to pass methods as procs?
    push = lambda{ | a, b | hello( a, b ) }
    pop = lambda{ | a, b | goodbye( a, b) }
    @focus.traverse( doc, push, pop )
  end
  
  private    
    def create_visitors
      v = []
      v << Namer.new( @stack, @filter )
      v << Formatter.new( @stack, @filter )
      v << IconStamper.new( @stack )
      v << AttributeStamper.new( @stack )
      v << PositionStamper.new( @stack )
      v
    end  
  
  #todo: not mad on the inject into behaviour here, needing to return doc is silly
    def hello( doc, item )
      e = doc.create_element( "node" )
      if @filter.include?( item )
        @stack.last << ( e ) if @stack.last # do not add kids to excluded parents..
        @stack << e
        @visitors.each{ | visitor | visitor.accept item }
      else
        # todo: this is a shame...
        @stack << nil
      end
      doc
    end
    
    def goodbye( doc, node )
      @stack.pop
      doc
    end
        
end

class MapFilter
  
  def include? item
    visitor = self
    item.any?{ | c | c.visit( visitor ) }
  end
  
  def method_missing name, *args, &block
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
    element << element.document.create_element( name, *args, &block )
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
    has_kids = kids.any?{ | kid | !kid.is_folder? }
    element['COLOR'] = has_kids ? '#006699' : '#bfd8e5'
    add_child( "edge", :COLOR => "#cccccc", :STYLE => "bezier", :WIDTH => "thin") unless has_kids
  end
  
  def visit_project project
    element['FOLDED'] = 'true' if project.children.first #folding childless nodes confuses freemind
    if project.on_hold?
      element['COLOR'] = "#666666"
      add_child "font", :ITALIC => 'true', :NAME => "SansSerif", :SIZE => "12" 
    end
  end
  
  def visit_task task
    element['COLOR'] = "#444444"
    add_child "font", :NAME => "SansSerif", :SIZE => "9"
  end
  
end

class IconStamper
  include ElementMixin, VisitorMixin
  
  def visit_project project
    add_on_hold_icon if project.on_hold?
    add_done_icon if project.done?
  end
  
  def visit_task task
    add_done_icon if task.done?
  end
  
  def add_on_hold_icon
    add_child "icon", :BUILTIN => 'stop-sign'
  end

  def add_done_icon
    add_child "icon", :BUILTIN => 'button_ok'
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
