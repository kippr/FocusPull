
module Focus
  class ArchivePull
  
  @logger = Logger.new(STDOUT)
  
  def self.download_archive( username, password )
    agent = Mechanize.new
    agent.user_agent_alias = 'Mac Safari'
      
    @logger.debug("Connecting to sync server...")
    agent.get('https://www.omnigroup.com/sync/') do |page|
      login_result = page.form_with(:action => '/sync/signin') do |login|
        @logger.debug("Trying to login as '#{username}'")
        login.username = username
        login.password = password
      end.submit

      login_result.link_with(:href => '/sync/manage/download') do |archive|
        @logger.debug("Trying to download archive")
        raise "Something went wrong retrieving archive, maybe invalid username/ password?" if archive.nil?
        archive_file = archive.click()
        @logger.debug("Retrieved ok")
        return archive_file
      end
    end
  end
  end
end


