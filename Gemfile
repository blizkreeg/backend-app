source 'https://rubygems.org'

gem 'rails', '~> 4.2.5'
gem 'pg'
gem 'jbuilder', '~> 2.0'
gem 'puma'
gem 'omniauth-facebook'
gem 'jwt'
gem 'timezone'
gem 'sass-rails', '~> 5.0'
gem 'uglifier', '>= 1.3.0'
gem 'coffee-rails', '~> 4.1.0'
gem 'oj'
gem 'oj_mimic_json'
gem 'koala', '~> 2.2'
gem 'json-schema'
gem 'responders'
gem 'geocoder'
gem 'redis'
gem 'redis-rails'
gem 'sidekiq', require: ['sidekiq', 'sidekiq/web']
gem 'cloudinary'
gem 'aasm'
gem 'firebase'
gem 'firebase_token_generator'
# TBD: move to standalone or protected on production
# if you require 'sinatra' you get the DSL extended to Object
gem 'sinatra', :require => nil
gem 'httparty'
gem 'nokogiri'
gem 'slim-rails'
gem 'faraday'
gem 'jsonb_accessor', '~> 0.3.3'
gem 'jquery-rails'
gem 'sidekiq_parameters_logging'
# TBD: add https://github.com/schneems/puma_worker_killer
# gem 'librato-rails'
# gem 'stackify-api-ruby'
gem 'exception_notification'
gem 'lograge'
gem 'newrelic_rpm'
gem 'redcarpet'
gem 'google_drive'
gem 'highcharts-rails'
gem 'roadie-rails', '~> 1.0'
gem 'whenever', require: false
gem 'rollbar'

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

group :development, :test do
  gem 'byebug'
  gem 'faker'
  gem 'forgery'
  gem 'rspec-rails'
  gem 'capybara'
  gem 'dotenv-rails'
end

group :development do
  gem 'quiet_assets'
  gem 'web-console', '~> 2.0'
  # gem 'spring'
  gem 'derailed'
  gem 'ruby-prof'
  gem 'capistrano', '~> 3.1'
  gem 'capistrano-bundler', '~> 1.1.2'
  gem 'capistrano-rails', '~> 1.1'
  gem 'capistrano3-puma', require: false
  gem 'capistrano-rbenv', '~> 2.0', require: false
  gem 'capistrano-rbenv-vars', '~> 0.1', require: false
  gem 'capistrano-sidekiq'
end
