source 'http://rubygems.org'

gem 'rails', '3.2.11'
gem "rake"
gem 'haml'

gem 'psych'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

#gem 'sqlite3-ruby', :require => 'sqlite3'

# Use unicorn as the web server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

# Bundle the extra gems:
# gem 'bj'
# gem 'nokogiri'
# gem 'sqlite3-ruby', :require => 'sqlite3'
# gem 'aws-s3', :require => 'aws/s3'

gem 'nokogiri'
gem 'minitar'
gem 'mechanize'
#gem 'zip'
gem 'rubyzip'

gem "cloud", :git => "git://github.com/kippr/cloud.git"
#gem 'ninajansen-cloud'
gem 'pdf-writer', :git => "git://github.com/metaskills/pdf-writer.git"
#gem 'pdf-writer'
gem 'RubyInline'
gem "ZenTest", "4.6.0"

gem 'hpricot', '0.8.3'
gem 'hoe', '2.8.0'

# Bundle gems for the local environment. Make sure to
# put test-only gems in this group so their generators
# and rake tasks are available in development mode:
group :development, :test do
#   gem 'webrat'
	gem 'sqlite3-ruby', :require => 'sqlite3'
	
	gem 'rspec-rails'
	gem 'timecop'

  # To use debugger
  gem 'ruby-debug19'

  gem 'simplecov'

  gem 'pry'
  gem 'terminal-notifier'  # for focus-repl
  gem 'awesome_print'
end

group :production do
	gem 'pg'
end
