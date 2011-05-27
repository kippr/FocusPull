require 'focus'
class TestHelper
  
  def self.parse_test_archive
    parser = Focus::FocusParser.new( "spec/focus", "omnisync-sample.tar", "tester" )
    focus = parser.parse
    Focus::MindMapFactory.failing_test_hack = true
    focus
  end
  
  def self.reset_factory
    Focus::MindMapFactory.failing_test_hack = false
  end
  
end