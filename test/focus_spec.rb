require File.join(File.dirname(__FILE__), '../src/focus')

describe Focus do

  before do
    @focus = Focus.new
    @mailProject = Project.new( "Spend less time in email", 1)
    @mailProject.link_parent( @focus )
    @mailTask = Task.new( "Collect useless mails in sd", 1)
    @mailTask.link_parent( @mailProject )
    @personalFolder = Folder.new( "Personal", 1)
    @personalFolder.link_parent( @focus )
    @openZoneProject = Project.new( "iPad has open zone access", 1 )
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
    @focus.to_a.should == [ @focus, @mailProject, @mailTask, @personalFolder, @openZoneProject ]
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
  
  it "should default task status to active" do
    @mailTask.status.should == "active"
    @mailTask.completed_date.should be_nil
  end
  
  it "should accept tasks as being marked complete" do
    @mailTask.completed( "2010-12-07T08:50:19.935Z" )
    @mailTask.status.should == "done"
    @mailTask.completed_date.should == Date.parse( "2010-12-07" )
  end
  
  it "should use modified date as completed date when status is dropped" do
    @openZoneProject.status = 'dropped'
    @openZoneProject.updated_date = "2010-11-30"
    @openZoneProject.completed_date.should == Date.parse( "2010-11-30" )
  end
  
  it "should use days from started to completed as age for done projects" do
    @mailTask.created_date = "2010-11-10"
    @mailTask.completed( "2010-11-20" ) 
    @mailTask.age.should == 10 
  end

  it "should use days from started to today as age for active projects" do
    @mailTask.created_date = ( Date.today - 30 ).to_s
    @mailTask.status = 'inactive'
    @mailTask.age.should == 30 
  end
  
  it "should implement the visitor pattern" do
    visitor = Visitor.new
    Project.new("", 0).visit( visitor ).should == "Visited a Project"
    Task.new("", 0).visit( visitor ).should == "Visited a Task"
    Folder.new("", 0).visit( visitor ).should == "Visited a Folder"
    Focus.new.visit( visitor ).should == "Visited Portfolio Root"
  end
  
end

class Visitor
  def visit_folder folder
    "Visited a Folder"
  end
  def visit_project project
    "Visited a Project"
  end
  def visit_task task
    "Visited a Task"
  end
  def visit_focus portfolio
    "Visited Portfolio Root"
  end
end
