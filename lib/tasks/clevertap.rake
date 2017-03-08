namespace :clevertap do
  task :create_user_actions => :environment do
    # create dummy user
    uuid = SecureRandom.uuid
    puts "dummy UUID: #{uuid}"
    payload_body = {
      d: [
        {
          identity: uuid,
          type: 'profile',
          ts: Time.now.to_i,
          profileData: {
            uuid: uuid,
            email: "#{uuid}@ekcoffee.com",
            firstname: 'test',
            lastname: 'test',
            gender: 'M'
          }
        }
      ]
    }

    response = Clevertap.post_json('/1/upload', payload_body.to_json)

    abort("Failed to create dummy user profile. error status = #{response.status}, body = #{response.body.inspect}") if response.status != 200

    PushNotifier::DETAILS.each do |notification_type, notification_default_params|
      title = notification_default_params[:title] || 'ekc'
      body = notification_default_params[:body] || 'test'
      category = notification_default_params[:category] || 'test-category'

      event_data = {
        'message_title'.humanize => title,
        'message_body'.humanize => body,
        'category'.humanize => category,
        'badge_count'.humanize => 1
      }

      if notification_default_params[:event_details].present?
        properties_with_humanized_keys = notification_default_params[:event_details].inject({}) do |hash, (key, value)|
          hash[key.to_s.humanize] = value
          hash
        end

        event_data.merge!(properties_with_humanized_keys)
      end

      payload_body = {
        d: [
          {
            identity: uuid,
            type: 'event',
            ts: Time.now.to_i,
            evtName: notification_default_params[:event_name],
            evtData: event_data
          }
        ]
      }

      response = Clevertap.post_json('/1/upload', payload_body.to_json)

      abort("Failed to upload user action '#{notification_default_params[:event_name]}'. error status = #{response.status}, body=#{response.body.inspect} ") if response.status != 200

      puts "uploaded '#{notification_default_params[:event_name]}' event"
    end
  end

  task :download_user_profiles_by_event => :environment do
    ARGV.each { |a| task a.to_sym do ; end }

    payload = { event_name: ARGV[1], from: ARGV[2].to_i, to: ARGV[3].to_i }.to_json
    response = Clevertap.post_json("/1/profiles.json?batch_size=2000", payload)

    cursor =  JSON.parse(response.body)["cursor"]
    while cursor.present? do
      response = Clevertap.get("/1/profiles.json?cursor=#{cursor}")
      data = JSON.parse(response.body)

      if data["records"].present?
        mumbai_users =  data["records"].select { |hash| hash["profileData"].present? }.select { |hash| ['Mumbai', 'Thane', 'Navi Mumbai'].include? hash["profileData"]["location_city"] }
        mumbai_users.map {|h| { fname: h["name"], email: h["email"] } }.each { |h|
          puts h[:email]
          UserMailer.delay.send_email("4ea51c77-4583-433e-84d5-458d40833a61", h[:email], "The new ekCoffee is here, #{h[:fname]}", { "-fname-" => [h[:fname]]})
        }
      end

      cursor = data["next_cursor"]
    end
  end
end
