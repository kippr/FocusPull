require File.join(File.dirname(__FILE__), '../src/archive_parser')
require File.join(File.dirname(__FILE__), '../src/focus')

dir = "../archives/2010.12.19_2225"
#dir = "archives/2010.12.19_1407"

parser = FocusParser.new( dir, "omnisync.tar", "kippr" )
focus = parser.parse

out = Nokogiri::XML::Document.new()

root = out.create_element "map", :version => '0.9.0'
out << root
stack = []
stack.push root
push = lambda{ | root, node | el = out.create_element "node", :TEXT => node.name ; stack.last << el ; stack << el }
pop = lambda{ | root, node | stack.pop  }

focus.traverse(root, push, pop )

#xml = "<map version='0.9.0'>#{xml}</map>"

File.open("../test.mm", "w") { |f| f.write( out ) }