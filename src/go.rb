require 'rubygems'
require 'highline/import'

require File.dirname(__FILE__) + '/pull_archive.rb'
require File.dirname(__FILE__) + '/archive_parser.rb'

username = 'kippr'
password = ask("Omnisync password for #{username}? ") { |q| q.echo = false }

directory = "./archives/#{Time.now.strftime("%Y.%m.%d_%H%M")}"
FileUtils.mkpath(directory)
filename = "omnisync.tar"

archive = download_archive( username, password )
archive.save("#{directory}/#{filename}")
@log.info("Saved #{filename} into #{directory}")

focus = parse( directory, filename, username)
puts focus

