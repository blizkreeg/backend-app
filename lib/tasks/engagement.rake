namespace :engagement do
  task :day7_comeback => :environment do
    not_active_have_matches = Profile.visible.last_seen_at_before(DateTime.now-7.days).select { |p| p.matches.undecided.count > 0 }
    not_active_have_matches.each do |p|
      msg = "#{p.firstname}, you have #{p.matches.undecided.count} new matches waiting for you 😎"
      PushNotifier.delay.record_event(p.uuid, 'general_announcement', body: msg)
      if p.email.present?
        UserMailer.remind_matches(p.uuid, p.matches.undecided.take(10).map(&:matched_profile).map(&:uuid)).deliver_now
      end
      puts "sent notification of #{p.matches.undecided.count} to #{p.firstname} #{p.email}"
    end
    puts "\nsent notifications to #{not_active_have_matches.count} users"
  end

  task :day2_complete_profile => :environment do
    incomplete_profiles = Profile.visible.signed_in_at_after(DateTime.now-48.hours).signed_in_at_before(DateTime.now-24.hours).select { |p| p.incomplete }
    incomplete_profiles.each do |p|
      msg = "#{p.firstname}, because your profile is incomplete, we are unable to find you matches 😞  Can you complete it?"
      PushNotifier.delay.record_event(p.uuid, 'general_announcement', body: msg)
    end
    puts "sent notifications to #{incomplete_profiles.count} users"
  end
end
