class Match < ActiveRecord::Base
  # who is the match for?
  belongs_to :for_profile, foreign_key: "for_profile_uuid"
  # who is the match?
  belongs_to :matched_profile, foreign_key: "matched_profile_uuid", class_name: 'Profile'

  scope :undecided, -> { where("properties->>'decision' is null") }

  ATTRIBUTES = {
    decision: :string,
    decision_at: :date_time,
    delivered_at: :date_time,
  }

  jsonb_accessor :properties, ATTRIBUTES

  before_save :set_defaults

  def self.update_delivery_time(id)
    Match.update(id, delivered_at: DateTime.now)
  end

  private

  def set_defaults
    self.decision_at = DateTime.now if self.decision_changed?
  end
end
