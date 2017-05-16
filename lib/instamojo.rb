module Instamojo
  class Payment
    INSTAMOJO_HOST = Rails.env.production? ? 'https://www.instamojo.com' : 'https://test.instamojo.com'
    attr_accessor :id, :payment_url, :profile

    def initialize(profile)
      @profile = profile
    end

    def create_link
      headers = {
        "X-Api-Key" => Rails.env.production? ? "caa31f4ed12bdf8bdade3e3825b3300a" : "9b2449b56bd0ac0a649d40c69d693342",
        "X-Auth-Token" => Rails.env.production? ? "4d338f299422a7393fbf81b76dd6800d" : "434209c3abe280e84b1a00747dc6f521"
      }

      payload = {
        purpose: "ekCoffee #{Constants::PREMIUM_TIER_NAME.capitalize} Membership",
        amount: Constants::PREMIUM_TIER_PRICE.to_s,
        buyer_name: self.profile.fullname,
        email: self.profile.email,
        phone: self.profile.phone,
        redirect_url: Rails.application.routes.url_helpers.membership_status_url(params: { ekcapp: 1, uuid: self.profile.uuid }),
        send_email: false,
        send_sms: false,
        webhook:  Rails.application.routes.url_helpers.process_instamojo_payment_url,
        allow_repeated_payments: false,
      }

      conn = Faraday.new(url: "#{INSTAMOJO_HOST}/api/1.1/", :headers => headers)
      response = conn.post 'payment-requests/', payload

      data = JSON.parse(response.body)
      if data["success"]
        @id = data["payment_request"]["id"]
        @payment_url = data["payment_request"]["longurl"]
      end
    end
  end
end
