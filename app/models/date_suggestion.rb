class DateSuggestion < ActiveRecord::Base
  # include JsonbAttributeHelpers

  belongs_to :conversation
  belongs_to :date_place

  NUM_SUGGESTIONS = 4
  TIME_WINDOWS = {
    "Coffee" => "Afternoon/Evening, 4-6pm",
    "Brunch" => "Mid-morning, 11am - 2pm",
    "Dinner" => "Evening, 8-10pm",
    "Activities" => "Varies"
  }

  ASK_STRINGS = {
    "Coffee" => ['Want to meet for coffee', 'Want to get a coffee', 'Want to go for a coffee'],
    "Brunch" => ['Want to meet for brunch', 'Want to get brunch'],
    "Dinner" => ['Want to meet for dinner', 'How does dinner sound'],
    "Activities" => ['How about']
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

  def self.weekend_days(date=nil)
    week_of = date
    day = date.wday
    if day > 0 && day < 5 # M - Th
      suggest_idx = 2
    elsif day == 5
      suggest_idx = 1
    elsif day == 6
      suggest_idx = 0
    else
      week_of = date + 1.day
      suggest_idx = 2
    end

    (0..suggest_idx).to_a.map { |idx| week_of.end_of_week - idx.days }.reverse
  end

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
    if %w(Coffee Brunch Dinner).include?(self.type_of_date)
      ASK_STRINGS[self.type_of_date].sample + " at #{date_place.name} #{self.format_day_of_week}?"
    elsif self.type_of_date == "Activities"
      ASK_STRINGS[self.type_of_date].sample + " #{date_place.name} #{self.format_day_of_week}?"
    end
  end
end
