class ConversationHealth < ActiveRecord::Base
  belongs_to :conversation
  belongs_to :profile, foreign_key: "profile_uuid"

  HEALTH_CHECK_VALUES = [
    "Conversation fizzled",
    "It's going okay",
    "Going good",
    "Great!"
  ]

  scope :by_profile, -> (uuid) { where(profile_uuid: uuid) }

  ATTRIBUTES = {
    value: :string
  }

  jsonb_accessor :properties, ATTRIBUTES

  validates :value, inclusion: { in: HEALTH_CHECK_VALUES, message: "%{value} is not valid" }

  before_save :set_recorded_at, if: Proc.new { |chealth| chealth.value_changed? }

  private

  def set_recorded_at
    self.recorded_at = DateTime.now.utc
  end
end
