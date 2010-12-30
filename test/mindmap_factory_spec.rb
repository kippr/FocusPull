require File.join(File.dirname(__FILE__), '../src/focus')
require File.join(File.dirname(__FILE__), '../src/mindmap_factory')
require 'nokogiri'

describe MindMapFactory, "simple_map" do

  before(:all) do
    @parser = FocusParser.new( "test", "omnisync-sample.tar", "tester" )
    @focus = @parser.parse
    @map_factory = MindMapFactory.new( @focus )
    @xml =  Nokogiri::Slop @map_factory.simple_map.to_s
    @root = @xml.at_xpath("/map")
  end
 
  # todo: quite brittle, what is a sensible test?
  it "should create entries for folders and their projects" do
    @root.attribute("version").content.should == "0.9.0"
    @root.node.node.size.should == 3
    @root.node.node(:xpath=>"@TEXT = 'Personal'").node.size.should == 2
    @root.at_xpath("./node/node/node[@TEXT = 'Plan']").parent.attribute("TEXT").content.should == "Secretive Project"
    
  end
  
  it "should assign positions to 'first child' nodes only" do    
    portfolio = @root.node
    portfolio.attribute('POSITION').should be_nil
    
    personal = portfolio.node(:xpath=>"@TEXT='Personal'")
    personal.attribute('POSITION').content.should == "right"

    personalProject = portfolio.node[1]
    personalProject.should_not be_nil
    portfolio.attribute('POSITION').should be_nil
    
  end
  
end
