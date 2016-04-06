class DateSuggestion < ActiveRecord::Base
  # include JsonbAttributeHelpers

  belongs_to :conversation
  belongs_to :date_place

  NUM_SUGGESTIONS = 3
  TIME_WINDOWS = {
    "Coffee" => "Afternoon/Evening, 4-6pm",
    "Brunch" => "Mid-morning, 11am - 2pm",
    "Dinner" => "Evening, 8-10pm",
    "Activities" => "Varies"
  }

  ATTRIBUTES = {
    day_of_week: :date,
    type_of_date: :string,
    formatted_suggestion: :string
  }

  # store_accessor :properties, *(ATTRIBUTES.keys.map(&:to_sym))
  # jsonb_attr_helper :properties, ATTRIBUTES
  jsonb_accessor :properties, ATTRIBUTES

  before_save :format_suggestion_string

  def time_window
    TIME_WINDOWS[self.type_of_date]
  end

  def format_day_of_week
    day =
      if (self.day_of_week - Date.today).to_i == 1
        'tomorrow'
      elsif (self.day_of_week - Date.today).to_i == 0
        'today'
      elsif (self.day_of_week - Date.today).to_i >= 7
        "next " + self.day_of_week.strftime("%A")
      elsif (self.day_of_week.wday < Date.today.wday)
        "next " + self.day_of_week.strftime("%A")
      elsif (self.day_of_week.wday > Date.today.wday)
        "on " + self.day_of_week.strftime("%A")
      end
  end

  private

  def format_suggestion_string
    self.formatted_suggestion =
    case self.type_of_date
    when "Coffee"
      "Want to meet for Coffee at #{date_place.name} #{self.format_day_of_week}?"
    when "Brunch"
      "Want to meet for Brunch at #{date_place.name} #{self.format_day_of_week}?"
    when "Dinner"
      "Want to meet for Dinner at #{date_place.name} #{self.format_day_of_week}?"
    when "Activities"
      "How does #{date_place.name} sound on #{self.format_day_of_week}?"
    end
  end
end
