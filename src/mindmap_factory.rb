require File.join(File.dirname(__FILE__), '../src/focus')

class MindMapFactory

  def initialize( focus )
    @focus = focus
    @stack = []
    @size = 0
  end
  
  def simple_map
    doc = Nokogiri::XML::Document.new()
    root = doc.create_element "map", :version => '0.9.0'
    doc.add_child root
    @stack << root
    # todo: is there a way to pass methods as procs?
    push = lambda{ | a, b | hello( a, b ) }
    pop = lambda{ | a, b | goodbye( a, b) }
    @focus.traverse( doc, push, pop )
    doc
  end
  
  #todo: not mad on the inject into behaviour here, needing to return doc is silly
  private
    def hello( doc, node )
      element = doc.create_element( "node" ) do | n | 
        n['TEXT'] = node.name 
        n['POSITION'] = pos if pos
        n['COLOR'] = "#006699" if node.is_folder?
        n['FOLDED'] = 'true' if node.is_project? && node.children.first
      end
      @stack.last.add_child( element ) #if node.is_folder? or node.status == "active"
      @stack << element
      @size += 1
      doc
    end
    
    def goodbye( doc, node )
      @stack.pop
      doc
    end
    
    def pos
      if @stack.size == 2
        if @size % 2 == 0
          "left"
        else
          "right"
        end 
      else
        nil
      end
    end
  
end
