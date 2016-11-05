class Brew < ActiveRecord::Base
  has_many :brewings
  has_many :profiles, through: :brewings
  belongs_to :brew_category

  DEFAULT_GROUP_SIZE = 8
  POST_BREW_MIN_NUM_DAYS_OUT = 0
  POST_BREW_MAX_NUM_DAYS_OUT = 4

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

  ATTRIBUTES = {
    primary_image_cloudinary_id: :string,
    title: :string,
    notes: :text,
    happening_on: :date,
    starts_at: :integer,
    place: :string,
    address: :string,
    max_group_size: :integer,
    category: :string,
    min_age: :integer,
    max_age: :integer,
    group_makeup: :integer,
    payment_link: :string,
    price: :integer,
    moderation_status: :string,
    rejection_reason: :string
  }

  jsonb_accessor :properties, ATTRIBUTES

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

  private

  def set_price
    self.price = 250
  end

  def set_group_size
    self.max_group_size ||= DEFAULT_GROUP_SIZE
  end

  def defaults_to_under_review
    self.moderation_status = 'in_review'
  end

  def approve!
    self.update! moderation_status: 'live'
  end

  def reject!(reason)
    self.update! moderation_status: 'rejected', rejection_reason: reason
  end
end
