class ColourFader
  
  def initialize *colours
    @c = colours.collect{ |c| as_rgb( c ) }
    raise "Should have at least two colours, got #{colours.size}" if colours.size < 2
  end
  
  def at ratio
    raise "Ratio #{ratio} not in range 0-1" unless (0.0..1.0).include? ratio
    return as_html( *@c.last ) if ratio == 1.0 # special case to avoid falling off end of array
    
    sized_ratio = ratio * ( @c.size - 1 )
    col1 = @c[ sized_ratio ]
    col2 = @c[ sized_ratio + 1 ]
    local_ratio = sized_ratio % 1
    
    rgb = col1.zip( col2 ).collect do | c1, c2 |
      ( ( c2 - c1 ) * local_ratio ) + c1
    end
    as_html( *rgb )
    
  end
  
  def as_rgb colour
    if colour =~ /^#([0-9a-fA-F]{2})([0-9a-fA-F]{2})([0-9a-fA-F]{2})$/
      [ $1.hex, $2.hex, $3.hex ]
    else
      raise "#{colour} is not a valid 'html' colour reference"
    end
  end
  
  def as_html r, g, b
    "##{as_h(r)}#{as_h( g )}#{as_h( b )}"
  end
  
  def as_h num
    num.to_i.to_s( 16 ).rjust( 2, '0' )
  end
  
end