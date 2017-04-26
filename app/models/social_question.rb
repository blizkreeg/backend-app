class SocialQuestion < ActiveRecord::Base
  has_many :social_updates, dependent: :destroy

  MASS_UPDATE_ATTRIBUTES = %i(
    question_text
    question_lede
  )

  ATTRIBUTES = {
    question_text: :string,
    question_lede: :string,
    active: :boolean
  }

  jsonb_accessor :properties, ATTRIBUTES

  def self.promote_random_to_active
    question = self.order("RANDOM()").take
    question.update!(active: true)

    self.with_active(true).where.not(id: [question.id]).map { |q| q.update!(active: nil) }

    question
  end

  def self.first_active
    self.with_active(true).take || self.promote_random_to_active
  end
end
