class Brewing < ActiveRecord::Base
  belongs_to :profile, foreign_key: "profile_uuid", touch: true
  belongs_to :brew, touch: true

  ATTRIBUTES = {
    host: :boolean
  }

  jsonb_accessor :properties, ATTRIBUTES

  scope :hosts, -> { is_host }
end
