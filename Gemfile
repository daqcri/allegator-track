source 'https://rubygems.org'

ruby '2.1.3'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.1.1'
# Use postgresql as the database for Active Record
gem 'pg'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 4.0.3'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .js.coffee assets and views
gem 'coffee-rails', '~> 4.0.0'
# See https://github.com/sstephenson/execjs#readme for more supported runtimes
gem 'therubyracer',  platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0',          group: :doc

# Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
gem 'spring',        group: :development

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use unicorn as the app server
gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Use debugger
# gem 'debugger', group: [:development, :test]

gem 'devise'

gem 'aws-sdk'

group :development do
  gem 'foreman'
end

gem 'cancan'

gem 'delayed_job_active_record', "~> 4.0.1"
gem "daemons"

gem 'pusher'

group :production, :demo do
  # New Relic integration
  #gem 'newrelic_rpm'
  # heroku will inject this anyway, better do through Gemfile to supress plugin injection warning
  gem 'rails_12factor'
end

gem "hirefire-resource"

gem "rails-observers"

# activeadmin Rails 4 support is merged on master, but not yet on rubygems.org as of 27/11/2014
gem 'activeadmin', github: 'gregbell/active_admin'

# delayed job web monitoring 
gem "delayed_job_web", :git => 'git://github.com/hammady/delayed_job_web.git'
# heroku api for delayed job zombie detection
gem 'platform-api'

gem 'rails_client_checker', :git => 'git://github.com/hammady/rails_client_checker.git'
