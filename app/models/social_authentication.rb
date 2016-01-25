class SocialAuthentication < ActiveRecord::Base
  belongs_to :profile, foreign_key: "profile_uuid"

  # TBD
  # this method could include the facebookauthentication module at run-time if FB auth object or cast using .becomes
  # def initialize
  # end

end
