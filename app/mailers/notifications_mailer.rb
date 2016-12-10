class NotificationsMailer < ApplicationMailer
  default from: 'ops@ekcoffee.com'

  def new_brew_notification(brew, email)
    sendgrid_header_params =
                  {
                    filters: {
                      templates: {
                        settings: { enable: 1,
                                    template_id: "1d9204fb-2086-454a-ba5a-c3dd677348eb"
                        }
                      }
                    },
                    sub: {
                    }
                  }
    headers['X-SMTPAPI'] = sendgrid_header_params.to_json

    mail(
      to: email,
      subject: "New Brew - #{brew.id}, #{brew.title}",
      body: "https://admin.ekcoffee.com/brew-dashboard"
    )
  end
end
