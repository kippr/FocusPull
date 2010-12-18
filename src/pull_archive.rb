require 'rubygems'
require 'mechanize'
require 'highline/import'


  #a.pluggable_parser.default = WWW::Mechanize::FileSaver

  username = 'kippr'
  password = ask("Pw?: ") { |q| q.echo = false }


  def downloadOmniSync( username, password )
    agent = WWW::Mechanize.new
      agent.user_agent_alias = 'Mac Safari'
      agent.get('https://www.omnigroup.com/sync/') do |page|
      login_result = page.form_with(:action => '/sync/signin') do |login|
        login.username = username
        login.password = password
      end.submit

      login_result.link_with(:href => '/sync/manage/download') do |archive|
        (puts "Something went wrong retrieving archive"; next) if archive.nil?
        archive_file = archive.click()
        return archive_file
      end
    end
  end

  archive_file = downloadOmniSync( username, password )
  dir = "./archives/#{Time.now.strftime("%Y.%m.%d_%H%M")}"
  FileUtils.mkpath dir
  filename = "#{dir}/omnisync.tar"
  archive_file.save(filename)
  puts "Saved #{filename} ok"


