json.state profile.state
json.state_endpoint (profile.state_endpoint.present? ? ENV['HOST_URL'] + profile.state_endpoint : nil)
json.substate profile.substate
json.substate_endpoint (profile.substate_endpoint.present? ? ENV['HOST_URL'] + profile.substate_endpoint : nil)
json.force_profile_update profile.force_device_update
