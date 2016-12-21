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

  def new_brew_invite_signup(invite_to)
    sendgrid_header_params =
                      {
                        filters: {
                          templates: {
                            settings: { enable: 1,
                                        template_id: "51938a18-15c8-46a1-b19d-2a1dc0a7927d"
                            }
                          }
                        },
                        sub: {
                        }
                      }
    headers['X-SMTPAPI'] = sendgrid_header_params.to_json

    mail(
      to: 'hello@ekcoffee.com',
      subject: "Brew Invitation Signup",
      body: "New Invite - #{invite_to}"
    )
  end
end
