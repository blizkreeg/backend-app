class RealDate < ActiveRecord::Base
  belongs_to :conversation
  belongs_to :profile, foreign_key: "profile_uuid"
  belongs_to :date_place

  MASS_UPDATE_ATTRIBUTES = %i(
    ready_to_meet
    meeting_day
    meeting_time
    other_date_place_name
    date_place_id
  )

  YES_VALUE = "Yes"
  NO_VALUE = "Not Yet"

  READY_TO_MEET_OPTIONS = [YES_VALUE, NO_VALUE]

  scope :by_profile, -> (uuid) { where(profile_uuid: uuid) }
  scope :ready_to_meet, -> { with_ready_to_meet(YES_VALUE) }

  ATTRIBUTES = {
    ready_to_meet: :string,
    rtm_recorded_at: :date_time,
    meeting_day: :date,
    meeting_time: :string,
    meeting_at: :date_time,
    meeting_at_recorded_at: :date_time,
    other_date_place_name: :string
  }

  jsonb_accessor :properties, ATTRIBUTES

  validates :ready_to_meet, inclusion: { in: READY_TO_MEET_OPTIONS, message: "%{value} is not valid" }, allow_blank: true, allow_nil: true
  validates :date_place, presence: true, if: Proc.new { |real_date| real_date.date_place_id.present? }

  before_save :set_rtm_recorded_at, if: Proc.new { |real_date| real_date.ready_to_meet_changed? }
  before_save :set_meeting_at_recorded_at, if: Proc.new { |real_date| real_date.meeting_day_changed? || real_date.meeting_time_changed? }
  before_save :set_meeting_at, if: Proc.new { |real_date| real_date.meeting_day.present? && real_date.meeting_time.present? }

  private

  def set_rtm_recorded_at
    self.rtm_recorded_at = DateTime.now.utc
  end

  def set_meeting_at_recorded_at
    self.meeting_at_recorded_at = DateTime.now.utc
  end

  def set_meeting_at
    tz_offset = ActiveSupport::TimeZone.new(self.profile.time_zone).utc_offset / 3600 rescue 0
    hours = self.meeting_time[0..1].to_i
    minutes = self.meeting_time[2..3].to_i
    self.meeting_at = DateTime.new(self.meeting_day.year, self.meeting_day.month, self.meeting_day.day, hours, minutes, 0, sprintf("%+d", tz_offset))

    true
  end
end