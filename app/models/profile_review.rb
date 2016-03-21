class ProfileReview < ActiveRecord::Base
  belongs_to :profile, foreign_key: 'profile_uuid'

  BASIC_PROPERTIES = %w(height highest_degree profession)

  PROPERTIES = {
    all_photos_ok: :boolean,
    facebook_ok: :boolean,
    notes: :string_array,
    facebook_rel_status: :string,
    facebook_friend_count: :integer,
    basics_completed: :string_array,
    questions_completed: :string_array,
    basics_ok: :boolean,
    questions_ok: :boolean,
    basic_attractiveness: :integer,
    grammar_and_language: :string,
    multiple_degrees: :boolean
  }

  jsonb_accessor :properties, PROPERTIES

  class << self
    def review(profile_uuid)
      profile = Profile.find(profile_uuid)
      review = profile.review || profile.create_review
      review.check_everything

      profile.update!(pending_human_review: true)
    rescue ActiveRecord::RecordNotFound
    end
  end

  def check_basics
    profile = self.profile

    new_basics_completed = Set.new
    new_basics_completed << "Height" if profile.height.present?
    new_basics_completed << "Faith" if profile.faith.present?
    new_basics_completed << "Highest Degree" if profile.highest_degree.present?
    new_basics_completed << "Colleges" if profile.schools_attended.present?
    new_basics_completed << "Profession" if profile.profession.present?

    self.basics_completed = new_basics_completed.to_a if self.basics_completed.blank? || (new_basics_completed ^ self.basics_completed.to_set).present?
    self.basics_ok = (self.basics_completed & BASIC_PROPERTIES).present? ? true : false
  end

  def check_questions
    questions_completed = []
    questions_completed << 'Ideal Weekend' if profile.about_me_ideal_weekend.present?
    questions_completed << 'Bucket List' if profile.about_me_bucket_list.present?
    questions_completed << 'Quirk' if profile.about_me_quirk.present?

    questions_ok = questions_completed.present?
  end

  def check_multiple_degrees
    multiple_degrees = %w(Masters Doctorate).include?(self.profile.highest_degree) ? true : false
  end

  def check_facebook
    facebook_rel_status = profile.possible_relationship_status
  end

  def check_everything
    check_basics
    check_facebook
    check_questions
    check_multiple_degrees
  end
end
