class SocialUpdate < ActiveRecord::Base
  belongs_to :profile, foreign_key: "profile_uuid", touch: true
  has_many :likes, class_name: 'SocialLike', dependent: :destroy
  has_many :comments, class_name: 'SocialComment', dependent: :destroy
  belongs_to :social_question

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

  jsonb_accessor :properties, ATTRIBUTES

  scope :published, -> { with_published(true) }
  scope :not_published, -> { where("(social_updates.properties->>'published')::boolean IS NOT TRUE") }
  scope :ordered_by_recency, -> { order("(social_updates.properties->>'posted_at')::timestamp DESC NULLS LAST") }
  scope :near, -> (lat, lng, distance_meters=nil) { joins(:profile).where("earth_box(ll_to_earth(?, ?), ?) @> ll_to_earth(profiles.search_lat, profiles.search_lng)", lat, lng, distance_meters || Constants::NEAR_DISTANCE_METERS) }
  scope :for, -> (profile) { joins(:profile).where("(((profiles.properties) ->> 'desirability_score')::decimal = ?)", profile.desirability_score).near(profile.latitude, profile.longitude) }

  def self.create_blank_for(profile)
    self.create!(profile_uuid: profile.uuid, social_question: SocialQuestion.first_active)
  end
end
