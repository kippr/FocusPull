class Item
  include Enumerable # Wow, I love Ruby!

  attr_reader :name
  attr_accessor :parent
  attr_reader :children
  
  def initialize( name )
    @name = name
    @children = []
  end

  def each( &block )
    yield self
    proc = block
    self.children.each { | child | child.each( &proc ) }
  end
  
  def to_s
    "#{self.class}: #{@name} <- #{self.parent}"
  end
end

class Focus < Item
  
  def initialize( )
    super( "Portfolio" )
  end
        
  def project_list
  end
  
  def project( name )
    self.detect{ | n | n.name == name }
  end
  
  alias folder project
  alias folder_list project_list
  
  def parent
    nil
  end
  
end

class Folder < Item
end

class Project < Item
  
  attr_accessor :status
  
  def initialize( name )
    super( name )
    @status = "active"
  end
  
  def to_s
    super + " [#{@status}]" 
  end
  
end
