require 'rubygems'
require 'mechanize'
require 'logger'

  @log = Logger.new(STDOUT)
  
  def download_archive( username, password )
    agent = Mechanize.new
    agent.user_agent_alias = 'Mac Safari'
      
    agent.get('https://www.omnigroup.com/sync/') do |page|
      login_result = page.form_with(:action => '/sync/signin') do |login|
        @log.debug("Trying to login #{username}")
        login.username = username
        login.password = password
      end.submit

      login_result.link_with(:href => '/sync/manage/download') do |archive|
        @log.debug("Trying to download archive")
        raise "Something went wrong retrieving archive, maybe invalid username/ password?" if archive.nil?
        archive_file = archive.click()
        return archive_file
      end
    end
  end


