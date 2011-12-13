require 'spec_helper'
require 'focus'

describe TreeMap do

  describe '#remaining' do

    before(:all) do
      @focus = parse_test_archive
      @tree = TreeMap.remaining( @focus )
      @json = @tree.to_json
    end

    it 'should include name of nodes' do
      @json.should match '"name":\s*"Portfolio"' 
    end

    it 'should include child nodes' do
      @json.should match '"children":\s*\[.*"name":\s*"Spend less time in email".*\]'
    end

    it 'should use path to root as id' do
      find( 'Collect useless mails in sd' ).path.should == 'Portfolio/Admin/Spend less time in email/Collect useless mails in sd'
    end

    it 'should build a tree' do
      @tree.children.should include_tree_node( 'Admin' )
    end

    it 'should not include Contexts' do
      find( 'Waiting' ).should be_nil
    end

    it 'should include inactive projects' do
      find('Meet simon for lunch').should_not be_nil
    end

  end

  describe '#active' do

    before(:all) do
      @focus = parse_test_archive
      @tree = TreeMap.active( @focus )
      @json = @tree.to_json
    end

    it 'should exclude inactive projects' do
      find('Meet simon for lunch').should be_nil
    end

  end

  def find by_name
    @tree.detect{ |n| n.name == by_name }
  end

end
