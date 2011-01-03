require File.join( File.dirname( __FILE__ ), '../src/archive_parser' )
require File.join( File.dirname( __FILE__ ), '../src/focus' )
require File.join( File.dirname( __FILE__ ), '../src/mindmap_factory' )

dir = "../archives/2010.12.19_2225"
#dir = "archives/2010.12.19_1407"

parser = FocusParser.new( dir, "omnisync.tar", "kippr" )
focus = parser.parse

xml = MindMapFactory.create_simple_map focus

delta = MindMapFactory.create_delta_map focus, "2010-12-08", "2010-12-13"

File.open("../output/focus.mm", "w") { |f| f.write( xml ) }
File.open("../output/delta.mm", "w") { |f| f.write( delta ) }

#Also handy to have
parser = FocusParser.new( "../test", "omnisync-sample.tar", "tester" )
focus = parser.parse
xml = MindMapFactory.create_simple_map focus
delta = MindMapFactory.create_delta_map focus, "2010-12-08", "2010-12-13"

File.open("../output/focus-sample.mm", "w") { |f| f.write( xml ) }
File.open("../output/delta-sample.mm", "w") { |f| f.write( delta ) }

