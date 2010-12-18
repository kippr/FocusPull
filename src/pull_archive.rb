require 'rubygems'
require 'mechanize'
require 'highline/import'
require 'logger'

  @log = Logger.new(STDOUT)
  
  def download_archive( username, password )
    agent = WWW::Mechanize.new
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
  
  def unpack_archive( directory, filename, username)
    @log.debug("unpacking #{directory}/#{filename} for #{username}")
    command = "tar xf #{directory}/#{filename} && mv #{username} #{directory}"
    success = system(command)
    raise "Could not untar #{filename}" unless success && $?.exitstatus == 0
    
  end

  username = 'kippr'
  password = ask("Omnisync password for #{username}? ") { |q| q.echo = false }
  
  archive = download_archive( username, password )
  
  directory = "./archives/#{Time.now.strftime("%Y.%m.%d_%H%M")}"
  FileUtils.mkpath(directory)
  filename = "omnisync.tar"
  archive.save("#{directory}/#{filename}")
  @log.info("Saved #{filename} into #{directory}")

  unpack_archive( directory, filename, username)


