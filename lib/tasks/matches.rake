namespace :matches do
  desc "generate matches"
  task :generate_new => :environment do
    Profile.active.ready_for_matches.find_each(batch_size: 10) do |profile|
      Matchmaker.delay.generate_new_matches_for(profile.uuid)
    end
  end

  desc "update state for profiles that have matches"
  task :ready_for_new => :environment do
    # TBD: this should be based on the user's timezone
    Profile.active.ready_for_matches.find_each(batch_size: 10) do |profile|
      if profile.has_new_matches?
        case profile.state
        when 'waiting_for_matches'
          profile.new_matches!(:has_matches)
        when 'waiting_for_matches_and_response'
          profile.new_matches!(:has_matches_and_waiting_for_response)
        end

        PushNotifier.delay.record_event(profile.uuid, 'new_matches')
        puts "#{profile.uuid}: #{[profile.matches.undecided.count, Constants::N_MATCHES_AT_A_TIME].min} matches"
      else
        puts "#{profile.uuid}: no matches"
      end
    end
  end

  desc "run mutual matches"
  task :find_mutual => :environment do
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
