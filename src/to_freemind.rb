require File.join( File.dirname( __FILE__ ), '../src/archive_parser' )
require File.join( File.dirname( __FILE__ ), '../src/focus' )
require File.join( File.dirname( __FILE__ ), '../src/mindmap_factory' )

dir = "../archives/2010.12.19_2225"
#dir = "archives/2010.12.19_1407"

parser = FocusParser.new( dir, "omnisync.tar", "kippr" )
focus = parser.parse

factory = MindMapFactory.new( focus )

xml = factory.simple_map

delta = factory.delta_map "2010-12-08", "2010-12-13"

File.open("../output/focus.mm", "w") { |f| f.write( xml ) }
File.open("../output/delta.mm", "w") { |f| f.write( delta ) }