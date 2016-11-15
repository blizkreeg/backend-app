class Brew < ActiveRecord::Base
  has_many :brewings
  has_many :profiles, through: :brewings
  # belongs_to :brew_category

  DEFAULT_GROUP_SIZE = 8
  POST_BREW_MIN_NUM_DAYS_OUT = 2
  POST_BREW_MAX_NUM_DAYS_OUT = 7

  GROUP_MAKEUPS = {
    'Balanced (men & women)' => 0,
    'Women only' => 1,
    'Men only' => 2
  }

  MODERATION_STATUS = %w(
    in_review
    rejected
    live
    expired
  )

  MASS_UPDATE_ATTRIBUTES = %i(
    title
    happening_on
    starts_at
    place
    notes
  )

  ATTRIBUTES = {
    primary_image_cloudinary_id: :string,
    title: :string,
    notes: :text,
    happening_on: :date,
    starts_at: :decimal,
    place: :string,
    address: :string,
    max_group_size: :integer,
    category: :string,
    min_age: :integer,
    max_age: :integer,
    group_makeup: :integer,
    payment_link: :string,
    price: :integer,
    min_desirability: :integer,
    moderation_status: :string,
    rejection_reason: :string
  }

  jsonb_accessor :properties, ATTRIBUTES

  scope :ordered_by_recency, -> { order("brews.created_at DESC") }

  before_create :set_create_defaults

  def tipped?
    self.profiles.of_gender('male').count >= self.max_group_size / 4 &&
    self.profiles.of_gender('female').count >= self.max_group_size / 4
  end

  def balanced_mf?
    self.group_makeup == 0
  end

  def places_remaining_for_gender(gender)
    rsvp_count = self.profiles.with_gender(gender).count

    if self.balanced_mf?
      self.max_group_size/2 - rsvp_count
    else
      self.max_group_size - rsvp_count
    end
  end

  def full_for?(profile)
    self.places_remaining_for_gender(profile.gender) == 0
  end

  def male_signups
    self.profiles.with_gender('male')
  end

  def female_signups
    self.profiles.with_gender('female')
  end

  def youngest_person
    self.profiles.youngest
  end

  def oldest_person
    self.profiles.oldest
  end

  def approve!
    # FIXME this should be the real link
    self.payment_link = "/brews/#{self.id}/registered"

    # FIXME this should be changed to primary host
    host = self.profiles.merge(Brewing.hosts).first
    self.min_age = host.male? ? (host.age - 5) : (host.age - 1)
    self.max_age = host.male? ? (host.age + 1) : (host.age + 5)
    self.min_desirability = host.try(:desirability_score) || 7 # default
    self.moderation_status = 'live'
    self.save!
  end

  def reject!(reason)
    self.update!(moderation_status: 'rejected', rejection_reason: reason)
  end

  def expire!
    self.update!(moderation_status: 'expired')
  end

  def happening_at
    hour = self.starts_at.floor.to_i
    min = ((self.starts_at % hour) * 60).to_i

    host_tz = self.profiles.merge(Brewing.hosts).first.time_zone

    Time.new(self.happening_on.year,
              self.happening_on.month,
              self.happening_on.day,
              hour,
              min,
              0,
              ActiveSupport::TimeZone.new(host_tz).formatted_offset)
  end

  private

  def set_create_defaults
    self.price ||= nil
    self.group_makeup ||= 0
    self.moderation_status = 'in_review'
    self.max_group_size ||= DEFAULT_GROUP_SIZE
  end
end
