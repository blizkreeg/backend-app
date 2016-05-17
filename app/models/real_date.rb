class RealDate < ActiveRecord::Base
  # include JsonbAttributeHelpers

  belongs_to :conversation, touch: true
  belongs_to :profile, foreign_key: "profile_uuid"
  belongs_to :date_place, touch: true

  MASS_UPDATE_ATTRIBUTES = %i(
    ready_to_meet
    meeting_day
    meeting_time
    meeting_at
    other_date_place_name
    date_place_id
    post_date_rating
    post_date_feedback
  )

  YES_VALUE = "Yes"
  NO_VALUE = "Not Yet"

  READY_TO_MEET_OPTIONS = [YES_VALUE, NO_VALUE]

  POST_DATE_RATING_OPTIONS = [
    "We never met",
    "Bad",
    "Fine, but not interested in meeting again",
    "Good! Would like to meet again"
  ]

  scope :by_profile, -> (uuid) { where(profile_uuid: uuid) }
  scope :are_ready_to_meet, -> { with_ready_to_meet(YES_VALUE) }

  ATTRIBUTES = {
    ready_to_meet:          :string,
    rtm_recorded_at:        :date_time,
    meeting_day:            :date,
    meeting_time:           :string,
    meeting_at:             :date_time,
    meeting_at_recorded_at: :date_time,
    other_date_place_name:  :string,
    post_date_rating:       :string,
    post_date_feedback:     :string
  }

  # store_accessor :properties, *(ATTRIBUTES.keys.map(&:to_sym))
  # jsonb_attr_helper :properties, ATTRIBUTES
  jsonb_accessor :properties, ATTRIBUTES

  validates :ready_to_meet, inclusion: { in: READY_TO_MEET_OPTIONS, message: "%{value} is not valid" }, allow_blank: true, allow_nil: true
  validates :date_place, presence: true, if: Proc.new { |real_date| real_date.date_place_id.present? }
  validates :post_date_rating, inclusion: { in: POST_DATE_RATING_OPTIONS, message: "%{value} is not valid" }, allow_blank: true, allow_nil: true

  before_save :set_rtm_recorded_at, if: Proc.new { |real_date| real_date.ready_to_meet_changed? }
  before_save :set_meeting_at_recorded_at, if: Proc.new { |real_date| real_date.meeting_at_changed? }
  # before_save :set_meeting_at, if: Proc.new { |real_date| real_date.meeting_day.present? && real_date.meeting_time.present? }

  def date_profile
    conversation.the_other_who_is_not(profile.uuid)
  end

  def is_ready_to_meet?
    self.ready_to_meet == YES_VALUE
  end

  def not_ready_to_meet?
    self.ready_to_meet == NO_VALUE
  end

  def meet_arranged?
    self.meeting_at.present? && (self.date_place.present? || self.other_date_place_name.present?)
  end

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
