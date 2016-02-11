class Match < ActiveRecord::Base
  # who is the match for?
  belongs_to :for_profile, foreign_key: "for_profile_uuid"
  # who is the match?
  belongs_to :matched_profile, foreign_key: "matched_profile_uuid", class_name: 'Profile'

  STALE_EXPIRATION_DURATION = 48.hours

  scope :undecided, -> { where("properties->>'decision' is null") }
  scope :unmatched, -> { where("CAST(properties->>'unmatched' AS boolean) = true") }

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
    expires_at: :date_time
  }

  jsonb_accessor :properties, ATTRIBUTES

  before_save :set_defaults

  def self.update_delivery_time(id)
    Match.update(id, delivered_at: DateTime.now)
  end

  def unmatch!(reason)
    self.unmatched = true
    self.unmatched_at = DateTime.now
    self.unmatched_reason = reason
    self.save!
  end

  def conversation
    Conversation.with_participant_uuids([self.for_profile_uuid, self.matched_profile_uuid]).take
  end

  private

  def set_defaults
    self.unmatched = false if self.unmatched.nil?
    self.decision_at = DateTime.now if self.decision_changed?

    true
  end
end
