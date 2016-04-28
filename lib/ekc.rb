module Ekc
  def self.logger
    Rails.logger
  end

  # converts distance (in km) to a value between 0 and 1
  def self.normalize_distance_km(distance)
    min_dist = 0
    max_dist = 21_000 * 1.0 # in km, roughly the max distance between two points on earth

    (((distance - 0) * (1 - 0)) / (max_dist - 0)) + 0
  rescue StandardError => e
    EKC.logger.error "Error normalizing distance #{distance}, exception: #{e.class.name}, #{e.backtrace.join('\n')}"
    0.7
  end
end

EKC = Ekc
