module Clevertap
  module_function

  def post_json(endpoint_uri, payload_json)
    conn = Faraday.new(:url => 'https://api.clevertap.com') do |faraday|
      faraday.response :logger
      faraday.adapter  Faraday.default_adapter
    end

    response = conn.post do |req|
      req.url endpoint_uri
      req.headers['Content-Type'] = 'application/json'
      req.headers['X-CleverTap-Account-ID'] = ENV['CLEVERTAP_ACCOUNT_ID']
      req.headers['X-CleverTap-Passcode'] = ENV['CLEVERTAP_ACCOUNT_PASSCODE']
      req.body = payload_json
    end
  end
end
