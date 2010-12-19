require 'rubygems'
require 'highline/import'

require File.dirname(__FILE__) + '/pull_archive'
require File.dirname(__FILE__) + '/archive_parser'

username = 'kippr'
password = ask("Omnisync password for #{username}? ") { |q| q.echo = false }

directory = "./archives/#{Time.now.strftime("%Y.%m.%d_%H%M")}"
FileUtils.mkpath(directory)
filename = "omnisync.tar"

archive = download_archive( username, password )
archive.save("#{directory}/#{filename}")
@log.info("Saved #{filename} into #{directory}")

parser = FocusParser.new( directory, filename, username)
focus = parser.parse
puts focus

