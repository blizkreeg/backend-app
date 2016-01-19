class SocialAuthentication < ActiveRecord::Base
  belongs_to :profile, foreign_key: "profile_uuid"
end
