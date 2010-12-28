require File.join(File.dirname(__FILE__), '../src/archive_parser')

describe FocusParser, "#parse" do

  before(:all) do
    @parser = FocusParser.new( "test", "omnisync-sample.tar", "tester" )
    @focus = @parser.parse
  end
  
  it "should read projects" do
    @focus.project("Spend less time in email").should_not be_nil
    @focus.projects.first.name.should_not be_nil
  end
  
  it "should parse project status" do
    @focus.project("iPad has open zone access").status.should == "dropped"
    @focus.project("Spend less time in email").status.should == "active"
  end
  
  it "should read folders" do
    @focus.folder("Personal").should_not be_nil
    @focus.folders.detect("Admin").should_not be_nil
  end
  
  it "should build the folder tree structure" do
    planFolder = @focus.folder("Plan")
    planFolder.parent.name.should == "FSA Liquidity"
    @focus.folder("FSA Liquidity").children.should include(planFolder)
  end
  
  it "should build links from projects to folders" do
    @focus.project("Spend less time in email").parent.name.should == "Admin"
  end
  
  it "should build a tree starting with orphan nodes linked into root" do
    @focus.name.should == "Portfolio"
    @focus.parent.should be_nil
    personal = @focus.children.detect{ |c| c.name == "Personal" }
    personal.should_not be_nil
    personal.children.map( &:name ).should include( "Switch to 3 network" )   
  end

end
