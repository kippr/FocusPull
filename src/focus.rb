class Item
  include Enumerable # Wow, I love Ruby!

  attr_reader :name
  attr_reader :parent
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
  
  def link_parent( parent )
    @parent = parent
    # then add a backlink, registering self with parent, except for root!
     parent.children << self unless self.is_root?
  end
  
  def is_root?
    false
  end
  
  def to_s
    "#{self.class}: #{@name} <- #{self.parent}"
  end
end

class Focus < Item
  
  def initialize( )
    super( "Portfolio" )
  end
        
  def projects
    self
  end
  
  def project( name )
    self.detect{ | n | n.name == name }
  end
  
  alias folder project
  alias folders projects
  
  def parent
    nil
  end

  def is_root?
    true
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
