
module Focus
  class ArchivePull
  
  $logger = Logger.new(STDOUT)
  
  def self.download_archive username, password
    server = ArchivePull.new
    server.sign_in username, password
    server.download_archive
  end

  def initialize
    @agent = Mechanize.new
    @agent.user_agent_alias = 'Mac Safari'
  end

  def sign_in username, password
    $logger.debug("Logging in to sync server...")
    @agent.get('https://manage.sync.omnigroup.com/') do |page|
      @account_page = page.form_with(:action => '/signin') do |login|
        $logger.debug("Trying to login as '#{username}'")
        login.username = username
        login.password = password
      end.submit
    end
  end

  def download_archive
    @account_page.link_with(:href => '/manage/download') do |archive|
      $logger.debug("Trying to download archive")
      raise "Something went wrong retrieving archive, maybe invalid username/ password?" if archive.nil?
      archive_file = archive.click()
      $logger.debug("Retrieved ok")
      return archive_file
    end
  end

  end
end
