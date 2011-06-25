require 'focus'

describe Focus::Focus do

  before do
    @focus = Focus::Focus.new
    @mailProject = Focus::Project.new( "Spend less time in email")
    @mailProject.link_parent( @focus )
    @mailAction = Focus::Action.new( "Collect useless mails in sd")
    @mailAction.link_parent( @mailProject )
    @personalFolder = Focus::Folder.new( "Personal" )
    @personalFolder.link_parent( @focus )
    @openZoneProject = Focus::Project.new( "iPad has open zone access" )
    @openZoneProject.link_parent( @personalFolder )
  end

  it "should not confuse folders with projects" do
    @focus.project("Spend less time in email").should == @mailProject
    @focus.folder("Spend less time in email").should be_nil
    @focus.project("Personal").should be_nil
    @focus.folder("Personal").should == @personalFolder
    @focus.projects.should_not == @focus.folders
  end
  
  it "should offer pre-order traversal" do
    @focus.to_a.should == [ @focus, @mailProject, @mailAction, @personalFolder, @openZoneProject ]
  end
  
  it "should offer pre-order traversal with callbacks" do
    push = lambda{ | x, n | x += "hello #{n.name}, "}
    pop = lambda{ | x, n | x += "#{n.name} bye! "}
    result = @focus.traverse("So, to begin with: ", push, pop )
    result.should == "So, to begin with: hello Portfolio, " +
      "hello Spend less time in email, " + 
      "hello Collect useless mails in sd, " +
      "Collect useless mails in sd bye! " +
      "Spend less time in email bye! " +
      "hello Personal, hello iPad has open zone access, " +
      "iPad has open zone access bye! Personal bye! " +
      "Portfolio bye! "
  end
  
  it "should offer gratuitous scope-creeping candy, like optional blocks" do
    postCollector = lambda{ | x, n, | x += "#{n.name}->" }
    result = @personalFolder.traverse("", nil, postCollector)
    result.should == "iPad has open zone access->Personal->"
  end
  
  it "should offer an optional traversal filter block, whereby sub-trees can be ignored" do
    collector = Proc.new{ | res, n |  res << n ; res }
    results = @focus.traverse( [], collector, nil ){ | n | n.name != 'Personal' }
    results.should_not include @personalFolder
    results.should_not include @openZoneProject
  end
  
  it "should default action status to active" do
    @mailAction.status.should == :active
    @mailAction.completed_date.should be_nil
  end
  
  it "should accept actions as being marked complete" do
    @mailAction.completed( "2010-12-07T08:50:19.935Z" )
    @mailAction.status.should == :done
    @mailAction.completed_date.should == Date.parse( "2010-12-07" )
  end
  
  it "should use modified date as completed date when status is dropped" do
    @openZoneProject.status = 'dropped'
    @openZoneProject.updated_date = "2010-11-30"
    @openZoneProject.completed_date.should == Date.parse( "2010-11-30" )
  end
  
  it "should leave the status for actions in completed projects as active" do
    @mailAction.status.should == :active
    @mailProject.completed( "2010-12-07T08:50:19.935Z" )
    @mailAction.status.should == :active
  end
  
  it "should override the status for actions in inactive projects to be inactive" do
    @mailAction.status.should == :active
    @mailProject.status = 'inactive'
    @mailAction.status.should == :inactive
  end

  it "should override the status for actions in dropped projects to be dropped" do
    @mailAction.status.should == :active
    @mailProject.status = 'dropped'
    @mailAction.status.should == :dropped
  end
  
  it "should use days from started to completed as age for done projects" do
    @mailAction.created_date = "2010-11-10"
    @mailAction.completed( "2010-11-20" ) 
    @mailAction.age.should == 10 
  end

  it "should use days from started to today as age for active projects" do
    @mailAction.created_date = ( Date.today - 30 ).to_s
    @mailAction.status = 'inactive'
    @mailAction.age.should == 30 
  end
  
  it "should implement the visitor pattern" do
    visitor = Visitor.new
    Focus::Project.new( "" ).visit( visitor ).should == "Visited a Project"
    Focus::Action.new( "" ).visit( visitor ).should == "Visited an Action"
    Focus::Folder.new( "" ).visit( visitor ).should == "Visited a Folder"
    Focus::Focus.new.visit( visitor ).should == "Visited Portfolio Root"
  end
  
  describe "stalled projects" do
    
    it "should mark as stalled any projects without children" do
      @focus.stalled_projects.should include( @openZoneProject )
    end

    it "should not mark as stalled any single actions projects" do
      @openZoneProject.set_single_actions
      @focus.stalled_projects.should_not include( @openZoneProject )
    end
    
    it "should not mark as stalled any inactive projects" do
      @openZoneProject.status = :inactive
      @focus.stalled_projects.should_not include( @openZoneProject )
    end

    it "should mark as stalled any projects without active children" do
      @mailAction.completed( Date.today.to_s )
      @focus.stalled_projects.should include( @mailProject )
    end
    
  end
  
  describe Focus::List do
    
    it "should offer simple traversal over focus items" do
      @focus.list.should include( @mailAction )
    end
    
  end
    
end

class Visitor
  def visit_folder folder
    "Visited a Folder"
  end
  def visit_project project
    "Visited a Project"
  end
  def visit_action action
    "Visited an Action"
  end
  def visit_focus portfolio
    "Visited Portfolio Root"
  end
end
