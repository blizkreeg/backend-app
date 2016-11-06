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

  def rsvped_to_brew?(brew)
    self.brews.where(id: brew.id).exists?
  end
end
