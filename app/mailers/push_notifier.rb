# TBD: log all sent push notifications somewhere!
class PushNotifier
  attr_accessor :title, :body

  TYPES = %w(new_matches
              new_mutual_match
              new_conversation_message
              conv_health_check
              conv_ready_to_meet
              conv_date_suggestions
              conv_are_you_meeting
              conv_close_notice
              new_butler_message
              profile_photo_rejected
              profile_edit_rejected)

  DETAILS = {
    'new_matches' => {
      title: "ekCoffee",
      body: "Meet your new matches",
      required_parameters: [],
    },
    'new_mutual_match' => {
      title: "ekCoffee",
      body: "@name is curious about you too!",
      required_parameters: ['name'],
    },
    'new_conversation_message' => {
      title: "ekCoffee",
      body: "@name has sent you a message!",
      required_parameters: ['name'],
    },
    'conv_health_check' => {
      title: "ekCoffee",
      body: "How is your conversation with @name going?",
      required_parameters: ['name'],
    },
    'conv_ready_to_meet' => {
      title: "ekCoffee",
      body: "Are you ready to meet @name yet?",
      required_parameters: ['name'],
    },
    'conv_date_suggestions' => {
      title: "ekCoffee",
      body: "You and @name are ready to meet! Here are a few suggestions for a first date.",
      required_parameters: ['name']
    },
    'conv_are_you_meeting' => {
      title: "ekCoffee",
      body: "Are you and @name meeting?",
      required_parameters: ['name'],
    },
    'conv_close_notice' => {
      title: "ekCoffee",
      body: "Your conversation with @name will close soon.",
      required_parameters: ['name'],
    },
    'new_butler_message' => {
      title: "ekCoffee",
      body: "@myname, you have a message from the ekCoffee Butler!",
      required_parameters: ['myname'],
      category: 'BUTLER_CHAT'
    },
    'profile_photo_rejected' => {
      title: "ekCoffee",
      body: "@myname, there was a problem with your photo.",
      required_parameters: ['myname'],
      category: 'EDIT_PHOTOS'
    },
    'profile_edit_rejected' => {
      title: "ekCoffee",
      body: "@myname, there was a problem with your profile edit.",
      required_parameters: ['myname'],
      category: 'EDIT_PROFILE'
    }
  }

  def self.notify_one(uuid, notification_type, notification_params = {})
    notification_params = notification_params.with_indifferent_access

    required_params = DETAILS[notification_type.to_s][:required_parameters]
    if required_params.present?
      given_params = notification_params.keys.map(&:to_s) & required_params
      raise Errors::InvalidPushNotificationPayload, "missing params #{given_params.join(', ')}" if given_params.size != required_params.size
    end

    notification_default_params = DETAILS[notification_type.to_s]

    payload_body = {
      name: "Transactional",
      estimate_only: false,
      where: {
        common_profile_prop: {
          profile_fields: [
            { name: "uuid", value: uuid }
          ]
        }
      },
      content: {
        title: notification_params[:title] || notification_default_params[:title],
        body: generated_body(notification_type, notification_params) || notification_default_params[:body],
        platform_specific: {
          ios: {
            category: notification_default_params[:category],
            badge_count: 1
          },
          android: {
            category: notification_default_params[:category]
          }
        }
      },
      devices: [
        "android",
        "ios"
      ],
      when: "now"
    }

    EKC.logger.debug "DEBUG: Sending push notification to #{uuid}, payload: #{payload_body.to_json}"

    Clevertap.post_json('/1/targets/create.json', payload_body.to_json)

    if response.status != 200
      EKC.logger.error "ERROR: Failed to send push notification! uuid: #{uuid}, type: #{notification_type}, params: #{notification_params}, error message: #{response.body}"
    else
      EKC.logger.info "INFO: Sent push notification '#{notification_type}' to #{uuid}, response: #{response.body}"
    end
  rescue StandardError => e
    EKC.logger.error "ERROR: exception on sending push notification! exception: #{e.class.name}, message: #{e.message}"
  end

  def self.notify_multi(uuids, notification_types = [], notification_params = [])
    uuids.each_with_index do |uuid, idx|
      notify_one(uuid, notification_types[idx], notification_params[idx])
    end
  end

  def self.generated_body(notification_type, notification_params)
    body_message = DETAILS[notification_type.to_s][:body]
    dynamic_body_props = body_message.scan(/\@([\w]+)/i).flatten
    dynamic_body_props.each do |prop_name|
      body_message.gsub!("@#{prop_name}", notification_params[prop_name.to_sym])
    end
    body_message
  end
end
