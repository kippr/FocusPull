require 'spec_helper'
require 'timecop'

describe HistoryController, "time_spent" do
  
  before(:all) do
    @history = HistoryController.new
    def @history.focus
      Timecop.travel(2011, 1, 1) do
        @focus ||= parse_test_archive
      end
      @focus
    end
  end
  
  it "group done tasks into one bucket per week" do
    # 2010-11-26, 2010-12-13
    Timecop.travel(2011, 1, 1) do
      @history.time_spent['Admin'][-6..-1].should == [ 1, 0, 0, 1, 0, 0 ]
    end
  end

  it "group done projects, weighted more heavily than tasks, into one bucket per week" do
    # 2010-12-16
    Timecop.travel(2011, 1, 1) do
      @history.time_spent['Personal'][-6..-1].should == [ 0, 0, 0, 3, 0, 0 ]
    end
  end
  
end
