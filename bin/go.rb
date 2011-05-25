require 'focus'


require 'highline/import'
require 'active_support/core_ext'
require 'fileutils'
require 'logger'
log = Logger.new(STDOUT)


username = 'kippr'
password = ask("Omnisync password for #{username}? ") { |q| q.echo = false }

directory = "archives/#{Time.now.strftime("%Y.%m.%d")}"
FileUtils.rm_rf(directory)
FileUtils.mkpath(directory)
filename = "omnisync.tar"

archive = Focus::ArchivePull.download_archive( username, password )
archive.save("#{directory}/#{filename}")
log.info("Saved #{filename} into #{directory}") 

parser = Focus::FocusParser.new( directory, filename, username)
focus = parser.parse

#options = { :EXCLUDE_NODES => [ 'Personal', 'Meta' ] }
options = {  }

log.info "Saving simple map"
simple_map = Focus::MindMapFactory.create_simple_map focus, options
log.info "Saving delta map for period #{6.days.ago} to #{Date.today}"
delta_map = Focus::MindMapFactory.create_delta_map focus, 6.days.ago.to_s, Date.today.to_s, :both_new_and_done, options
log.info "Saving completion delta map for period #{6.days.ago} to #{Date.today}"
done_delta_map = Focus::MindMapFactory.create_delta_map focus, 6.days.ago.to_s, Date.today.to_s, :all_done, options
log.info "Saving additions delta map for period #{6.days.ago} to #{Date.today}"
new_delta_map = Focus::MindMapFactory.create_delta_map focus, 6.days.ago.to_s, Date.today.to_s, :new_projects, options
log.info "Saving meta map"
meta_map = Focus::MindMapFactory.create_meta_map focus

directory = "output/#{Time.now.strftime("%Y.%m.%d")}"
FileUtils.mkpath(directory)

File.open("#{directory}/focus.mm", "w") { |f| f.write( simple_map ) }
File.open("#{directory}/changes-this-week.mm", "w") { |f| f.write( delta_map ) }
File.open("#{directory}/completed-this-week.mm", "w") { |f| f.write( done_delta_map ) }
File.open("#{directory}/new-projects-this-week.mm", "w") { |f| f.write( new_delta_map ) }
File.open("#{directory}/meta.mm", "w") { |f| f.write( meta_map ) }


Focus::CloudFactory.create_cloud focus, directory




