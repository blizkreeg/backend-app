# TBD : constantize the db numbers
$redis = Redis.new(:host => ENV['REDIS_HOST'], :db => 3)
