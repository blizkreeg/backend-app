class Match < ActiveRecord::Base
  # who is the match for?
  belongs_to :for_profile, foreign_key: "for_profile_uuid", class_name: 'Profile'
  # who is the match?
  belongs_to :matched_profile, foreign_key: "matched_profile_uuid", class_name: 'Profile'

  STALE_EXPIRATION_DURATION = 2910.minutes # 48 hours, 30 minutes
  LIKE_DECISION_STR = 'Like'
  PASS_DECISION_STR = 'Pass'

  scope :undecided, -> { where("properties->>'decision' is null") }
  scope :unmatched, -> { with_unmatched(true) }
  scope :open, -> { with_unmatched(false) }
  scope :mutual_like, -> { with_mutual(true) }
  scope :liked, -> { with_decision(LIKE_DECISION_STR) }
  scope :not_liked, -> { with_decision(PASS_DECISION_STR) }

  MASS_UPDATE_ATTRIBUTES = %i(
    decision
  )

  ATTRIBUTES = {
    decision: :string,
    decision_at: :date_time,
    delivered_at: :date_time,
    unmatched: :boolean,
    unmatched_at: :date_time,
    unmatched_reason: :string,
    expires_at: :date_time,
    initiates_profile_uuid: :string,
    mutual: :boolean
  }

  jsonb_accessor :properties, ATTRIBUTES

  validates :unmatched_reason, inclusion: { in: Constants::UNMATCH_REASONS, message: "%{value} is not a valid reason" }, allow_nil: true

  before_save :set_defaults

  def self.update_delivery_time(id)
    Match.update(id, delivered_at: DateTime.now)
  end

  def self.mark_if_mutual_like(match_ids)
    matches = Match.find match_ids
    matches.each do |match|
      reverse_match = match.reverse
      if reverse_match.present? && reverse_match.like?
        match.update mutual: true
        reverse_match.update mutual: true
      end
    end
  end

  def unmatch!(reason)
    self.unmatched = true
    self.unmatched_at = DateTime.now
    self.unmatched_reason = reason
    self.save!
  end

  def reverse
    Match.where(for_profile_uuid: self.matched_profile_uuid, matched_profile_uuid: self.for_profile_uuid).take
  end

  def conversation
    Conversation.with_participant_uuids([self.for_profile_uuid, self.matched_profile_uuid]).take
  end

  def like?
    self.decision == LIKE_DECISION_STR
  end

  def pass?
    self.decision == PASS_DECISION_STR
  end

  def undecided?
    self.decision.nil?
  end

  def waiting_for_response_expires_in_hours
    t = self.reverse.try(:expires_at)
    if t.present?
      (t.to_i - DateTime.now.utc.to_i) / 1.hour
    else
      nil
    end
  end

  def test_and_set_expiration!
    if self.expires_at.nil?
      self.expires_at = DateTime.now.utc + STALE_EXPIRATION_DURATION
      self.save!
    end
  end

  def expires_in_hours
    (self.expires_at.to_i - DateTime.now.utc.to_i) / 1.hour
  end

  private

  def set_defaults
    self.unmatched = false if self.unmatched.nil?
    self.decision_at = DateTime.now if self.decision_changed?
    self.mutual = false if self.mutual.nil?

    true
  end

  # def set_mutual
  #   if self.decision_changed? && self.like?
  #     reverse_match = self.reverse
  #     if reverse_match.present? && reverse_match.like?
  #       self.mutual = true
  #       reverse_match.update mutual: true
  #     end
  #   end

  #   true
  # end
end
