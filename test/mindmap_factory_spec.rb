require File.join(File.dirname(__FILE__), '../src/focus')
require File.join(File.dirname(__FILE__), '../src/archive_parser')
require File.join(File.dirname(__FILE__), '../src/mindmap_factory')
require 'nokogiri'

describe MindMapFactory, "create_simple_map" do

  #todo: fair amount of duplication in the befores now...
  before(:all) do
    @parser = FocusParser.new( "test", "omnisync-sample.tar", "tester" )
    @focus = @parser.parse
    MindMapFactory.failing_test_hack = true
    # attributes are disabled by default, but leave in tests, since that's handier that splitting all out
    @map = MindMapFactory.create_simple_map( @focus, :ADD_ATTRIBUTES => true, :STATUSES_TO_INCLUDE => [ :active, :done, :inactive, :dropped ] )
    @xml =  Nokogiri::Slop @map.to_s
    @root = @xml.at_xpath( "/map" )
  end
  
  after(:all) do
    MindMapFactory.failing_test_hack = false
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
  
  it "should colour folders with no projects or actions as faded" do
    childless_folder = node_for( 'Secretive Project' )
    childless_folder['COLOR'].should == "#bfd8e5"
  end
  
  
  it "should fold projects with child actions" do
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
  
  it "should add a status attribute to actions" do
    attribute_for( 'Collect useless mails in sd', 'status' ).should == 'active'
  end

  it "should add an icon to projects that are on hold" do
    node_for( 'Meet simon for lunch' ).icon['BUILTIN'].should == 'stop-sign'
  end

  it "should add an icon to projects and actions that are done" do
    node_for( 'Switch to 3 network' ).icon['BUILTIN'].should == 'button_ok'
  end
  
  it "should add an icon to projects that have been dropped" do
    node_for( 'iPad has open zone access' ).icon['BUILTIN'].should == 'button_cancel'
  end

  it "should *not* highlight active projects and actions" do
    node_for( 'Spend less time in email' ).at_xpath( './icon' ).should be_nil
    node_for( 'Review progress on mails collected' ).at_xpath( './icon' ).should be_nil
  end
  
  it "should add a created attribute to actions and project" do
    project = 'Switch to 3 network'
    attribute_for( project, 'created' ).should == '2010-12-08'
    action = 'Collect useless mails in sd'
    attribute_for( action, 'created' ).should == '2010-11-24'
  end

  it "should add a updated attribute to actions and project" do
    project = 'Switch to 3 network'
    attribute_for( project, 'updated' ).should == '2010-12-16'
    action = 'Record # of mails in inbox before and after'
    attribute_for( action, 'updated' ).should == '2010-12-13'
  end

  it "should add a completed attribute to finished actions and project" do
    project= 'Switch to 3 network'
    attribute_for( project, 'completed' ).should == '2010-12-16'
    action = 'Record # of mails in inbox before and after'
    attribute_for( action, 'completed' ).should == '2010-12-13'
  end
    
  it "should distinguish actions" do
    action = node_for( 'Collect useless mails in sd' )  
    action['COLOR'].should == '#444444'
    # Prefer not to assert all the details, but freemind is picky about these
    action.font['SIZE'].should == '9'
    action.font['NAME'].should == 'SansSerif'
  end
  
  it "should add thicker edges to 'heavy' folders" do
    node_for( 'Personal' ).edge['COLOR'].should == '#cccccc' # nothing active
    node_for( 'Admin' ).edge['COLOR'].should == '#99a300' # 2 active projs, 2 actions
  end
  
  it "should offer a way of excluding sub-trees" do
    @map = MindMapFactory.create_simple_map( @focus, :EXCLUDE_NODES => ['Spend less time in email', 'Personal'] )
    @xml =  Nokogiri::Slop @map.to_s
    node_for( 'Personal' ).should be_nil
    node_for( 'Spend less time in email' ).should be_nil
    node_for( 'Admin' ).should_not be_nil
  end
    
end  

describe MindMapFactory, "create_delta_map" do

  before(:all) do
    @parser = FocusParser.new( "test", "omnisync-sample.tar", "tester" )
    @focus = @parser.parse
    MindMapFactory.failing_test_hack = true
    @map = MindMapFactory.create_delta_map( @focus, "2010-12-08", "2010-12-13" )
    @xml =  Nokogiri::Slop @map.to_s
    @root = @xml.at_xpath( "/map" )
  end
  
  after(:all) do
    MindMapFactory.failing_test_hack = false
  end
  
  
  it "should include filtering dates in 'portfolio' node name" do
    @root.node.richcontent['TYPE'].should == 'NODE'
    @root.node.richcontent.body.p[0].font.content.should == 'Portfolio'
    @root.node.richcontent.body.p[1].font.content.should == '2010-12-08..2010-12-13'
  end
  
  it "should include newly created projects, and their parent folders" do
    node_for( 'Setup 2011 vacsheet' ).parent['TEXT'].should == "Admin"
  end
  
  it "should not include actions that didn't change" do
    node_for( 'Meet simon for lunch' ).should be_nil
  end

  it "should include projects that have been dropped in the specified period" do
    node_for( "iPad has open zone access" ).should_not be_nil
  end  
    
  it "should include projects that didn't change but have child actions that did" do
    unchanged_project = node_for( 'Spend less time in email' )
    unchanged_project.should_not be_nil
    completed_action = node_for( 'Record # of mails in inbox before and after' )
    completed_action.parent.should == unchanged_project 
    # this is an unchanged child of unchanged project
    unchanged_action = node_for( 'Collect useless mails in sd' ) 
    unchanged_action.should be_nil
  end
  
  it "should fold projects with child actions, by default" do
    node_for( 'Spend less time in email' )['FOLDED'].should == 'true'
  end
  
  it "should fade (unchanged) projects that are included only because sub-actions changed" do
    unchanged_project = node_for( "Spend less time in email" )
    unchanged_project[ 'COLOR' ].should == '#666666'
  end
  
  it "should highlight active projects and actions, as these must have been added recently" do
    # the mail project is only there b/c of sub-actions and therefore shouldn't have icon
    node_for( 'Spend less time in email' ).at_xpath( './icon' ).should be_nil
    node_for( 'Review progress on mails collected' ).icon['BUILTIN'].should == 'idea'
  end
  
  it "should weight both active and done projects & actions" do
    node_for( 'Spend less time in email' ).edge['COLOR'].should == '#7ae07a'
  end
  
