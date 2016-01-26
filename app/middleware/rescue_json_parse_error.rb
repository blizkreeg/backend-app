class RescueJsonParseError
  def initialize(app)
    @app = app
  end

  def call(env)
    begin
      @app.call(env)
    rescue ActionDispatch::ParamsParser::ParseError => error
      if env['HTTP_ACCEPT'] =~ /application\/json/
        error_output = "Invalid JSON payload"
        return [
          400, { "Content-Type" => "application/json" },
          [ { error: { http_status: 400, message: error_output } }.to_json ]
        ]
      else
        raise error
      end
    end
  end
end
