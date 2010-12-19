require File.dirname(__FILE__) + '/../src/archive_parser.rb'

describe FocusParser, "#parse" do

  before do
    @parser = FocusParser.new( "archives/2010.12.19_1407", "omnisync.tar", "kippr" )
  end
  
  it "should see projects" do
    @parser.parse
  end
end
