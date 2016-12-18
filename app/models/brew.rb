class Brew < ActiveRecord::Base
  has_many :brewings
  has_many :profiles, through: :brewings
  # belongs_to :brew_category

  MIN_GROUP_SIZE = 8
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
    formatted_details
  )

  ATTRIBUTES = {
    primary_image_cloudinary_id: :string,
    other_images_cloudinary_ids: :string_array,
    title: :string,
    slug: :string,
    notes: :text,
    formatted_details: :text,
    happening_on: :date,
    starts_at: :decimal,
    place: :string,
    address: :string,
    min_group_size: :integer,
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
  scope :ordered_by_soonest, -> { order("(brews.properties->>'happening_on')::date ASC, (brews.properties->>'starts_at')::decimal ASC") }
  scope :live, -> { with_moderation_status('live') }
  scope :in_review, -> { with_moderation_status('in_review') }

  before_create :set_create_defaults

  def tipped?
    self.profiles.merge(Brewing.going).of_gender('male').count >= self.min_group_size / 2 &&
    self.profiles.merge(Brewing.going).of_gender('female').count >= self.min_group_size / 2
  end

  def hot?
    self.profiles.merge(Brewing.interested).of_gender('male').count >= self.min_group_size / 2 &&
    self.profiles.merge(Brewing.interested).of_gender('female').count >= self.min_group_size / 2
  end

  def balanced_mf?
    self.group_makeup == 0
  end

  def places_remaining_for_gender(gender)
    rsvp_count = self.profiles.merge(Brewing.going).with_gender(gender).count

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
    self.payment_link ||= "/brews/#{self.slug}/registered"

    # FIXME this should be changed to primary host
    host = self.profiles.merge(Brewing.hosts).first
    self.min_age ||= host.male? ? (host.age - 5) : (host.age - 1)
    self.max_age ||= host.male? ? (host.age + 1) : (host.age + 5)
    self.min_desirability ||= host.try(:desirability_score) || 7 # default
    self.moderation_status = 'live'
    self.save!
  end

  def reject!(reason=nil)
    self.moderation_status = 'rejected'
    self.rejection_reason = reason
    self.save!
  end

  def expire!
    self.update!(moderation_status: 'expired')
  end

  def host_tz
    self.profiles.merge(Brewing.hosts).first.time_zone
  end

  def host_time_now
    Time.now.in_time_zone(self.host_tz)
  end

  def happening_at
    hour = self.starts_at.floor.to_i
    min = ((self.starts_at % hour) * 60).to_i

    Time.new(self.happening_on.year,
              self.happening_on.month,
              self.happening_on.day,
              hour,
              min,
              0,
              ActiveSupport::TimeZone.new(self.host_tz).formatted_offset)
  end

  def free?
    self.price.blank?
  end

  def slugify_title
    self.slug ||= [self.title.parameterize,
                    self.happening_on.to_s,
                    6.times.map{ (('a'..'z').to_a + (0..9).to_a).sample }.join].join('-')
  end

  private

  def set_create_defaults
    self.price ||= nil
    self.group_makeup ||= 0
    self.moderation_status = 'in_review'
    self.min_group_size ||= MIN_GROUP_SIZE
    self.max_group_size ||= self.min_group_size * 1.5
    self.slugify_title

    true
  end
end
