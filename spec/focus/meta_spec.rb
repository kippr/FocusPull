require 'spec_helper'

describe GtdRules do

  before :all do
    @focus = parse_test_archive
    @rules = GtdRules.new( @focus )
  end

  describe "structure verification" do

    it 'should warn about Goals and Ideas projects that aren\'t on hold' do
      @rules.verify.should have_key( :projects_that_should_not_be_active )
       @rules.verify[ :projects_that_should_not_be_active ].should_not be_empty
    end

    it 'should warn about Idea, Goal and Action projects that aren\'t single action projects' do
      @rules.verify.should have_key( :projects_that_should_be_single_action )
    end

    it 'should warn about Idea, Goal and Action projects whose name doesn\'t mirror the containing folder' do
      @rules.verify.should have_key( :projects_whose_name_should_mirror_folder_name )
    end

  end


end
