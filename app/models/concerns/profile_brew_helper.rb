module ProfileBrewHelper
  extend ActiveSupport::Concern

  def upcoming_brews
    events = Event.current_or_future_events

    # staff sees all events w/ no filters
    unless self.staff_or_internal
      events = events.min_age_lte(self.age).max_age_gte(self.age)
    end

    events
  end

  def interested_in_brew?(brew)
    self.brews.merge(Brewing.interested).where(brews: { id: brew.id }).exists?
  end

  def going_to_brew?(brew)
    self.brews.merge(Brewing.going).where(brews: { id: brew.id }).exists?
  end
end
