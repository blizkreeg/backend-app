# Load the Rails application.
require File.expand_path('../application', __FILE__)

# Initialize the Rails application.
Rails.application.initialize!

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
