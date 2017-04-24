class SocialUpdate < ActiveRecord::Base
  belongs_to :profile, foreign_key: "profile_uuid", touch: true
  has_many :likes, class_name: 'SocialLike', dependent: :destroy
  has_many :comments, class_name: 'SocialComment', dependent: :destroy

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

  scope :published, -> { with_published(true) }
  scope :not_published, -> { where("(social_updates.properties->>'published')::boolean IS NOT TRUE") }
  scope :ordered_by_recency, -> { order("(social_updates.properties->>'posted_at')::timestamp DESC NULLS LAST") }
end