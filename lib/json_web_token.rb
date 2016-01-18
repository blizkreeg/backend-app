class JsonWebToken
  class << self
    def encode(payload, expires_in = 60.days.from_now)
      payload = payload.dup
      payload['exp'] = expires_in.to_i
      JWT.encode(payload, Rails.application.secrets.secret_key_base, 'HS256')
    end

    def decode(token_str)
      JWT.decode(token_str, Rails.application.secrets.secret_key_base)
    rescue StandardError => e
      nil
    end
  end
end
