class UserMailer < ApplicationMailer
  def welcome_email(profile_uuid)
    profile = Profile.find(profile_uuid)

    srand(Time.now.to_i)
    cofounder = profile.male? ? "Vineet" : "Anushri"
    cofounder_email = profile.male? ? "vineet@ekcoffee.com" : "anu@ekcoffee.com"

    sendgrid_header_params =
                      {
                        filters: {
                          subscriptiontrack: {
                            settings: {
                              enable: 0
                            }
                          },
                          templates: {
                            settings: {
                              enable: 1,
                              template_id: "783c67e7-6cb2-441e-9f43-d4c0b9f70b26"
                            }
                          }
                        },
                        sub: {
                          "-fname-" => [profile.firstname],
                          "-cofounder-" => [cofounder],
                          "-cofounder_email-" => [cofounder_email]
                        }
                      }
    headers['X-SMTPAPI'] = sendgrid_header_params.to_json

    mail(
      to: profile.email,
      subject: "Welcome to ekCoffee, #{profile.firstname} 🙌",
    )
  end

  def remind_matches(profile_uuid, match_profiles_uuids)
    @profile = Profile.find(profile_uuid) rescue nil
    return if @profile.blank?
    @match_profiles = match_profiles_uuids.map { |uuid| Profile.find(uuid) rescue nil }.compact
    return if @match_profiles.blank?

    mail(to: @profile.email, subject: "#{@profile.firstname}, you have #{@match_profiles.count} potential matches on ekCoffee.")
  end
end
