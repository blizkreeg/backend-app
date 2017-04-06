namespace :introductions do

  task :schedule_reminder => :environment do
    Profile.members.not_staff.each do |profile|
      message = [
                  "We have new introductions for you, #{profile.firstname}!",
                  "Have you checked out today's introductions, #{profile.firstname}?"
                ].sample

      puts "#{profile.uuid}, #{profile.age}, #{profile.gender}, #{profile.firstname}"

      # if the user has no current intros
      if !profile.has_current_intros?
        # but they have upcoming intros
        if profile.has_more_intros?
          puts "HAS new intros"

          # schedule the notification now
          schedule_notification(profile, Time.now.utc, message)
        else
          puts "NO new intros"
        end
      elsif profile.has_more_intros? # user has current intros and has upcoming ones
        puts "HAS more intros, scheduling reminder at #{Time.at(profile.intros_expire_at)}"

        # schedule the notification when the current set expires
        schedule_notification(profile, Time.at(profile.intros_expire_at), message)
      end

      puts "--"
    end
  end

  def schedule_notification(profile, time, message)
    # don't send notification if we've sent one in the past 24 hours
    if profile.needs_reminder?
      if time > Time.now.utc
        # schedule later
        PushNotifier.delay_until(time).send_transactional_push([profile.uuid], 'general_announcement', body: message)
      else
        # schedule now
        PushNotifier.delay.send_transactional_push([profile.uuid], 'general_announcement', body: message)
      end

      # track notifications send time
      profile.sent_reminder_at = time
    end
  end

end
