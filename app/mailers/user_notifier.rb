class UserNotifier
  SALUTATION = "Hi %{firstname}"

  WELCOME_MESSAGES = [
    "This is #{Constants::COFOUNDERS.sample}, Co-founder of ekCoffee. Thanks for joining! :)",
    "Reach out to us here at any time if you have questions or concerns.",
    "By the way, how did you hear about us?"
  ]

  def self.send_welcome_messages_via_butler(uuid)
    p = Profile.find(uuid)

    return if p.blacklisted?

    messages = [SALUTATION % {firstname: p.firstname}] + WELCOME_MESSAGES
    Profile.delay.send_butler_messages(p.uuid, messages)
    PushNotifier.delay_for(1.minute).record_event(p.uuid, 'new_butler_message', myname: p.firstname)

  rescue ActiveRecord::RecordNotFound
    EKC.logger.error "Newly created profile not found #{p.uuid} -- can't send welcome messages"
  rescue StandardError => e
    EKC.logger.error "Error while sending welcome messages, profile uuid: #{p.uuid}, exception: #{e.class.name}"
  end
end
