require File.join(File.dirname(__FILE__), '../src/focus')

describe Focus do

  before do
    @focus = Focus.new
    @mailProject = Project.new( "Spend less time in email" )
    @mailProject.link_parent( @focus )
    @mailTask = Task.new( "Collect useless mails in sd")
    @mailTask.link_parent( @mailProject )
    @personalFolder = Folder.new( "Personal" )
    @personalFolder.link_parent( @focus )
    @openZoneProject = Project.new( "iPad has open zone access" )
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
    @mailTask.completedDate.should be_nil
  end
  
  it "should accept tasks as being marked complete" do
    @mailTask.completed("2010-12-07T08:50:19.935Z")
    @mailTask.status.should == "done"
    @mailTask.completedDate.should == Date.parse("2010-12-07")
  end
  
  it "should implement the visitor pattern" do
    visitor = Visitor.new
    Project.new("").visit( visitor ).should == "Visited a Project"
    Task.new("").visit( visitor ).should == "Visited a Task"
    Folder.new("").visit( visitor ).should == "Visited a Folder"
    Focus.new.visit( visitor ).should == "Visited Portfolio Root"
  end
  
  it "should implement visitor pattern with arguments"
end

class Visitor
  def visitFolder folder
    "Visited a Folder"
  end
  def visitProject project
    "Visited a Project"
  end
  def visitTask task
    "Visited a Task"
  end
  def visitFocus portfolio
    "Visited Portfolio Root"
  end
end

class VisitorWithArgs
  def visitProject project, argument, *arguments
    puts argument.class
    argument + " Project"
  end
end
