require File.join(File.dirname(__FILE__), '../src/focus')
require File.join(File.dirname(__FILE__), '../src/mindmap_factory')
require 'nokogiri'

describe MindMapFactory, "simple_map" do

  before(:all) do
    @parser = FocusParser.new( "test", "omnisync-sample.tar", "tester" )
    @focus = @parser.parse
    @map_factory = MindMapFactory.new( @focus )
    @xml =  @map_factory.simple_map
  end
 
  it "should create entries for folders and their projects" do
    @xml.should_not be_nil
    @xml.css("map node").should_not be_nil
    puts @xml
  end
  
end
