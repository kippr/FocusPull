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
end