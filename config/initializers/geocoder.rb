Geocoder.configure(

  # geocoding service (see below for supported options):
  # TBD: uncomment before going live
  # :lookup => :google,

  # IP address geocoding service (see below for supported options):
  :ip_lookup => :maxmind,

  # to use an API key:
  # :api_key => "...",

  # geocoding service request timeout, in seconds (default 3):
  :timeout => 5,

  # set default units to kilometers:
  :units => :km,

  # caching (see below for details):
  :cache => Redis.new(:host => ENV['REDIS_HOST'], :db => Rails.application.config.redis_db_geocoder),
  :cache_prefix => "geocoder",

  # TBD: before going live, need to set up SSL cert and turn this on to use key
  # google: {
    # api_key: ENV['GOOGLE_GEOCODING_API_KEY'],
    # use_https: true,
  # }
)
