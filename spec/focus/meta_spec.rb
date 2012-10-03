require 'spec_helper'

describe GtdRules do

  before :all do
    @focus = parse_test_archive
    @rules = GtdRules.new( @focus )
  end

  describe "structure verification" do

    it 'should warn about idea projects that aren\'t on hold' do
      @rules.verify.should have_key( :active_idea_project )
       @rules.verify[ :active_idea_project ].should_not be_empty
    end

  end


end
