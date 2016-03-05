module ProfileAttributeHelpers
  extend ActiveSupport::Concern

  def height=(ft_in_str)
    write_attribute(:height, ft_in_str)

    if ft_in_str.present?
      ft, inches = ft_in_str.split(/['"]/i)
      ht_in = 12 * ft.to_i + inches.to_i
    end

    write_attribute(:height_in, ht_in)
  end

  def height_in=(value); end

  def seeking_minimum_height=(ft_in_str)
    write_attribute(:seeking_minimum_height, ft_in_str)

    if ft_in_str.present?
      ft, inches = ft_in_str.split(/['"]/i)
      ht_in = 12 * ft.to_i + inches.to_i
    end

    write_attribute(:seeking_minimum_height_in, ht_in)
  end

  def seeking_minimum_height_in=(value); end

  def seeking_maximum_height=(ft_in_str)
    write_attribute(:seeking_maximum_height, ft_in_str)

    if ft_in_str.present?
      ft, inches = ft_in_str.split(/['"]/i)
      ht_in = 12 * ft.to_i + inches.to_i
    end

    write_attribute(:seeking_maximum_height_in, ht_in)
  end

  def seeking_maximum_height_in=(value); end

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

  def mutual_friends_count(logged_in_profile)
    return 0 if self.uuid == logged_in_profile.uuid
    return 0 if self.facebook_authentication.blank?

    logged_in_profile.facebook_authentication.mutual_friends_count(self.facebook_authentication.oauth_uid)
  rescue StandardError => e
    0
  end
end
