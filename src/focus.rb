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
  
  def is_folder?
    self.class == Folder
  end
  
  def is_project?
    self.class == Project
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

  # todo: remove duplication w projects, inefficiency of double scan?
  def folders
    self.select{ | n | n.class == Folder }
  end

  def tasks
    self.select{ | n | n.class == Task }
  end
  
  def project( name )
    projects.detect{ | n | n.name == name }
  end

  # todo: remove duplication w project
  def folder( name )
    folders.detect{ | n | n.name == name }
  end
  
  def task( name )
    tasks.detect{ | n | n.name == name }
  end
  
  def parent
    nil
  end

  def is_root?
    true
  end
  
  def visit( visitor, *args )
    visitor.visit_focus( self )
  end

end

class Folder < Item
  
  def visit( visitor )
    visitor.visit_folder( self )
  end

end

class Task < Item

  attr_accessor :status
  
  def initialize( name )
    super( name )
    @status = 'active'
  end
  
  def completed( date )
    @status = 'done'
    @completedDate = Date.parse( date )
  end
  
  def completed_date
    @completedDate
  end
  
  def inactive?
    status == 'inactive'
  end
  
  def to_s
    super + " [#{@status}]" 
  end
  
  def visit( visitor )
    visitor.visit_task( self )
  end

end

class Project < Task  
  
  def visit( visitor )
    visitor.visit_project( self )
  end
  
end

