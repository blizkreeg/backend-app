module Ekc
  def self.logger
    Rails.logger
  end

  # normalizes earth distance (in km) to a value between 0 and 1
  def self.normalize_distance_km(distance)
    min_dist = 0
    max_dist = 21_000 * 1.0 # in km, roughly the max distance between two points on earth

    (((distance - 0) * (1 - 0)) / (max_dist - 0)) + 0
  rescue StandardError => e
    EKC.logger.error "Error normalizing distance #{distance}, exception: #{e.class.name}, #{e.backtrace.join('\n')}"
    0.7
  end

  def self.now_in_pacific_time
    DateTime.now.in_time_zone('America/Los_Angeles')
  end

  def self.launched_in?(lat, lng)
    return false if lat.blank? || lng.blank?

    Rails.application.config.live_in_cities.each do |city|
      distance_to = Geocoder::Calculations.distance_between([lat, lng], [city[:lat], city[:lng]])
      return true if distance_to * 1_000 <= city[:radius].to_f # comparison is in meters
    end

    false
  end
end

EKC = Ekc

class ActiveSupport::Logger
  def error(*args)
    ExceptionNotifier.notify_exception(StandardError.new(args.first)) unless Rails.env.development?
    super
  end
end