end

describe MindMapFactory, "create_delta_map for new projects" do
  
  before(:all) do
    @parser = FocusParser.new( "test", "omnisync-sample.tar", "tester" )
    @focus = @parser.parse
    MindMapFactory.failing_test_hack = true
    @map = MindMapFactory.create_delta_map( @focus, "2010-12-08", "2010-12-13", :new_projects )
    @xml =  Nokogiri::Slop @map.to_s
    @root = @xml.at_xpath( "/map" )
  end
  
  it "should exclude new actions" do
    node_for( "Review progress on mails collected" ).should be_nil
  end
  
  it "should not include new projects that were also completed in same period, these make more sense in done view" do
    node_for( "Switch to 3 network" ).should be_nil
  end
  
  it "should specify new projects only in description 'portfolio' node name" do
    @root.node.richcontent.body.p[0].font.content.should == 'Portfolio'
    @root.node.richcontent.body.p[1].font.content.should == 'New projects 2010-12-08..2010-12-13'
  end
  
  
  after(:all) do
    MindMapFactory.failing_test_hack = false
  end
  
end  

describe MindMapFactory, "create_delta_map for completed items" do

  before(:all) do
    @parser = FocusParser.new( "test", "omnisync-sample.tar", "tester" )
    @focus = @parser.parse
    MindMapFactory.failing_test_hack = true
    @map = MindMapFactory.create_delta_map( @focus, "2010-12-08", "2010-12-13", :all_done )
    @xml =  Nokogiri::Slop @map.to_s
    @root = @xml.at_xpath( "/map" )
  end
  
  after(:all) do
    MindMapFactory.failing_test_hack = false
  end

  it "should include filtering dates in 'portfolio' node name" do
    @root.node.richcontent['TYPE'].should == 'NODE'
    @root.node.richcontent.body.p[0].font.content.should == 'Portfolio'
    @root.node.richcontent.body.p[1].font.content.should == 'Completed 2010-12-08..2010-12-13'
  end

  it "should include projects that have been dropped in the specified period" do
    node_for( "iPad has open zone access" ).should_not be_nil
  end  
  
  it "should not include newly created projects" do
    node_for( 'Setup 2011 vacsheet' ).should be_nil
  end
  
  it "should barf when an invalid filter type is passed" do
    lambda{ MindMapFactory.create_delta_map( @focus, "2010-12-08", "2010-12-13", :monkey ) }.should raise_error
  end
  
end

describe MindMapFactory, "create_meta_map" do
  
  before(:all) do
    @parser = FocusParser.new( "test", "omnisync-sample.tar", "tester" )
    @focus = @parser.parse
    MindMapFactory.failing_test_hack = false
    @map = MindMapFactory.create_meta_map( @focus )
    @xml =  Nokogiri::Slop @map.to_s
    @root = @xml.at_xpath( "/map" )
  end
  
  after(:all) do
    MindMapFactory.failing_test_hack = false
  end
  
  it "should be rooted with a meta-node that has info on tree" do
    @root.node['TEXT'].should ==  "Meta" 
  end
  
  it "should have projects and actions nodes that aggregate per status" do
    projects = node_for( "Projects" )
    projects.node.size.should == 4 # 4 statuses for projects
    projects.node.last['TEXT'].should == "Dropped: 1"
    projects.parent['TEXT'].should == "By status"
    
    actions = node_for( "Actions" )
    actions.node.size.should == 2 # 2 statuses for actions
    actions.node.first['TEXT'].should == "Active: 2"
    actions.node.first.node.size == 2 # Two sub-nodes of active, one for each active action
  end
  
  context "when adding actionless projects node" do
    it "should have add active projects without a next step defined" do
      actionless = node_for( "Actionless projects" )
      actionless.children.collect{ | n | n['TEXT'] }.should include( 'Setup 2011 vacsheet' )
    end

    it "should not add done or inactive projects" do
      actionless = node_for( "Actionless projects" )
      actionless.children.collect{ | n | n['TEXT'] }.should_not include( 'iPad has open zone access' )
    end
  end

  it "should have an 'aged projects' node" do
    #todo: this test will start failing as other projects get 'old'
    node_for( "Aged projects (1)" ).at_xpath(".//node[@TEXT = 'Meet simon for lunch']").should_not be_nil
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
