json.state profile.state
json.state_endpoint do
  if profile.state_endpoint.blank?
    json.null!
  else
    profile.state_endpoint
  end
end
