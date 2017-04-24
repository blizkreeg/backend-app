class SocialComment < ActiveRecord::Base
  belongs_to :profile, foreign_key: "profile_uuid", touch: true
  belongs_to :social_update

  ATTRIBUTES = {
    comment_text: :string
  }

  jsonb_accessor :properties, ATTRIBUTES
end
