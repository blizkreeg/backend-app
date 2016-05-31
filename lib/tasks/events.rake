namespace :events do
  task :import => :environment do
    session = GoogleDrive.saved_session("#{Rails.root}/config/gdrive.json")
    ws = session.spreadsheet_by_key("1JYr0UwPFgck9QbXV5LQr5I_JD2qHodnxGR1AWLL32aA").worksheets[0]

    # doc version stored at [1,2]
    version = ws[1,2]
    if !Rails.env.production? || (version.to_i != Rails.cache.read("stb_events_version").to_i)
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

        event.save!

        if new_event
          puts "Added new event #{event.inspect}"
          ws[row, 9] = event.id
          ws.save
        end
      end
    end
  end
end
