require 'timecop'

require File.join(File.dirname(__FILE__), '../src/focus')
require File.join(File.dirname(__FILE__), '../src/graphable')

describe Graphable, "histogram" do

  before(:all) do
    @parser = FocusParser.new( "test", "omnisync-sample.tar", "tester" )
    Timecop.travel(2011, 1, 9) { @histo = Graphable.histo( @parser.parse ) }
  end
  
  it "should plot done projects by age in days" do
    @histo.done_projects[ 8 ].size.should == 1
    @histo.done_projects[ 2 ].size.should == 0
  end
  
  it "should be enumerable, to spit out all results in csv format" do
    @histo.first.should == "Day, Open projects, Done projects, Active actions, Done actions"
    @histo.to_a[ 12 ].should ==  "12, 0, 0, 0, 0"
    @histo.to_a[ 102 ].should ==  "102, 1, 0, 0, 0"
  end
  
end

describe Graphable, "trend" do
  
  before(:all) do
    @parser = FocusParser.new( "test", "omnisync-sample.tar", "tester" )
    @trend = Graphable.trend( @parser.parse )
  end

  it "should be enumerable, to spit out all results in csv format" do
    @trend.first.should == "Day, Added projects, Completed projects, Added actions, Completed actions"
    @trend.to_a.should include("2010-11-24, 1, 0, 1, 0")
  end
  
end
