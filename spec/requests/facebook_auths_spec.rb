require 'rails_helper'

RSpec.describe "FacebookAuths", type: :request do
  describe "GET /auth/facebook" do
    it "responds with valid auth hash" do
      get '/auth/facebook'
      puts response.inspect
      expect(response).to redirect_to(omniauth_callback_path)# have_http_status(200)
    end
  end
end
