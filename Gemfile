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
gem 'default_value_for', '~> 3.0.0' # TBD: check if we can use this
gem 'coffee-rails', '~> 4.1.0'
gem 'email_validator'
gem 'oj'
gem 'oj_mimic_json'
gem 'koala', '~> 2.2'
gem 'json-schema'
gem 'responders'
gem 'geocoder'
gem 'redis'
gem 'sidekiq'
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
gem 'jsonb_accessor'
gem 'jquery-rails'
# TBD: add https://github.com/schneems/puma_worker_killer

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
