require File.dirname(__FILE__) + '/../src/archive_parser.rb'

describe FocusParser, "#parse" do

  before(:all) do
    @parser = FocusParser.new( "archives/2010.12.19_2225", "omnisync.tar", "kippr" )
    @focus = @parser.parse
  end
  
  it "should read projects" do
    @focus.project("Spend less time in email").should_not be_nil
    @focus.project_list.first.name.should_not be_nil
  end
  
  it "should parse project status" do
    @focus.project("iPad has open zone access").status.should == "dropped"
    @focus.project("Spend less time in email").status.should == "active"
  end
  
  it "should read folders" do
    @focus.folder("Personal").should_not be_nil
    @focus.folder_list.each { | f | puts f }
  end
  
  it "should build the folder tree structure" do
    planFolder = @focus.folder("Plan")
    planFolder.parent.name.should == "FSA Liquidity"
    @focus.folder("FSA Liquidity").children.should include(planFolder)
  end

end
