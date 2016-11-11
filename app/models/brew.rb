class Brew < ActiveRecord::Base
  has_many :brewings
  has_many :profiles, through: :brewings
  belongs_to :brew_category

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

  before_create :defaults_to_under_review
  before_create :set_price
  before_save :set_group_size

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

    self.min_desirability = self.profiles.merge(Brewing.host).first.try(:desirability_score) || 7 # default
    self.moderation_status = 'live'
    self.save!
  end

  def reject!(reason)
    self.update!(moderation_status: 'rejected', rejection_reason: reason)
  end

  private

  def set_price
    self.price = 250
  end

  def set_group_size
    self.max_group_size ||= DEFAULT_GROUP_SIZE
  end

  def defaults_to_under_review
    self.moderation_status ||= 'in_review'
  end
end
