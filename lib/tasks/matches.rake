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
    Profile.with_has_new_matches(true).find_each(batch_size: 10) do |profile|
      match_uuids = $redis.zrange("new_matches/#{profile.uuid}", 0, 4)
      Matchmaker.delay.create_matches(profile.uuid, match_uuids) if match_uuids.present?
    end
  end
end
