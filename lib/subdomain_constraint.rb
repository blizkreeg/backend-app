class SubdomainConstraint
  def initialize(subdomain)
    @subdomain = subdomain
  end

  def matches?(request)
    if !Rails.env.production?
      true
    else
      @subdomain == request.subdomain
    end
  end
end
