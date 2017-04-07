module Clevertap
  module_function

  def post_json(endpoint_uri, payload_json)
    conn = Faraday.new(:url => 'https://api.clevertap.com') do |faraday|
      # faraday.response(:logger) if Rails.env.development?
      faraday.adapter(Faraday.default_adapter)
    end

    response = conn.post do |req|
      req.url endpoint_uri
      req.headers['Content-Type'] = 'application/json'
      req.headers['X-CleverTap-Account-ID'] = ENV['CLEVERTAP_ACCOUNT_ID']
      req.headers['X-CleverTap-Passcode'] = ENV['CLEVERTAP_ACCOUNT_PASSCODE']
      req.body = payload_json
    end
  end

  def get(endpoint_uri)
    conn = Faraday.new(:url => 'https://api.clevertap.com') do |faraday|
      # faraday.response(:logger) if Rails.env.development?
      faraday.adapter(Faraday.default_adapter)
    end

    response = conn.get do |req|
      req.url endpoint_uri
      req.headers['Content-Type'] = 'application/json'
      req.headers['X-CleverTap-Account-ID'] = ENV['CLEVERTAP_ACCOUNT_ID']
      req.headers['X-CleverTap-Passcode'] = ENV['CLEVERTAP_ACCOUNT_PASSCODE']
    end
  end

  # @args
  #    event name : "App Uninstalled"
  #    from date  : '20160601'
  #    to date    : '20161231'
  def profiles_by_event(name, from, to)
    payload = { event_name: name,
                from: from.to_i,
                to: to.to_i
              }.to_json
    response = Clevertap.post_json("/1/profiles.json?batch_size=500", payload)
    cursor =  JSON.parse(response.body)["cursor"]
    data = []

    while cursor.present? do
      response = Clevertap.get("/1/profiles.json?cursor=#{cursor}")
      body = JSON.parse(response.body)
      cursor = body["next_cursor"]

      next if body["records"].blank?

      data += body["records"].select { |hash| hash["profileData"].present? }
    end

    data
  end
end
