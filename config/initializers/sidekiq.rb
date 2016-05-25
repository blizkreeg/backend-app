Sidekiq.configure_server do |config|
  config.redis = { url: "redis://#{ENV['REDIS_HOST']}:6379/#{Rails.application.config.redis_db_sidekiq}" }
end

Sidekiq.configure_client do |config|
  config.redis = { url: "redis://#{ENV['REDIS_HOST']}:6379/#{Rails.application.config.redis_db_sidekiq}" }
end

Sidekiq::Web.use(Rack::Auth::Basic) do |user, password|
  [user, password] == [ENV["SIDEKIQ_USERNAME"], ENV["SIDEKIQ_PASSWORD"]]
end if Rails.env.production?
