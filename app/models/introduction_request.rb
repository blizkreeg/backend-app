class IntroductionRequest < ActiveRecord::Base
  # who is the match for?
  belongs_to :by, foreign_key: "by_profile_uuid", class_name: 'Profile'
  # who is the match?
  belongs_to :to, foreign_key: "to_profile_uuid", class_name: 'Profile'

  ATTRIBUTES = {
    made_on: :date_time,
    responded_on: :date_time,
    mutual: :boolean,
  }

  jsonb_accessor :properties, ATTRIBUTES
end
