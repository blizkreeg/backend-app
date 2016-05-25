# TBD: log all sent push notifications somewhere!
class PushNotifier
  attr_accessor :title, :body

  MAX_ATTEMPTS = 3

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
      body: ["Meet your new matches.", "Who among these matches will you meet?", "We have new matches for you."].sample,
      required_parameters: [],
      event_name: 'Has New Matches',
      has_push_notification: true
    },
    'new_mutual_match' => {
      title: "ekCoffee",
      body: "@name is interested in you!",
      required_parameters: ['name'],
      event_name: 'Got Mutual Match',
      has_push_notification: true
    },
    'new_conversation_message' => {
      title: "ekCoffee",
      body: "@name has sent you a message!",
      required_parameters: ['name'],
      event_name: 'Has New Message',
      event_details: { sender_type: 'User' },
      has_push_notification: true
    },
    'conv_open' => {
      required_parameters: [],
      event_name: 'Conversation State Change',
      event_details: { state: 'Open' },
      has_push_notification: false
    },
    'conv_health_check' => {
      title: "ekCoffee",
      body: ["Is your conversation with @name going well?", "How's your conversation with @name going?", "Good conversation with @name?", "Hope you're talking about something fun with @name!"].sample,
      required_parameters: ['name'],
      event_name: 'Conversation State Change',
      event_details: { state: 'Health Check' },
      has_push_notification: true
    },
    'conv_ready_to_meet' => {
      title: "ekCoffee",
      body: "Are you ready to meet @name yet? :)",
      required_parameters: ['name'],
      event_name: 'Conversation State Change',
      event_details: { state: 'Check If Ready To Meet' },
      has_push_notification: true
    },
    'conv_date_suggestions' => {
      title: "ekCoffee",
      body: "Great news! You and @name are ready to meet. Here are a few first date suggestions.",
      required_parameters: ['name'],
      event_name: 'Conversation State Change',
      event_details: { state: 'Show Date Suggestions' },
      has_push_notification: true
    },
    'conv_are_you_meeting' => {
      title: "ekCoffee",
      body: "Did you and @name decide to meet?",
      required_parameters: ['name'],
      event_name: 'Conversation State Change',
      event_details: { state: 'Check If Meeting' },
      has_push_notification: true
    },
    'conv_close_notice' => {
      title: "ekCoffee",
      body: "Your conversation with @name will close soon.",
      required_parameters: ['name'],
      event_name: 'Conversation State Change',
      event_details: { state: 'Close Notice' },
      has_push_notification: true
    },
    'new_butler_message' => {
      title: "ekCoffee",
      body: "@myname, you have a message from the ekCoffee Butler!",
      required_parameters: ['myname'],
      category: 'BUTLER_CHAT',
      event_name: 'Has New Message',
      event_details: { sender_type: 'Butler' },
      has_push_notification: true
    },
    'profile_photo_rejected' => {
      title: "ekCoffee",
      body: "@myname, there was a problem with your photo.",
      required_parameters: ['myname'],
      category: 'EDIT_PHOTOS',
      event_name: 'Profile Issue',
      event_details: { issue_type: 'Bad Photo' },
      has_push_notification: true
    },
    'profile_edit_rejected' => {
      title: "ekCoffee",
      body: "@myname, there was a problem with your profile edit.",
      required_parameters: ['myname'],
      category: 'EDIT_PROFILE',
      event_name: 'Profile Issue',
      event_details: { issue_type: 'Bad Update' },
      has_push_notification: true
    }
  }

  # This function will record a user action/event in Clevertap
  # It will also send a push notification if the event should trigger one (disable sending the push with do_not_send_push: true)
  def self.record_event(uuid, notification_type, params = {})
    notification_params = params.with_indifferent_access.clone

    required_params = DETAILS[notification_type.to_s][:required_parameters].clone
    if required_params.present?
      given_params = notification_params.keys.map(&:to_s) & required_params
      raise Errors::InvalidPushNotificationPayload, "missing params #{given_params.join(', ')}" if given_params.size != required_params.size
    end

    notification_default_params = DETAILS[notification_type.to_s].clone

    title = notification_params[:title] || notification_default_params[:title]
    body = notification_params[:body] || generated_body(notification_type, notification_params) || notification_default_params[:body]
    category = notification_default_params[:category]

    event_data = {
      'message_title'.humanize => title,
      'message_body'.humanize => body,
      'category'.humanize => category
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

    EKC.logger.debug "Uploading user action '#{notification_default_params[:event_name]}' for #{uuid}, payload: #{payload_body.to_json}"

    attempt = 1
    begin
      response = Clevertap.post_json('/1/upload', payload_body.to_json)

      if response.status != 200
        EKC.logger.error "ERROR: (try #{attempt}) Failed to upload user action! uuid: #{uuid}, type: #{notification_type}, params: #{notification_params}, error message: #{response.body}"
        raise Errors::ClevertapError, "got a non-200 status from the Clevertap API. Trying once more."
      else
        EKC.logger.info "INFO: Uploaded user action '#{notification_default_params[:event_name]}' for #{uuid}, response: #{response.body}"
      end
    rescue Errors::ClevertapError => e
      attempt += 1
      if attempt <= MAX_ATTEMPTS
        sleep 0.25
        retry
      end
    rescue StandardError => e
      EKC.logger.error "ERROR: (try #{attempt}) exception occured while uploading user action! exception: #{e.class.name}, message: #{e.message}"
      attempt += MAX_ATTEMPTS
      if attempt <= MAX_ATTEMPTS
        sleep 0.25
        retry
      end
    end

    # send the push notification if this event should trigger one
    if notification_default_params[:has_push_notification] && !params[:do_not_send_push]
      send_transactional_push([uuid], notification_type, params.with_indifferent_access.clone)
    end
  end

  # Send push notifications to one or more users
  # TBD: NOTE - params is a hash here. Since we can send to multiple uuids, params should be an array of hashes.
  # This needs to be fixed where each hash elem in the params array corresponds to the respective uuid
  def self.send_transactional_push(uuids, notification_type, params = {})
    notification_params = params.with_indifferent_access.clone

    required_params = DETAILS[notification_type.to_s][:required_parameters].clone
    if required_params.present?
      given_params = notification_params.keys.map(&:to_s) & required_params
      raise Errors::InvalidPushNotificationPayload, "missing params #{given_params.join(', ')}" if given_params.size != required_params.size
    end

    notification_default_params = DETAILS[notification_type.to_s].clone

    title = notification_params[:title] || notification_default_params[:title]
    body = notification_params[:body] || generated_body(notification_type, notification_params) || notification_default_params[:body]
    category = notification_default_params[:category]

    payload_body = {
      to: {
        "Identity" => uuids,
      },
      respect_frequency_caps: true,
      content: {
        title: title,
        body: body,
        platform_specific: {
          ios: {
            category: category,
            badge_count: 1,
            sound_file: 'default'
          },
          android: {
            category: category,
            default_sound: true
          }
        }
      },
      devices: [
        "android",
        "ios"
      ]
    }

    EKC.logger.debug "Sending push notification to #{uuids}, payload: #{payload_body.to_json}"

    attempt = 1
    begin
      response = Clevertap.post_json('/1/send/push.json', payload_body.to_json)

      if response.status != 200
        EKC.logger.error "ERROR: (try #{attempt}) Failed to send push notification! #{uuids}, type: #{notification_type}, params: #{notification_params}, error message: #{response.body}"
        raise Errors::ClevertapError, "got a non-200 status from the Clevertap API. Trying once more."
      else
        EKC.logger.info "INFO: Sent push notification '#{notification_type}' to #{uuids}, response: #{response.body}"
      end
    rescue Errors::ClevertapError => e
      attempt += 1
      if attempt <= MAX_ATTEMPTS
        sleep 0.25
        retry
      end
    rescue StandardError => e
      EKC.logger.error "ERROR: (try #{attempt}) exception occured while sending push notification! exception: #{e.class.name}, message: #{e.message}"
      attempt += MAX_ATTEMPTS
      if attempt <= MAX_ATTEMPTS
        sleep 0.25
        retry
      end
    end
  end

  def self.generated_body(notification_type, notification_params)
    if DETAILS[notification_type.to_s][:body]
      body_message = DETAILS[notification_type.to_s][:body].clone
      dynamic_body_props = body_message.scan(/\@([\w]+)/i).flatten
      dynamic_body_props.each do |prop_name|
        body_message.gsub!("@#{prop_name}", notification_params[prop_name.to_sym])
      end
      body_message
    end
  end
end
