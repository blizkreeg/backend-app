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
end
