require File.dirname(__FILE__) + '/../src/focus.rb'

describe Focus do

  before do
    @focus = Focus.new
    @mailProject = Project.new( "Spend less time in email" )
    @mailProject.link_parent( @focus )
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
    @focus.to_a.should == [ @focus, @mailProject, @personalFolder, @openZoneProject ]
  end
  
  it "should offer pre-order traversal with callbacks" do
    push = lambda{ | x, n | x += "hello #{n.name}, "}
    pop = lambda{ | x, n | x += "#{n.name} bye! "}
    result = @focus.traverse("So, to begin with: ", push, pop )
    result.should == "So, to begin with: hello Portfolio, " +
      "hello Spend less time in email, Spend less time in email bye! " +
      "hello Personal, hello iPad has open zone access, " +
      "iPad has open zone access bye! Personal bye! " +
      "Portfolio bye! "
  end
  
  it "should offer gratuitous scope-creeping candy, like optional blocks" do
    postCollector = lambda{ | x, n, | x += "#{n.name}->" }
    @personalFolder.traverse("", nil, postCollector).should == "iPad has open zone access->Personal->"
  end
end