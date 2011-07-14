module Focus
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

  attr_reader :name
  attr_reader :parent
  attr_reader :children
  attr_reader :created_date, :updated_date
  
  def initialize( name )
    @name = name
    @children = []
  end
  
  def list
    List.new( self )
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
  end
  
  def is_root?
    false
  end
  
  def is_folder?
    false
  end
  
  def created_date=( date )
    @created_date = Date.parse( date ) if date
  end

  def updated_date=( date )
    @updated_date = Date.parse( date ) if date
  end
    
  #todo: this is evil
  def status
    :active
  end
  
  def remaining?
    [:active, :inactive].include? status
  end
  
  def to_s
    "#{self.class}: #{@name}"
  end
end

class Focus < Item
  
  def initialize
    super( "Portfolio")
  end
        
  def projects
    select_for Project  
  end

  def actions
    select_for Action
  end
  
  def project( name )
    detect_for( Project, name )
  end

  def folder( name )
    detect_for( Folder, name )
  end
  
  def action( name )
    detect_for( Action, name )
  end
  
  def parent
    nil
  end

  def is_root?
    true
  end
  
  def created_date
    Date.today
  end
  
  def visit( visitor, *args )
    visitor.visit_focus( self )
  end
  
  private
    def select_for( type )
      self.list.select{ | n | n.class == type }
    end
    
    def detect_for( type, name )
      self.list.detect{ | n | n.class == type && n.name == name }
    end

end

class Folder < Item
  
  def is_folder?
    true
  end
  
  def visit( visitor )
    visitor.visit_folder( self )
  end

  # todo: define status method
    
end

class Action < Item

  attr_reader :completed_date
  
  def initialize( name )
    super( name )
    @status = :active
  end
  
  def status
    parent && [ :inactive, :dropped ].include?( parent.status ) ? parent.status : @status 
  end
  
  def status=( status_string )
    @status = status_string.intern if status_string
  end
  
  def completed( date )
    date = Date.parse( date ) if date.is_a? String
    if date
      @status = :done
      @completed_date = date
    end
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
  
  def single_actions?
    @single_actions || false
  end
  
  def set_single_actions
    @single_actions = true
  end
  
  
  def visit( visitor )
    visitor.visit_project( self )
  end
  
end


  class List
    include Enumerable
    
    def initialize source, filter = lambda{ |n| true }
      @source = source
      @filter = filter
      @negate_next = false
    end
    
    def each( &block )
      yield @source
      proc = block
      @source.children.each { | child | child.list.each( &proc ) }
    end
    
    def folders
      with_type Folder
    end
    
    def projects
      with_type Project
    end

    def actions
      with_type Action
    end

    def active
      with_status :active
    end

    def completed
      with_status :done
    end

    def remaining
      with_status [ :active, :inactive ]
    end

    def with_status one_or_many_status
      chain lambda{ | n | [*one_or_many_status].include?( n.status ) }
    end

    def stalled
      #todo: should children also move?
      active.not.single_action.with{ | n | n.children.none?(&:remaining?) }
    end
    
    def older_than date
      chain lambda{ | n | n.respond_to?( :age ) && n.age > date }
    end
    
    def single_action
      chain lambda{ | n | n.respond_to?( :single_actions? ) && n.single_actions? }
    end
    
    def with &block 
      chain block
    end
    
    def not
      @negate_next = true
      self
    end

    def to_s
      to_a.to_s
    end

    private 
      def chain lambda
        if @negate_next
          lambda = negate( lambda )
          @negate_next = false
        end
        FilteredList.new( self, lambda )
      end
      
      def negate original_lambda
        lambda{ |n| ! original_lambda.call( n ) }
      end
      
      def with_type type         
        chain lambda{ | n | n.class == type }
      end

  end
  
  class FilteredList < List
    
    def each( &block )
      #todo: is there a nicer way to ref block?
      proc = block
      @source.select{ | n | @filter.call( n ) }.each( &proc )
    end
    
  end
  
end