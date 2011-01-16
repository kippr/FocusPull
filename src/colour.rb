class ColourFade
  
  def initialize colour1, colour2
    @c1 = as_rgb( colour1 )
    @c2 = as_rgb( colour2 )
  end
  
  def at ratio
    raise "Ratio #{ratio} not in range 0-1" unless (0.0..1.0).include? ratio
    res = @c1.zip( @c2 ).collect do | c1, c2 |
      ( ( c2 - c1 ) * ratio.to_f ) + c1
    end
    as_html( *res )
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