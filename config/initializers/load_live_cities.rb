LIVE_CITIES = YAML.load_file("#{Rails.root}/config/live_in_cities.yml")[Rails.env].map(&:with_indifferent_access)
