require 'spec_helper'

describe Date, "commercial year and week" do

  it '2 Jan 2011 is a Sunday, so is in last commercial week of 2010' do
    Date.new( 2011, 01, 02 ).cwyear_and_week.should == 201052
  end

  it '3 Jan 2011 is a Monday, in the first commercial week of 2011' do
    Date.new( 2011, 01, 03 ).cwyear_and_week.should == 201101
  end

  it '4 Jan 2011 falls into same week as 3 Jan' do
    Date.new( 2011, 01, 04 ).cwyear_and_week.should == 201101
  end

end