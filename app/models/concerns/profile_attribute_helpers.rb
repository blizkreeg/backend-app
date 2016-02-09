module ProfileAttributeHelpers
  extend ActiveSupport::Concern

  def male?
    self.gender == 'male'
  end

  def female?
    self.gender == 'female'
  end

  def intent_text
    case self.intent
    when 'Dating'
      'Date and see where it leads'
    when 'Relationship'
      'Find something long-term'
    end
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
    %w(about_me_ideal_weekend about_me_bucket_list about_me_quirk)
  end
end
