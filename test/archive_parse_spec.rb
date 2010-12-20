require File.dirname(__FILE__) + '/../src/archive_parser.rb'

describe FocusParser, "#parse" do

  before(:all) do
    @parser = FocusParser.new( "archives/2010.12.19_2225", "omnisync.tar", "kippr" )
    @focus = @parser.parse
  end
  
  it "should see projects" do
    @focus.project("Spend less time in email").should_not be_nil
    @focus.project_list.each { | project | puts project }
  end
  
  it "should parse project status" do
    @focus.project("iPad has open zone access").status.should == "dropped"
    @focus.project("Spend less time in email").status.should == "active"
  end
end
