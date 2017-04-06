namespace :events do
  task :import => :environment do
    session = GoogleDrive.saved_session("#{Rails.root}/config/gdrive.json")
    worksheet_num =
    case Rails.env
    when 'production'
      0
    when 'test'
      1
    when 'development'
      2
    else
      2
    end
    ws = session.spreadsheet_by_key("1JYr0UwPFgck9QbXV5LQr5I_JD2qHodnxGR1AWLL32aA").worksheets[worksheet_num]

    # doc version stored at [1,2]
    version = ws[1,2]
    if !Rails.env.production? || (version != Rails.cache.read("stb_events_version"))
      Rails.cache.write("stb_events_version", version, expires_in: 30.days)
      (1..ws.num_rows).to_a.each do |row|
        next unless row >= 3
        event_id = ws[row, 9]
        if event_id.blank?
          new_event = true
          event = Event.new
        else
          event = Event.find(event_id.to_i) rescue nil
          new_event = event.present? ? false : true
          event = Event.new if new_event
        end

        event.happening_on = Date.parse(ws[row, 1])
        event.happening_at = ws[row, 2]
        event.place = ws[row, 3]
        event.address = ws[row, 4]
        event.total_spots = ws[row, 5]
        event.male_spots = ws[row, 6]
        event.female_spots = ws[row, 7]
        event.photo = ws[row, 8]
        event.payment_link = ws[row, 10]
        event.description = ws[row, 11]
        event.name = ws[row, 12]
        event.min_age = ws[row, 13]
        event.max_age = ws[row, 14]

        event.save!

        if new_event
          puts "Added new event #{event.inspect}"
          ws[row, 9] = event.id
          ws.save
        end
      end
    end
  end

  task :send_mailer => :environment do
    @profiles = Profile.members.not_staff
    @profiles.each do |profile|
      skip_emails = %w(
        rahul.dsouza@gmail.com
        ameet.gaitonde@bba02.mccombs.utexas.edu
        alaokika@yahoo.com
        punitgor@yahoo.com
        sajili.shirodkar@gmail.com
        shailesh24@gmail.com
        mohitis@gmail.com
        pawanrai91@gmail.com
        mrinali89@gmail.com
        devasis1985@gmail.com
        guhaaditi@gmail.com
        smritijaiswal123@gmail.com
        rahul.si@gmail.com
        saurabh.t85@rediffmail.com
        anupam.kgp@gmail.com
        nagesh.raii@gmail.com
        nikhiljain_99@yahoo.com
        bhulbhaal@gmail.com
        chantelle.dq@gmail.com
        anant.jhawar@gmail.com
        prateek.mota@gmail.com
        supreet.kunte@gmail.com
        sweetlilbee@hotmail.com
        sinhaar.rodrigues@gmail.com
        rehanrox@hotmail.com
      )
      next if profile.email.blank?
      next if profile.firstname.blank?
      next if skip_emails.include?(profile.email)
      # PushNotifier.delay.record_event(profile.uuid, 'general_announcement', body: "#{profile.firstname}, we are excited to announce our fourth Singles That Brunch in Mumbai! This time, it's at The Bombay Canteen. RSVP in the app and join us :-)")
      UserMailer.send_email("2a791920-b620-4678-8f87-d5c8a3f85924", profile.email, nil, { "-fname-" => [profile.firstname]}).deliver_later
      puts "emailed #{profile.firstname}"
    end
  end
end
