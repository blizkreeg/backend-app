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

  task :butler => :environment do
    Profile.with_gender('female').age_gte(23).age_lte(28).within_distance(18.98, 72.83, 50000).each do |p|
      next if p.uuid == 'c4382cc3-887f-4cef-b2f9-74159672a963'
      Profile.delay_for(90.minutes).send_butler_messages(p.uuid, ["Hey #{p.firstname}! This is Anu, Co-Founder of ekCoffee.", "We're hosting a singles brunch at the Tea Villa cafe in Bandra this Sunday the 18th and we have an interesting group of people joining us!", "The group consists of an established entrepreneur, a marketing head, an investment banker and a management trainee.", "I was going through the profiles of some interesting women on ekCoffee, and stumbled across yours.", "I thought you’d be a nice fit in the group and would love to meet other interesting singles from Bombay over engaging conversations.", "For sometimes group activities are way relaxed than dates :) - Anu.", "If you are interested, you can see details of it on your home screen (click on See My Brews)."])

      Profile.delay_for(91.minutes).send_butler_messages(p.uuid, ["You'll have to go through your current matches to see it."]) if (p.state == 'has_matches' || p.state == 'show_matches')

      PushNotifier.delay_for(92.minutes).record_event(p.uuid, 'new_butler_message', myname: p.firstname)

      puts "queued for #{p.uuid} #{p.firstname}"

      sleep 2
    end
  end
end
