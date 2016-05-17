$redis = Redis.new(:host => ENV['REDIS_HOST'], :db => Rails.application.config.redis_db_data)
