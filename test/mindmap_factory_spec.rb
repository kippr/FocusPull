require File.join(File.dirname(__FILE__), '../src/focus')
require File.join(File.dirname(__FILE__), '../src/mindmap_factory')
require 'nokogiri'

describe MindMapFactory, "create_simple_map" do

  before(:all) do
    @parser = FocusParser.new( "test", "omnisync-sample.tar", "tester" )
    @focus = @parser.parse
    @map = MindMapFactory.create_simple_map( @focus )
    @xml =  Nokogiri::Slop @map.to_s
    @root = @xml.at_xpath( "/map" )
  end
 
  it "should set map xml version" do
    @root['version'].should == "0.9.0"
  end
  
  it "should hide attributes by default" do
    @root.attribute_registry['SHOW_ATTRIBUTES'].should == 'hide'
  end
  
  # todo: quite brittle, what is a sensible test?
  it "should create entries for folders and their projects" do
    personal_project = node_for( 'Personal' ).node
    personal_project.size.should == 3
    node_for( 'Plan' ).parent['TEXT'].should == "Secretive Project"
  end
  
  it "should assign positions to 'first child' nodes only" do    
    @root.node['POSITION'].should be_nil
    
    top_level_folder = node_for( 'Personal' )
    top_level_folder['POSITION'].should == "right"

    second_level_item = top_level_folder.node[0]
    second_level_item['POSITION'].should be_nil   
  end
  
  it "should colour folders" do
    @root.node['COLOR'].should be_nil
    node_for( 'Personal' )['COLOR'].should == "#006699"
  end
  
  it "should colour folders with no projects or tasks as faded" do
    childless_folder = node_for( 'Secretive Project' )
    childless_folder['COLOR'].should == "#bfd8e5"
  end
  
  
  it "should fold projects with child tasks" do
    node_for( 'Spend less time in email' )['FOLDED'].should be_true
    @root['FOLDED'].should_not be_true
  end
  
  it "should distinguish projects that are on hold" do
    inactiveProject = node_for( 'Meet simon for lunch' )
    inactiveProject['COLOR'].should == '#666666'
    # Prefer not to assert all the details, but freemind is picky about these
    inactiveProject.font['ITALIC'].should be_true
    inactiveProject.font['SIZE'].should == '12'
    inactiveProject.font['NAME'].should == 'SansSerif'    
  end
  
  it "should add a status attribute to projects" do
    # todo: this might be nice with a custom 'should be'?
    attribute_for( 'Meet simon for lunch', 'status' ).should == 'inactive'
  end
  
  it "should add a status attribute to tasks" do
    attribute_for( 'Collect useless mails in sd', 'status' ).should == 'active'
  end

  it "should add an icon to projects that are on hold" do
    node_for( 'Meet simon for lunch' ).icon['BUILTIN'].should == 'stop-sign'
  end

  it "should add an icon to projects and tasks that are done" do
    node_for( 'Switch to 3 network' ).icon['BUILTIN'].should == 'button_ok'
  end
  
  it "should add an icon to projects that have been dropped" do
    node_for( 'iPad has open zone access' ).icon['BUILTIN'].should == 'button_cancel'
  end

  it "should *not* highlight active projects and tasks" do
    node_for( 'Spend less time in email' ).at_xpath( './icon' ).should be_nil
    node_for( 'Review progress on mails collected' ).at_xpath( './icon' ).should be_nil
  end
  
  it "should add a created attribute to tasks and project" do
    project = 'Switch to 3 network'
    attribute_for( project, 'created' ).should == '2010-12-08'
    task = 'Collect useless mails in sd'
    attribute_for( task, 'created' ).should == '2010-11-24'
  end

  it "should add a updated attribute to tasks and project" do
    project = 'Switch to 3 network'
    attribute_for( project, 'updated' ).should == '2010-12-16'
    task = 'Record # of mails in inbox before and after'
    attribute_for( task, 'updated' ).should == '2010-12-13'
  end

  it "should add a completed attribute to finished tasks and project" do
    project= 'Switch to 3 network'
    attribute_for( project, 'completed' ).should == '2010-12-16'
    task = 'Record # of mails in inbox before and after'
    attribute_for( task, 'completed' ).should == '2010-12-13'
  end
    
  it "should distinguish tasks" do
    task = node_for( 'Collect useless mails in sd' )  
    task['COLOR'].should == '#444444'
    # Prefer not to assert all the details, but freemind is picky about these
    task.font['SIZE'].should == '9'
    task.font['NAME'].should == 'SansSerif'
  end
  
  it "should add thicker edges to 'heavy' folders" do
    node_for( 'Personal' ).edge['COLOR'].should == '#cccccc' # nothing active
    node_for( 'Admin' ).edge['COLOR'].should == '#000088' # 1 active proj, 2 tasks
  end
    
