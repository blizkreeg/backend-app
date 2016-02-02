require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# load .env file environment variables for development
# Dotenv::Railtie.load

module BackendApp
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'UTC'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Do not swallow errors in after_commit/after_rollback callbacks.
    config.active_record.raise_in_transactional_callbacks = true

    config.autoload_paths << Rails.root.join('lib')

    # TODO: before going to production, check why this isn't working (SSL error) and use Google if possible
    # TODO: set IPs of production servers for the key at https://console.developers.google.com/apis/credentials/key/0?project=nifty-catfish-119105
    # Timezone::Configure.begin do |c|
    #   c.google_timezone_api_key = ENV['GOOGLE_TIMEZONE_API_KEY']
    #   # c.google_client_id = 'your_google_client_id' # only if using 'Google for Work'
    # end

    Timezone::Configure.begin do |c|
      c.username = ENV['GEONAMES_USERNAME']
    end

    config.middleware.insert_before ActionDispatch::ParamsParser, "RescueJsonParseError"
  end
end
