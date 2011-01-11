require 'timecop'

require File.join(File.dirname(__FILE__), '../src/focus')
require File.join(File.dirname(__FILE__), '../src/histo')

describe Histogram do

  before(:all) do
    @parser = FocusParser.new( "test", "omnisync-sample.tar", "tester" )
    @histo = Histogram.new( @parser.parse )
  end
  
  it "should plot done projects by age in days" do
    results = @histo.results
    results.done_projects[ 8 ].size.should == 1
    results.done_projects[ 2 ].size.should == 0
  end
  
  it "should be enumerable, to produce all results" do
    Timecop.travel(2011, 1, 9) do
      @histo.first.should == "Day, Open projects, Done projects, Active tasks, Done tasks"
      @histo.to_a[ 12 ].should ==  "12, 0, 0, 0, 0"
      @histo.to_a[ 102 ].should ==  "102, 1, 0, 0, 0"
    end
  end
  
end
