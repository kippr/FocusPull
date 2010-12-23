require File.join(File.dirname(__FILE__), '../src/archive_parser')
require File.join(File.dirname(__FILE__), '../src/focus')

dir = "../archives/2010.12.19_2225"
#dir = "archives/2010.12.19_1407"

parser = FocusParser.new( dir, "omnisync.tar", "kippr" )
focus = parser.parse

push = lambda{ | xml, node | xml += "<node TEXT='#{node.name}'>" }
pop = lambda{ | xml, node | xml += "</node>"  }

xml = focus.traverse("", push, pop )

xml = "<map version='0.9.0'>#{xml}</map>"

File.open("../test.mm", "w+") { |f| f.write( xml ) }