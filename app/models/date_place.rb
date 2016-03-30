class DatePlace < ActiveRecord::Base
  include JsonbAttributeHelpers

  has_many :date_suggestions, dependent: :destroy
  has_many :real_dates, dependent: :destroy

  ATTRIBUTES = {
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

  store_accessor :properties, *(ATTRIBUTES.keys.map(&:to_sym))
  jsonb_attr_helper :properties, ATTRIBUTES

  def price_range
    self.read_attribute(:price_range) || 'Unknown'
  end
end
