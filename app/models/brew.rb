class Brew < ActiveRecord::Base
  has_many :brewings
  has_many :profiles, through: :brewings

  DEFAULT_SPOTS = 8

  ATTRIBUTES = {
    title: :string,
    on: :date,
    starts_at: :time,
    duration: :integer, # mins
    place: :string,
    short_description: :text,
    notes: :text,
    spots: :integer,
    category: :string,
  }

  jsonb_accessor :properties, ATTRIBUTES

  after_initialize :set_default_spots

  private

  def set_default_spots
    self.spots ||= DEFAULT_SPOTS
  end
end
