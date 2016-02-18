json.state profile.state
json.state_endpoint (profile.state_endpoint.present? ? ENV['HOST_URL'] + profile.state_endpoint : nil)
