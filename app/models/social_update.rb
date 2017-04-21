class SocialUpdate < ActiveRecord::Base
  belongs_to :profile, foreign_key: "profile_uuid", touch: true

  MASS_UPDATE_ATTRIBUTES = %i(
    text
    picture_id
  )

  ATTRIBUTES = {
    published: :boolean,
    text: :string,
    picture_id: :string,
    posted_at: :date_time
  }

  # store_accessor :properties, *(ATTRIBUTES.keys.map(&:to_sym))
  # jsonb_attr_helper :properties, ATTRIBUTES
  jsonb_accessor :properties, ATTRIBUTES
end
