# config/initializers/mailer.rb
if Rails.env.production?
  ActionMailer::Base.delivery_method = :smtp
  ActionMailer::Base.smtp_settings = {
    :address => "smtp.sendgrid.net",
    :port => 587,
    :domain => "ekcoffee.com",
    :user_name => ENV['SENDGRID_USER'],
    :password => ENV['SENDGRID_PASSWORD'],
    :authentication => :plain,
    :enable_starttls_auto => true
  }
end
