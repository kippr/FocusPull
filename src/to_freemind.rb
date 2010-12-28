require File.join( File.dirname( __FILE__ ), '../src/archive_parser' )
require File.join( File.dirname( __FILE__ ), '../src/focus' )
require File.join( File.dirname( __FILE__ ), '../src/mindmap_factory' )

dir = "../archives/2010.12.19_2225"
#dir = "archives/2010.12.19_1407"

parser = FocusParser.new( dir, "omnisync.tar", "kippr" )
focus = parser.parse

xml = MindMapFactory.new( focus ).simple_map

File.open("../output/focus.mm", "w") { |f| f.write( xml ) }