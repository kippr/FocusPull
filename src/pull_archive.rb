require 'rubygems'
require 'mechanize'

  a = WWW::Mechanize.new { |agent|
    agent.user_agent_alias = 'Mac Safari'
  }

  #a.pluggable_parser.default = WWW::Mechanize::FileSaver


  a.get('https://www.omnigroup.com/sync/') do |page|
    login_result = page.form_with(:action => '/sync/signin') do |login|
      login.username = 'kippr'
      login.password = '123'
    end.submit

    login_result.link_with(:href => '/sync/manage/download') do |archive|
      (puts "Something went wrong retrieving archive"; next) if archive.nil?
      archive_file = archive.click()
      archive_file.save("./data/omnisync.tar")
    end

  end

