class Brewing < ActiveRecord::Base
  belongs_to :profile, foreign_key: "profile_uuid", touch: true
  belongs_to :brew, touch: true

  ATTRIBUTES = {

  }

  jsonb_accessor :properties, ATTRIBUTES
end
