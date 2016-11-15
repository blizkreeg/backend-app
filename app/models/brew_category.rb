class BrewCategory < ActiveRecord::Base
  # has_many :brews

  ATTRIBUTES = {
    name: :string
  }

  jsonb_accessor :properties, ATTRIBUTES
end
