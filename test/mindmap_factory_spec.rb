require File.join(File.dirname(__FILE__), '../src/focus')
require File.join(File.dirname(__FILE__), '../src/mindmap_factory')
require 'nokogiri'

describe MindMapFactory, "simple_map" do

  before(:all) do
    @parser = FocusParser.new( "test", "omnisync-sample.tar", "tester" )
    @focus = @parser.parse
    @map_factory = MindMapFactory.new( @focus )
    @xml =  @map_factory.simple_map
    puts @xml
  end
 
  it "should create entries for folders and their projects" do
    @xml.xpath("map").attribute("version").content.should == "0.9.0"
    @xml.xpath("/map/node/node").size.should == 3
    @xml.xpath("/map/node/node[@TEXT = 'Personal']/node").size.should == 2
    @xml.at_xpath("/map/node/node/node[@TEXT = 'Plan']").parent.attribute("TEXT").content.should == "Secretive Project"
    
  end
  
  it "should assign positions to 'first child' nodes only" do    
    root = @xml.xpath("/map/node")
    root.attribute('POSITION').should be_nil
    
    personal = root.xpath("./node[@TEXT='Personal']")
    personal.attribute('POSITION').content.should == "right"

    personalProject = root.xpath("./node[1]")
    personalProject.should_not be_nil
    root.attribute('POSITION').should be_nil
    
  end
  
end
