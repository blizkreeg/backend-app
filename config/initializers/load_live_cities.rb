cities = YAML.load_file("#{Rails.root}/config/live_in_cities.yml")[Rails.env]

Rails.application.config.live_in_cities = cities.present? ? cities.map(&:with_indifferent_access) : {}
