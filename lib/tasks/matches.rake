namespace :matches do
  desc "generate matches"
  task :generate_new => :environment do
    puts "#{EKC.now_in_pacific_time} FINDING NEW MATCHES"

    Profile.active.find_each(batch_size: 10) do |profile|
      # NOTE: you cannot make this asynchronous or we could run into a condition where two matches between the same people are being created
      # TODO: room for optimization
      n = Matchmaker.generate_new_matches_for(profile.uuid)
      puts "#{profile.uuid}: #{n} new matches" if n > 0
    end
  end

  desc "update state for profiles that have matches"
  task :ready_for_new => :environment do
    puts "#{EKC.now_in_pacific_time} SENDING NEW MATCHES NOTIFICATION"

    Profile.active.ready_for_matches.find_each(batch_size: 10) do |profile|
      if profile.has_new_matches?
        puts "#{profile.uuid}: #{[profile.matches.undecided.count, Constants::N_MATCHES_AT_A_TIME].min} new matches"

        case profile.state
        when 'waiting_for_matches'
          profile.new_matches!(:has_matches)
        when 'waiting_for_matches_and_response'
          profile.new_matches!(:has_matches_and_waiting_for_response)
        end

        profile.reload

        # check state and if it's time to notify them
        if profile.in_waiting_state? && profile.due_for_new_matches_notification?
          if profile.ok_to_send_new_matches_notification?
            PushNotifier.delay.record_event(profile.uuid, 'new_matches')
            profile.update!(sent_matches_notification_at: DateTime.now)
            puts "#{profile.uuid}: sent notification"
          else
            puts "#{profile.uuid}: last notification less than a day ago, skipping."
          end
        end

      else
        puts "#{profile.uuid}: no matches"
      end
    end
  end

  desc "run mutual matches"
  task :find_mutual => :environment do
    puts "#{EKC.now_in_pacific_time} FINDING MUTUAL MATCHES"
    Profile.active.with_gender('male').where("profiles.state != 'mutual_match' AND profiles.state != 'in_conversation' AND profiles.state != 'waiting_for_matches_and_response'").find_each(batch_size: 10) do |profile|
      profile.matches.mutual.order("matches.created_at ASC").each do |match|
        matched_profile = match.matched_profile
        next if matched_profile.state == 'mutual_match' || matched_profile.state == 'in_conversation'
        next if matched_profile.active_mutual_match.present?

        Matchmaker.transition_to_mutual_match(profile.uuid, match.id)
        puts "found mutual match for #{profile.uuid}, changing state to 'mutual_match'"

        break
      end
    end
  end
end
