namespace :matches do
  desc "generate matches"
  task :generate_new => :environment do
    # TBD: what about mutual -- both should see same match?
    # TBD: this should be based on the user's timezone
    Profile.active.ready_for_matches.find_each(batch_size: 10) do |profile|
      Matchmaker.delay.generate_new_matches_for(profile.uuid)
    end
  end

  desc "create match records"
  task :create => :environment do
    Profile.with_has_new_queued_matches(true).find_each(batch_size: 10) do |profile|
      match_uuids = profile.queued_matches
      Matchmaker.delay.create_matches_between(profile.uuid, match_uuids) if match_uuids.present?
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
