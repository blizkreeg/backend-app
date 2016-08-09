class ApplicationMailer < ActionMailer::Base
  include Roadie::Rails::Automatic

  default from: "hello@ekcoffee.com"
  layout 'mailer'
end
