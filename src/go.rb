require 'rubygems'
require 'highline/import'
require 'activesupport'

require File.join(File.dirname(__FILE__), 'pull_archive')
require File.join(File.dirname(__FILE__), 'archive_parser')
require File.join(File.dirname(__FILE__), 'mindmap_factory')

username = 'kippr'
password = ask("Omnisync password for #{username}? ") { |q| q.echo = false }

directory = "../archives/#{Time.now.strftime("%Y.%m.%d_%H%M")}"
FileUtils.mkpath(directory)
filename = "omnisync.tar"

archive = download_archive( username, password )
archive.save("#{directory}/#{filename}")
@log.info("Saved #{filename} into #{directory}")

parser = FocusParser.new( directory, filename, username)
focus = parser.parse

@log.info "Saving simple map"
simple_map = MindMapFactory.create_simple_map focus
@log.info "Saving delta map for period #{1.week.ago} to #{Date.today}"
delta_map = MindMapFactory.create_delta_map focus, 1.week.ago.to_s, Date.today.to_s
@log.info "Saving meta map"
meta_map = MindMapFactory.create_meta_map focus

directory = "../output/#{Time.now.strftime("%Y.%m.%d_%H%M")}"
FileUtils.mkpath(directory)

File.open("#{directory}/focus.mm", "w") { |f| f.write( simple_map ) }
File.open("#{directory}/delta.mm", "w") { |f| f.write( delta_map ) }
File.open("#{directory}/meta.mm", "w") { |f| f.write( meta_map ) }





