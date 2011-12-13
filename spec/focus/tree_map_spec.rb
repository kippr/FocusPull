require 'spec_helper'
require 'focus'

describe TreeMap, 'to_json' do

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
    action = @focus.list.detect{ |n| n.name == 'Confirm names for 2011' }
    tree = TreeMap.active action
    tree.to_json.should match 'Portfolio/Admin/Setup 2011 vacsheet/Confirm names for 2011'
  end

  it 'should build a tree' do
    @tree.children.should include_tree_node( 'Admin' )
  end

end

