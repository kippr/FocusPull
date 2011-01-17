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

class Item
  include Enumerable # Wow, I love Ruby!

  attr_reader :name
  attr_reader :parent
  attr_reader :rank 
  attr_reader :children
  
  def initialize( name, rank )
    @name = name
    @rank = rank.to_i
    @children = []
  end

  def each( &block )
    yield self
    proc = block
    self.children.each { | child | child.each( &proc ) }
  end
  
  def traverse( value, push, pop = nil, &filter_block )
    if ( filter_block.nil? || yield( self ) )
      value = push.call( value, self ) if push
      children.each{ | c | value = c.traverse( value, push, pop, &filter_block ) }
      value = pop.call( value, self ) if pop
    end
    value
  end
  
  def link_parent( parent )
    @parent = parent
    # then add a backlink, registering self with parent, except for root!
     parent.children << self unless self.is_root?
     #todo: consider moving sorting of children out, rank is an obtrusive item not used for anything else
     parent.children.sort!{ | a,b | a.rank <=> b.rank }
  end
  
  def is_root?
    false
  end
  
  def is_folder?
    false
  end
  
  # todo: this is evil
  def created_date
    Date.today
  end
  
  def to_s
    "#{self.class}: #{@name}"
  end
end

class Focus < Item
  
  def initialize( )
    super( "Portfolio", 0 )
  end
        
  def projects
    self.select{ | n | n.class == Project }
  end

  # todo: remove duplication w projects, inefficiency of double scan?
  def folders
    self.select{ | n | n.class == Folder }
  end

  def actions
    self.select{ | n | n.class == Action }
  end
  
  def project( name )
    projects.detect{ | n | n.name == name }
  end

  # todo: remove duplication w project
  def folder( name )
    folders.detect{ | n | n.name == name }
  end
  
  def action( name )
    actions.detect{ | n | n.name == name }
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
  
  def is_folder?
    true
  end
  
  def visit( visitor )
    visitor.visit_folder( self )
  end
  
end

class Action < Item

  attr_reader :completed_date, :created_date, :updated_date
  attr_reader :status
  
  def initialize( name, rank )
    super( name, rank )
    @status = :active
  end
  
  def status=( status_string )
    @status = status_string.intern
  end
  
  def completed( date )
    @status = :done
    @completed_date = Date.parse( date )
  end
    
  def created_date=( date )
    @created_date = Date.parse( date )
  end

  def updated_date=( date )
    @updated_date = Date.parse( date )
  end
  
  def age
    if done?
      @completed_date - @created_date
    else
      Date.today - ( @created_date || 0 )
    end
  end
      
  def active?
    status == :active
  end

  def done?
    status == :done
  end
  
  def visit( visitor )
    visitor.visit_action( self )
  end

  def to_s
    super + " [#{self.age}]" 
  end  

end

class Project < Action  

  def on_hold?
    status == :inactive
  end

  def dropped?
    status == :dropped
  end
  
  def completed_date
    dropped? ? updated_date : @completed_date
  end
  
  
  def visit( visitor )
    visitor.visit_project( self )
  end
  
end

