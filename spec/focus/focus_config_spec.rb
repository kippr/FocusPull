require 'spec_helper'

describe FocusConfig do

  before do
    @config = FocusConfig.new
  end

  describe "period in focus" do

    it "should default to last two weeks" do
     @config.period_description.should == "last 14 days"
    end

    it "should allow period to be changed" do
      @config.period_start = 3.weeks.ago.to_date
      @config.period_description.should == "last 21 days"
    end

  end

  describe "excluded nodes" do

    it "should default to 'Nothing' being excluded" do
      @config.should use_default_exclusions
    end

    it "should handle empty input" do
      @config.exclusions = nil
      @config.should use_default_exclusions
      @config.exclusions = ""
      @config.should use_default_exclusions
    end

    it "should handle single inputs" do
      @config.exclusions = "Personal"
      @config.should use_exclusions( "Personal" )
    end

    it "should handle comma separated inputs" do
      @config.exclusions = "Hello, World"
      @config.should use_exclusions( "Hello", "World" )
    end

  end
end
