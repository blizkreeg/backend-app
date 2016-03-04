class MeetingReadiness < ActiveRecord::Base
  belongs_to :conversation
  belongs_to :profile, foreign_key: "profile_uuid"

  YES_VALUE = "Yes"
  NO_VALUE = "Not Yet"

  MEETING_READINESS_VALUES = [YES_VALUE, NO_VALUE]

  scope :by_profile, -> (uuid) { where(profile_uuid: uuid) }
  scope :ready, -> { with_value(YES_VALUE) }

  ATTRIBUTES = {
    value: :string
  }

  jsonb_accessor :properties, ATTRIBUTES

  validates :value, inclusion: { in: MEETING_READINESS_VALUES, message: "%{value} is not valid" }

  before_save :set_recorded_at, if: Proc.new { |mreadiness| mreadiness.value_changed? }

  private

  def set_recorded_at
    self.recorded_at = DateTime.now.utc
  end
end
