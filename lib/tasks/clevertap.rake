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
end
