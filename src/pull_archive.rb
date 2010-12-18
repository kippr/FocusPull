require 'rubygems'
require 'mechanize'
require 'highline/import'

  def download_archive( username, password )
    agent = WWW::Mechanize.new
    agent.user_agent_alias = 'Mac Safari'
      
    agent.get('https://www.omnigroup.com/sync/') do |page|
      login_result = page.form_with(:action => '/sync/signin') do |login|
        login.username = username
        login.password = password
      end.submit

      login_result.link_with(:href => '/sync/manage/download') do |archive|
        raise "Something went wrong retrieving archive, maybe invalid username/ password?" if archive.nil?
        archive_file = archive.click()
        return archive_file
      end
    end
  end

  username = 'kippr'
  password = ask("Omnisync password for #{username}? ") { |q| q.echo = false }
  
  archive = download_archive( username, password )
  
  dir = "./archives/#{Time.now.strftime("%Y.%m.%d_%H%M")}"
  FileUtils.mkpath(dir)
  filename = "#{dir}/omnisync.tar"
  archive.save(filename)
  puts("Saved #{filename} ok")


