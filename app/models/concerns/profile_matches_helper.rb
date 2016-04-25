module ProfileMatchesHelper
  extend ActiveSupport::Concern

  # adds new matches to the queue, sorted by score
  def add_matches_to_queue(matched_profile_uuids, scores)
    $redis.zadd(queued_matches_key, scores.zip(matched_profile_uuids))
  end

  # returns uuids of queued matches
  def queued_matches
    $redis.zrange(queued_matches_key, 0, Constants::N_MATCHES_AT_A_TIME-1)
  end

  private

  def queued_matches_key
    "new_matches/#{self.uuid}"
  end
end
