class TreeMap

  def initialize focus
    @focus = focus
  end

  def children
    active = @focus.children.select( &:active? )
    active = active.select{ |a| a.list.active.actions.count > 0 }
    active.map{ |c| TreeMap.new c }
  end

  def path node=@focus,current=@focus.name
    current = "#{path( node.parent, node.parent.name )}/#{current}" unless node.is_root?
    current
  end

  def as_json options={}
    {
      :children => children,
      :data => {
        "$color" => "#8E7032",
        "$area" => 276
      }, 
      :id => path,
      :name => @focus.name
    }
  end


end
