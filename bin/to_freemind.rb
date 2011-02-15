require 'focus'

dir = "archives/2010.12.19_2225"
#dir = "archives/2010.12.19_1407"

parser = Focus::FocusParser.new( dir, "omnisync.tar", "kippr" )
focus = parser.parse

xml = Focus::MindMapFactory.create_simple_map focus

delta = Focus::MindMapFactory.create_delta_map focus, "2010-12-08", "2010-12-13"
delta_done = Focus::MindMapFactory.create_delta_map focus, "2010-12-08", "2010-12-13", :all_done

meta = Focus::MindMapFactory.create_meta_map focus

File.open("output/focus.mm", "w") { |f| f.write( xml ) }
File.open("output/delta.mm", "w") { |f| f.write( delta ) }
File.open("output/delta-done.mm", "w") { |f| f.write( delta_done ) }
File.open("output/meta.mm", "w") { |f| f.write( meta ) }

#Also handy to have
parser = Focus::FocusParser.new( "test", "omnisync-sample.tar", "tester" )
focus = parser.parse

xml = Focus::MindMapFactory.create_simple_map focus

delta = Focus::MindMapFactory.create_delta_map focus, "2010-12-08", "2010-12-13"

meta = Focus::MindMapFactory.create_meta_map focus

File.open("output/focus-sample.mm", "w") { |f| f.write( xml ) }
File.open("output/delta-sample.mm", "w") { |f| f.write( delta ) }
File.open("output/meta-sample.mm", "w") { |f| f.write( meta ) }
