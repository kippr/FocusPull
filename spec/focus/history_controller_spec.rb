require 'spec_helper'
require 'timecop'

describe HistoryController, "time_spent" do
  
  before(:all) do
    @history = HistoryController.new
    def @history.focus
      @focus ||= parse_test_archive
    end
  end
  
  it "should do something" do
    @history.time_spent.should include(2)
  end
  
end
