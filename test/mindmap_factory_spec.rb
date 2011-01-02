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
    @root['version'].should == "0.9.0"
    @root.node.node.size.should == 3
    personal_project = @root.node.node(:xpath=>"@TEXT = 'Personal'").node
    personal_project.should_not be_nil
    done_project = "Switch to 3 network"
    #personal_projects.at_xpath(:xpath=>"@TEXT").should be_nil
    #todo: assert done_project is not included
    @root.at_xpath("./node/node/node[@TEXT = 'Plan']").parent.attribute("TEXT").content.should == "Secretive Project"
  end
  
  it "should assign positions to 'first child' nodes only" do    
    portfolio = @root.node
    portfolio.attribute('POSITION').should be_nil
    
    personal = portfolio.node(:xpath=>"@TEXT='Personal'")
    personal['POSITION'].should == "right"

    personalProject = portfolio.node[1]
    personalProject.should_not be_nil
    portfolio['POSITION'].should be_nil   
  end
  
  it "should colour folders" do
    portfolio = @root.node
    personalFolder = portfolio.node[0]
    portfolio['COLOR'].should be_nil
    personalFolder['COLOR'].should == "#006699"
  end
  
  it "should fold projects with child tasks" do
    project = @xml.at_xpath("//node[@TEXT='Spend less time in email']")
    project['FOLDED'].should be_true
    @root['FOLDED'].should_not be_true
  end
  
  it "should distinguish inactive projects" do
    inactiveProject = @xml.at_xpath("//node[@TEXT = 'Meet simon for lunch']")
    inactiveProject['COLOR'].should == '#666666'
    # Prefer not to assert all the details, but freemind is picky about these
    inactiveProject.font['ITALIC'].should be_true
    inactiveProject.font['SIZE'].should == '12'
    inactiveProject.font['NAME'].should == 'SansSerif'    
  end
  
end
