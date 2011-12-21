class TreeMap
  include Enumerable

  def self.active focus, *to_exclude
    self.new_tree focus, lambda{ |i| i.active? }, to_exclude, :active
  end

  def self.remaining focus, *to_exclude
    self.new_tree focus, lambda{ |i| i.remaining? }, to_exclude, :active, :inactive
  end

  def self.recent focus, *to_exclude
    completed = lambda{ |i| recently_completed( i ) }
    self.new_tree( focus, completed, to_exclude, :done )
  end

  def self.new_tree focus, filter, to_exclude, *status_types
    fader = ColourFader.new( '#00bb33', '#bbbb00', '#BB0000' )
    tree = self.new( focus, filter, fader, to_exclude, status_types )
  end

  def self.recently_completed item
    item.list.any?{ |i| was_recently_completed i }
  end

  def self.was_recently_completed item
    item.respond_to?( :completed_date ) && item.completed_date &&  ( item.completed_date > 2.weeks.ago.to_date )
  end


  def initialize focus, status, fader, to_exclude, status_types, max = nil
    @focus = focus
    @with_status = status
    @to_exclude = to_exclude
    @status_types = status_types
    @fader = fader
    @max = max || [ 150, filter( focus.list ).collect( &:age ).max || 0 ].max
  end

  def children
    filter( @focus.children ).map{ |c| TreeMap.new( c, @with_status, @fader, @to_exclude, @status_types, @max ) }
  end

  def path node=@focus,current=@focus.name
    current = "#{path( node.parent, node.parent.name )}/#{current}" unless node.parent.nil? || node.is_root?
    current
  end

  def as_json options={}
    {
      :children => children,
      :data => {
        :short_name => short_name,
        :type => type,
        :context => context_name,
        :status => status,
        :age => age,
        :avg_age => avg_age,
        :created => created,
        :num_kids => num_kids,
        "$color" => colour,
        "$area" => weight,
      }, 
      :id => path,
      :name => name 
    }
  end

  def filter list
    # todo: make site wide
    list = list.reject{ |a| @to_exclude.include?( a.name ) }
    list = list.reject( &:orphan? )
    list = list.select{ |a| a.list.actions.select( &@with_status ).count > 0 }
    list
  end

  def name
    @focus.name
  end

  def short_name
    name.truncate 30
  end

  def type
    @focus.class.name.demodulize
  end

  def status
    @focus.status
  end

  def created
    @focus.created_date
  end

  def colour
    to_colour avg_age
  end

  def weight
    [ filter( @focus.list ).select{ |i| @status_types.include? i.status }.collect( &:weight ).reduce( 0, &:+ ), 1 ].max
  end

  def age
    @focus.age
  end

  def avg_age
    #todo
    items = filter( @focus.list )
    items = items.reject{ |i| i.age == 0}
    total = items.collect( &:age ).reduce( &:+ ) || 0
    if items.count == 0
      0
    else
      ( total / ( items.count ) ).to_i 
    end
  end

  def num_kids
    children.count
  end

  # todo - copy/ paste from Edger! Move where?
  def to_colour( weight )
    col_max = @max * 0.75
    weight = [ weight, col_max ].min.to_f
    ratio = weight / col_max
    @fader.at ratio
  end

  def context_name
    @focus.at_context.class == Focus::Context && @focus.at_context.name
  end

  def each &block
    yield self
    children.each{ |c| c.each &block }
  end


end
