require File.join(File.dirname(__FILE__), '../src/focus')

class MindMapFactory

  def initialize( focus )
    @focus = focus
  end
  
  def simple_map
    @filter = MapFilter.new unless @filter
    @stack = []
    @size = 0
    doc = Nokogiri::XML::Document.new()
    root = doc.create_element( "map", :version => '0.9.0' )
    doc << root
    root << doc.create_element( "attribute_registry", :SHOW_ATTRIBUTES => 'hide' )
    @stack << root
    # todo: is there a way to pass methods as procs?
    push = lambda{ | a, b | hello( a, b ) }
    pop = lambda{ | a, b | goodbye( a, b) }
    @focus.traverse( doc, push, pop )
    doc
  end
  
  def delta_map start_date, end_date
    @filter = TemporalFilter.new start_date, end_date
    map = simple_map
    @filter = MapFilter.new
    map
  end
  
  #todo: not mad on the inject into behaviour here, needing to return doc is silly
  private
    def hello( doc, item )
      if @filter.include? item
        element = doc.create_element( "node" ) do | e |
          e['TEXT'] = item.name
          e['POSITION'] = pos if pos
          item.visit Formatter.new(e)
          item.visit AttributeStamper.new(e)
        end
        @stack.last << ( element ) if @stack.last
        @size += 1
      end
      @stack << element
      doc
    end
    
    def goodbye( doc, node )
      @stack.pop
      doc
    end
    
    def pos
      if first_level
        @size % 2 == 0 ? "left" : "right"
      else
        nil
      end
    end
    
    def first_level
      @stack.size == 2
    end
    
end

class MapFilter
  
  def include? item
    item.visit self
  end
  
  def method_missing name, *args, &block
    true
  end
  
end

class TemporalFilter < MapFilter
  
  def initialize start_date, end_date
    @start = Date.parse( start_date )
    @end = Date.parse( end_date )
  end
  
  def visit_project project
    in_range( project.created_date ) || in_range( project.completed_date )
  end
  
  def visit_task task
    true
  end
  
  def in_range date
    date && @start <= date && date <= @end
  end
  
end

class ElementVisitor
  
  def initialize( element )
    @element = element
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::INFO
  end
  
  def method_missing name, *args, &block
    visit_default *args
  end
  
  def visit_default *args
    @logger.debug "Unhandled visit to #{self} with #{args}"
  end
  
  def add_child( name, *args, &block )
    @element << @element.document.create_element( name, *args, &block )
  end
  
end

class Formatter < ElementVisitor
  
  def visit_folder folder
    @element['COLOR'] = "#006699"
  end
  
  def visit_project project
    @element['FOLDED'] = 'true' if project.children.first #folding childless nodes confuses freemind
    if project.inactive?
      @element['COLOR'] = "#666666"
      add_child "font", :ITALIC => 'true', :NAME => "SansSerif", :SIZE => "12" 
    end
  end
  
  def visit_task task
    @element['COLOR'] = "#444444"
    add_child "font", :NAME => "SansSerif", :SIZE => "9"
  end
  
end

class AttributeStamper < ElementVisitor
  
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
