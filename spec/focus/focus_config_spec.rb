require 'app/models/focus_config'
#require 'spec_helper'

describe FocusConfig, "period in focus" do

  it "should default to last two weeks" do
    FocusConfig.new.period_description.should == "last 2 weeks"
  end

end

describe FocusConfig, "excluded nodes" do

  it "should default to 'Nothing' being excluded" do
    FocusConfig.new.exclusion_description.should == "Nothing"
  end

end
