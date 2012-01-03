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
  attr_reader :parent, :children
  attr_reader :created_date, :updated_date
  
  def initialize( name )
    @name = name
    @children = []
    @status = :active
  end
  
  def list
    List.new( self )
  end

  def at_context
    # handle a YAML bug which is putting nonsense in here sometimes
    if @at_context.class == Context
      @at_context
    else
      Context.new ""
    end
  end

  def traverse( value, push, pop = nil, &filter_block )
    if ( filter_block.nil? || yield( self ) )
      value = push.call( value, self ) if push
      #todo: make this class reject nicer
      children.each{ | c | value = c.traverse( value, push, pop, &filter_block ) }
      value = pop.call( value, self ) if pop
    end
    value
  end
  
  #todo: rename
  def link_parent( parent, at_context = nil )
    @parent = parent
    @at_context = at_context
    # then add backlinks, registering self with parent and containing context, except for root!
     parent.add_child self unless self.is_root?
     at_context.add_child self unless at_context.nil? || at_context.class != Context || parent.context?
  end
  
  #todo: lose 'is_' on these
  def is_root?
    false
  end
  
  def is_folder?
    false
  end

  def context?
    false
  end
  
  def created_date=( date )
    @created_date = date.respond_to?( :to_date ) ? date.to_date : Date.parse( date ) if date
  end

  def updated_date=( date )
    @updated_date = date.respond_to?( :to_date ) ? date.to_date : Date.parse( date ) if date
  end
    
  def status
    @status
  end

  def status=( status_string )
    @status = status_string.intern if status_string
  end
  
  def active?
    status == :active
  end

  def remaining?
    [:active, :inactive].include? status
  end
  
  #todo: this is evil
  def single_actions?
    false
  end

  #todo: and this is evil too
  def orphan?
    false
  end
  
  #todo: and this is evil too
  def age
    0
  end

  #todo: and this is evil too
  def completed_date
    nil 
  end
  
  def age
    0
  end
  
  
  def depth
    parent.depth + 1
  end
  
  def to_s
    "#{self.class}: #{@name}"
  end
  
  # todo: this doesn't feel like it belongs here, but how to share this else?
  def weight
    0
  end

  def add_child child
    @children << child
  end
  
end

class Focus < Item

  attr_reader :contexts
  
  def initialize
    super( "Portfolio")
    @contexts = []
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

  def context( name )
    @contexts.detect{ |c| c.name == name }
  end
  
  def parent
    nil
  end

  def is_root?
    true
  end
  
  def depth
    1
  end
  
  def created_date
    Date.today
  end
  
  def visit( visitor, *args )
    visitor.visit_focus( self )
  end

  def add_child child
    if child.context?
      @contexts << child
    else
      @children << child
     end
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
  def active?
    true
  end

end

class Action < Item

  def initialize( name )
    super( name )
  end
  
  # todo: make this prettier?
  def status
    case
    when :done == @status
      :done
    when :inactive == at_context.status
      :inactive 
    when parent && :active != parent.status
      parent.status
    else
      @status
    end
  end

  def completed( date )
    date = Date.parse( date ) if date.is_a? String
    if date
      @status = :done
      @completed_date = date
    end
  end

  def completed_date
    @completed_date || parent.completed_date
  end

  def age
    if done?
      completed_date - @created_date
    else
      Date.today - ( @created_date || 0 )
    end
  end
      
  def done?
    status == :done
  end

  def orphan?
    parent.nil? || parent.is_root?
  end
  
  def visit( visitor )
    visitor.visit_action( self )
  end

  def to_s
    super + " [#{self.age}]" 
  end  
  
  def weight
    1
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
  
  def weight
    # single_actions are more like folders than projects...
    single_actions? ? 0 : 3
  end

  # todo: single actions should be a different class
  def age
    single_actions? ? 0 : super
  end
  
end

  class Context < Item

    def visit( visitor, *args )
      visitor.visit_context( self )
    end

    def context?
      true
    end

    def name
      unless parent && parent.context?
        super
      else
        "#{parent.name} : #{super}"
      end
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
    
    def root 
      with_type Focus
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
    
    def older_than seconds_ago
      chain lambda{ | n | n.respond_to?( :age ) && n.age.days > seconds_ago }
    end
    
    def completed_in_last seconds
      chain lambda { | n | 
        n.respond_to?( :completed_date ) && n.completed_date && \
        ( Date.today - n.completed_date ) * 24*60*60 <= seconds
      }
    end

    def created_in_last seconds
      chain lambda { | n | ( Date.today - n.created_date ) * 24*60*60 <= seconds }
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
