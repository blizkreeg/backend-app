namespace :engagement do
  task :day7_comeback => :environment do
    not_active = Profile.visible.last_seen_at_before(DateTime.now-7.days).select { |p| p.matches.undecided.count > 0 }
    not_active.each do |p|
      msg = "#{p.firstname}, where are you hiding? We have #{p.matches.undecided.count} new matches for you!"
      PushNotifier.delay.record_event(p.uuid, 'general_announcement', body: msg)
    end
    puts "sent notifications to #{not_active.count} users"
  end
end
