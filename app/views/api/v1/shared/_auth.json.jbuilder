json.auth do
  if current_profile.present?
    json.token JsonWebToken.encode(current_profile.auth_token_payload)
    json.expires_at Constants::TOKEN_EXPIRATION_TIME_STR
  else
    json.nil!
  end
end

json.state_data do
  json.partial! 'api/v1/profiles/state', profile: current_profile
end
