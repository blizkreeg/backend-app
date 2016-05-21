cities = YAML.load_file("#{Rails.root}/config/live_in_cities.yml")[Rails.env]
LIVE_CITIES = cities.present? ? cities.map(&:with_indifferent_access) : {}
