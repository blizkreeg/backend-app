class SkippedProfile < ActiveRecord::Base
  belongs_to :by, foreign_key: "by_profile_uuid", class_name: 'Profile'

  belongs_to :skipped, foreign_key: "skipped_profile_uuid", class_name: 'Profile'

  ATTRIBUTES = {
  }

  jsonb_accessor :properties, ATTRIBUTES
end
