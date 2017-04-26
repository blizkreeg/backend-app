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

  def self.create_blank_for(profile)
    self.create!(profile_uuid: profile.uuid, social_question: SocialQuestion.first_active)
  end
end
