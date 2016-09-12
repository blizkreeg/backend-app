module ProfileBrewHelper
  extend ActiveSupport::Concern

  def upcoming_brews
    Event.current_or_future_events#.min_age_lte(self.age).max_age_gte(self.age)
  end
end
