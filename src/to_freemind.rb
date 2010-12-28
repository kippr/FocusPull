require File.join( File.dirname( __FILE__ ), '../src/archive_parser' )
require File.join( File.dirname( __FILE__ ), '../src/focus' )
require File.join( File.dirname( __FILE__ ), '../src/MindMapFactory' )

dir = "../archives/2010.12.19_2225"
#dir = "archives/2010.12.19_1407"

parser = FocusParser.new( dir, "omnisync.tar", "kippr" )
focus = parser.parse

xml = MindMapFactory.new( focus ).to_map_xml

File.open("../test.mm", "w") { |f| f.write( xml ) }