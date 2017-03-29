namespace :introductions do
  task :generate => :environment do
    Profile.active.not_staff.visible.desirability_score_gte(Profile::HIGH_DESIRABILITY).within_distance(18.98, 72.83).each do |profile|
      puts "-- for #{profile.firstname}, #{profile.gender}, #{profile.age} --"

      introduce_to_profiles = Matchmaker.introduction_suggestions_for(profile)
      introduce_to_profiles.each do |p|
        puts "      : #{p.firstname}, #{p.age}, #{p.gender}"
      end

      if introduce_to_profiles.present?
        message = "Hey #{profile.firstname}! We've launched ekCoffee Introductions beginning today! Tap here to get introduced to interesting singles and grow your connections!"
        PushNotifier.delay.send_transactional_push([profile.uuid], 'general_announcement', body: message)
      end

      $redis.set("generated_intros_ts:#{profile.uuid}", Time.now.utc.to_i)
      $redis.set("generated_intro_profiles:#{profile.uuid}", introduce_to_profiles.map(&:uuid).to_json)
    end

  end
end
