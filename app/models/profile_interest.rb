class ProfileInterest < ActiveRecord::Base
  belongs_to :profile, foreign_key: "profile_uuid", touch: true
  belongs_to :interest
end
