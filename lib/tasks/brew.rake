namespace :brew do
  task :reminder_to_confirm_24h_prior => :environment do
    brews = Brew
            .live
            .happening_on_after(Time.now.utc.to_date - 1.day)
            .happening_on_before(Time.now.utc.to_date + 1.day)

    brews.each do |brew|
      tdiff = brew.happening_at.to_i - brew.host_time_now.to_i
      seconds_min = 86_400 - 1.hour.seconds.to_i
      seconds_max = 86_400 - 1

      if (tdiff >= seconds_min) && (tdiff <= seconds_max)
        if brew.brewings.interested.count > 0
          uuids = brew.brewings.interested.map(&:profile).map(&:uuid)
          PushNotifier.delay.send_transactional_push(uuids,
                                               'brew',
                                               body: "🕒 '#{brew.title}' is happening in a day! Confirm to reserve your spot 🙋")
        end
      end
    end
  end

  task :expire_past_ones => :environment do
    Brew.live.each do |brew|
      host_time_now = Time.now.in_time_zone(brew.host_tz)
      brew.expire! if brew.happening_at.to_i < brew.host_time_now.to_i
    end
  end
end
