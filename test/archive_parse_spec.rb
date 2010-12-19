require File.dirname(__FILE__) + '/../src/archive_parser.rb'

describe FocusParser, "#parse" do

  before do
    @parser = FocusParser.new( "archives/2010.12.19_2225", "omnisync.tar", "kippr" )
  end
  
  it "should see projects" do
    focus = @parser.parse
    focus.project("Spend less time in email").should_not be_nil
    focus.project_list.each { | project | puts project }
  end
end
