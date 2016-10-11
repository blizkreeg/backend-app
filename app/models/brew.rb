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

  ATTRIBUTES = {
    title: :string,
    notes: :text,
    happening_on: :date,
    starts_at: :time,
    place: :string,
    address: :string,
    max_group_size: :integer,
    category: :string,
    min_age: :integer,
    max_age: :integer,
    group_makeup: :integer
  }

  jsonb_accessor :properties, ATTRIBUTES

  before_save :set_group_size

  private

  def set_group_size
    self.max_group_size ||= DEFAULT_GROUP_SIZE
  end
end
