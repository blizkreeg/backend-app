class DatePlace < ActiveRecord::Base
  has_many :date_suggestions, dependent: :destroy

  PROPERTIES = {
    name:               :string,
    street_address:     :string,
    part_of_city:       :string,
    city:               :string,
    state:              :string,
    country:            :string,
    latitude:           :decimal,
    longitude:          :decimal,
    price_range:        :string,
    date_types:         :string_array,
    photos_public_ids:  :string_array
  }

  jsonb_accessor :properties, PROPERTIES

  def price_range
    self.read_attribute(:price_range) || 'Unknown'
  end
end
