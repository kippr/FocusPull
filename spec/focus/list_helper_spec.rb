require 'spec_helper'

describe ListHelper, "age histos" do

  before :all do
    @focus = parse_test_archive

    class ListHelperInstance
      include ListHelper
      def initialize focus
        @focus = focus
      end
    end
    @helper = ListHelperInstance.new @focus
  end
  
  it "should show zeros for days without no actions" do
    @helper.age_histo_for( :done ).should == [1,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,1]
  end

end
