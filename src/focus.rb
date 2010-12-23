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
  
  def traverse( value, push, pop )
    value = push.call( value, self ) if push
    children.each{ | c | value = c.traverse( value, push, pop ) }
    pop.call( value, self ) if pop
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
    self.select{ | n | n.class == Project }
  end

  # remove duplication w projects, inefficiency of double scan?
  def folders
    self.select{ | n | n.class == Folder }
  end
  
  def project( name )
    projects.detect{ | n | n.name == name }
  end

  # remove duplication w project
  def folder( name )
    folders.detect{ | n | n.name == name }
  end
  
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
