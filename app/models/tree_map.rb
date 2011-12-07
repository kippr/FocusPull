class TreeMap

  def initialize focus, type = :active?, weighter = nil,  fader = nil, max = nil
    @focus = focus
    @type = type
    @weighter = weighter || Focus::WeightCalculator.new( NoFilter.new, [], [ :active, :inactive ] ) 
    @fader = fader || ColourFader.new( '#00bb33', '#bbbb00', '#BB0000' ) 
    @max = max || [ 150, filter( @focus.list ).collect( &:age ).max || 0 ].max
  end

  def children
    filter( @focus.children ).map{ |c| TreeMap.new( c, @type, @weighter, @fader, @max ) }
  end

  def path node=@focus,current=@focus.name
    current = "#{path( node.parent, node.parent.name )}/#{current}" unless node.parent.nil? || node.is_root?
    current
  end

  def as_json options={}
    {
      :children => children,
      :data => {
        :short_name => @focus.name.truncate( 30 ),
        :type => @focus.class.name.demodulize,
        :context => context_name,
        :status => @focus.status,
        :age => age,
        :avg_age => avg_age,
        :created => @focus.created_date,
        "$color" => colour,
        "$area" => filter( @focus.list ).count
      }, 
      :id => path,
      :name => @focus.name
    }
  end

  def filter list
    list = list.select( &@type )
    # todo: make site wide
    list = list.reject{ |a| a.name == 'Personal' }
    list = list.reject( &:orphan? )
#    list = list.reject( &:single_actions? )
    list = list.select{ |a| a.list.remaining.actions.count > 0 }
    list
  end


  def colour
    to_colour( avg_age || 0 )
  end

  def weight
    @weighter.weigh( @focus ).to_i
  end

  def age
    @focus.age if @focus.respond_to? :age 
  end

  def avg_age
    #todo
    items = filter( @focus.list ).select( &@type )
    total = items.collect( &:age ).reduce( &:+ ) || 0
    ( total / ( items.reject{ |i| i.age == 0}.count + 0.01 ) ).to_i
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



end

class NoFilter
  def accept item
    true
  end
end
