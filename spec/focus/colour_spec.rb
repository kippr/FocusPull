require 'spec_helper'
require 'focus'

describe ColourFader, "with two colours" do
  
  before( :all ) do
    @bw = ColourFader.new( '#000000', '#ffffff' )
  end
  
  it "should represent the fade from one html colour to another" do
    @bw.at( 0 ).should == '#000000'
    @bw.at( 1 ).should == '#ffffff'
  end
  
  it "should only accept something in range of 0 to 1" do
    lambda{ @bw.at( 1.0001 ) }.should raise_error
    lambda{ @bw.at( -1.0 / 10 ) }.should raise_error    
  end
  
  it "should calculate points in colour range" do
    @bw.at( 0.5 ).should == '#7f7f7f'
  end
  
  it "should translate html colours into rgb" do
    @bw.as_rgb( '#007fff' ).should == [ 0, 127, 255 ]
    @bw.as_rgb( '#007FFF' ).should == [ 0, 127, 255 ]
  end
  
  it "should not accept invalid html colours" do
    lambda{ puts @bw.as_rgb( '#CAFEgr') }.should raise_error
  end

  it "should translate rgb colours back into html" do
    @bw.as_html( 0, 127, 255 ).should == '#007fff'
  end

end

describe ColourFader, "with three colours" do
  
  before( :all ) do
    @three = ColourFader.new( '#cccccc', '#ffffff', '#0000ff' )
  end
  
  it "should calculate points in colour range" do
    @three.at( 0.25 ).should == '#e5e5e5' # this is half way b/w cc & ff
    @three.at( 0.75 ).should == '#7f7fff' # this is half way b/c blue and black
  end
  
end

describe ColourFader, "with a special colour at zero" do

  before( :all ) do
    @bw = ColourFader.new_with_zero( '#cccccc', '#000000', '#ffffff' )
  end
  
  it "should have a special behaviour for zero" do
    @bw.at( 0 ).should == '#cccccc'
  end
  
  it "should represent the fade from one html colour to another as usual once not at zero" do
    @bw.at( 0.00000000001 ).should == '#000000'
    @bw.at( 1 ).should == '#ffffff'
  end
  
end