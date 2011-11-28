class TreeMap

  def initialize focus, weighter = nil,  fader = nil
    @focus = focus
    @weighter = weighter || Focus::WeightCalculator.new( NoFilter.new, [], [ :active, :inactive ] ) 
    @fader = fader || ColourFader.new_with_zero( '#cccccc', '#00bb33', '#bbbb00', '#BB0000' ) 
    @max = 20
  end

  def children
    active = @focus.children.select( &:remaining? )
    # todo: revisit use of single_actions? - defined ugly hack for Item!
    active = active.reject( &:single_actions? ).reject( &:orphan? )
    active = active.select{ |a| a.list.active.actions.count > 0 }
    active.map{ |c| TreeMap.new( c, @weighter, @fader ) }
  end

  def path node=@focus,current=@focus.name
    current = "#{path( node.parent, node.parent.name )}/#{current}" unless node.is_root?
    current
  end

  def as_json options={}
    weight = @weighter.weigh @focus
    p weight
    {
      :children => children,
      :data => {
        "$color" => to_colour( weight ),
        "$area" => @focus.list.active.count
      }, 
      :id => path,
      :name => @focus.name
    }
  end

  # todo - copy/ paste from Edger!
  def to_colour( weight )
    col_max = @max * 0.75
    weight = [ weight, col_max ].min.to_f
    ratio = weight / col_max
    @fader.at ratio
  end



end

class NoFilter
  def accept item
    true
  end
end