end  

describe MindMapFactory, "create_delta_map" do

  before(:all) do
    @parser = FocusParser.new( "test", "omnisync-sample.tar", "tester" )
    @focus = @parser.parse
    @map = MindMapFactory.create_delta_map( @focus, "2010-12-08", "2010-12-13" )
    @xml =  Nokogiri::Slop @map.to_s
    @root = @xml.at_xpath( "/map" )
  end
  
  it "should include filtering dates in 'portfolio' node name" do
    @root.node['TEXT'].should == 'Portfolio 2010-12-08..2010-12-13'
  end
  
  it "should include newly created projects, and their parent folders" do
    node_for( 'Switch to 3 network' ).parent['TEXT'].should == "Personal"
  end
  
  it "should not include tasks that didn't change" do
    node_for( 'Meet simon for lunch' ).should be_nil
  end

  it "should include projects that have been dropped in the specified period" do
    node_for( "iPad has open zone access" ).should_not be_nil
  end  
    
  it "should include projects that didn't change but have child tasks that did" do
    unchanged_project = node_for( 'Spend less time in email' )
    unchanged_project.should_not be_nil
    completed_task = node_for( 'Record # of mails in inbox before and after' )
    completed_task.parent.should == unchanged_project 
    # this is an unchanged child of unchanged project
    unchanged_task = node_for( 'Collect useless mails in sd' ) 
    unchanged_task.should be_nil
  end
  
  it "should *not* fold projects with child tasks, by default" do
    node_for( 'Spend less time in email' )['FOLDED'].should be_nil
  end
  
  it "should fade (unchanged) projects that are included only because sub-tasks changed" do
    unchanged_project = node_for( "Spend less time in email" )
    unchanged_project[ 'COLOR' ].should == '#666666'
  end
  
  it "should highlight active projects and tasks, as these must have been added recently" do
    # the mail project is only there b/c of sub-tasks and therefore shouldn't have icon
    node_for( 'Spend less time in email' ).at_xpath( './icon' ).should be_nil
    node_for( 'Review progress on mails collected' ).icon['BUILTIN'].should == 'idea'
  end
  
end

describe MindMapFactory, "create_meta_map" do
  
  before(:all) do
    @parser = FocusParser.new( "test", "omnisync-sample.tar", "tester" )
    @focus = @parser.parse
    @map = MindMapFactory.create_meta_map( @focus )
    @xml =  Nokogiri::Slop @map.to_s
    @root = @xml.at_xpath( "/map" )
  end
  
  it "should be rooted with a meta-node that has info on tree" do
    @root.node['TEXT'].should ==  "Meta" 
    node_for( "Projects" ).node.size.should == 4
    node_for( "Projects" ).node.last['TEXT'].should == "Dropped: 1"
    node_for( "Tasks" ).node.size.should == 2
    node_for( "Tasks" ).node.first['TEXT'].should == "Active: 2"
  end
  
end

def node_for item_name
  @xml.at_xpath("//node[@TEXT = '#{item_name}']")  
end
  
def attribute_for item_name, attribute_name
  item = node_for item_name
  attribute = item && item.at_xpath("./attribute[@NAME = '#{attribute_name}']")
  attribute && attribute['VALUE']
end
