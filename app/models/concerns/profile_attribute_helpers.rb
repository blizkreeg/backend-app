module ProfileAttributeHelpers
  extend ActiveSupport::Concern

  GENDER_MALE = 'male'
  GENDER_FEMALE = 'female'
  LOW_DESIRABILITY = 6

  def male?
    self.gender == GENDER_MALE
  end

  def female?
    self.gender == GENDER_FEMALE
  end

  def intent_text
    case self.intent
    when 'Dating'
      'To date and see where it goes'
    when 'Relationship'
      'Seeking a Relationship'
    end
  end

  def about_me_i_love_label
    "I love".upcase
  end

  def about_me_ideal_weekend_label
    "An Ideal Weekend Would Be".upcase
  end

  def about_me_bucket_list_label
    "On My Bucket List This Year".upcase
  end

  def about_me_quirk_label
    "A Quirk I Have".upcase
  end

  def about_me_order
    %w(about_me_i_love about_me_ideal_weekend about_me_bucket_list about_me_quirk)
  end

  def unmoderated?
    self.moderation_status == 'unmoderated'
  end

  def in_review?
    self.moderation_status == 'in_review'
  end

  def blacklisted?
    self.moderation_status == 'blacklisted'
  end

  def approved?
    self.moderation_status == 'approved'
  end

  # not approved could mean unmoderated (new) or any other state that is not an approved state
  def not_approved?
    self.moderation_status != 'approved'
  end

  def low_desirability?
    self.desirability_score.present? && (self.desirability_score <= LOW_DESIRABILITY)
  end

  def not_approved_or_low_dscore?
    self.not_approved? || self.desirability_score.blank? || self.low_desirability?
  end
end
