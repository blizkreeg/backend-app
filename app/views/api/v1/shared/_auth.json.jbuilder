json.auth do
  if current_profile.present?
    json.token JsonWebToken.encode(current_profile.auth_token_payload)
    json.expires_at Constants::TOKEN_EXPIRATION_TIME_STR
    json.firebase_token Firebase::FirebaseTokenGenerator.new("#{ENV['FIREBASE_SECRET']}").create_token({ uid: current_profile.uuid })
  else
    json.nil!
  end
end

json.state_data do
  if current_profile.present?
    json.partial! 'api/v1/profiles/state', profile: current_profile
  else
    json.nil!
  end
end
