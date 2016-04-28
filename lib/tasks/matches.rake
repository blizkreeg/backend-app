namespace :matches do
  desc "generate matches"
  task :generate_new => :environment do
    puts "\n#{DateTime.now} ******** Finding new matches **********\n"

    Profile.active.find_each(batch_size: 10) do |profile|
      # NOTE: you cannot make this asynchronous or we could run into a condition where two matches between the same people are being created
      # TODO: room for optimization
      n = Matchmaker.generate_new_matches_for(profile.uuid)
      puts "#{profile.uuid}: #{n} new matches" if n > 0
    end
  end

  desc "update state for profiles that have matches"
  task :ready_for_new => :environment do
    puts "\n#{DateTime.now} ******** Checking for who's ready to get new matches **********\n"

    Profile.active.ready_for_matches.find_each(batch_size: 10) do |profile|
      next unless profile.past_matches_time?

      if profile.has_new_matches?
        case profile.state
        when 'waiting_for_matches'
          profile.new_matches!(:has_matches)
        when 'waiting_for_matches_and_response'
          profile.new_matches!(:has_matches_and_waiting_for_response)
        end

        PushNotifier.delay.record_event(profile.uuid, 'new_matches')
        puts "#{profile.uuid}: #{[profile.matches.undecided.count, Constants::N_MATCHES_AT_A_TIME].min} available matches"
      else
        puts "#{profile.uuid}: no matches"
      end
    end
  end

  desc "run mutual matches"
  puts "\n#{DateTime.now} ******** Finding mutual matches **********\n"

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
