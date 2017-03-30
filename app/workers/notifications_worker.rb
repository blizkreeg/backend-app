class NotificationsWorker
  ADMIN_EMAILS = %w(vineet@ekcoffee.com anu@ekcoffee.com)
  ADMIN_PHONE_NUMBERS = [
    '+918291407276',
    '+14157068051'
  ]

  def self.notify_admins_of_new_brew(brew_id)
    ADMIN_EMAILS.each do |email|
      NotificationsMailer.new_brew_notification(Brew.find(brew_id), email).deliver_now
    end
  end

  def self.notify_hosts_of_brew_approval(brew_id)
    brew = Brew.find(brew_id)
    host_uuids = brew.brewings.hosts.map(&:profile).map(&:uuid)
    message = "Your Brew '#{brew.title}' has been reviewed and is now live! 💃"

    PushNotifier.send_transactional_push(host_uuids, 'brew', body: message)
  end

  def self.notify_hosts_of_new_rsvp(brew_id, profile_uuid)
    brew = Brew.find(brew_id)
    profile = Profile.find(profile_uuid)
    host_uuids = brew.brewings.hosts.map(&:profile).map(&:uuid)
    message = "#{profile.firstname} is interested in your Brew '#{brew.title}'! 🙌"

    PushNotifier.send_transactional_push(host_uuids, 'brew', body: message)
  end
end
