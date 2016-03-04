class DateSuggestion < ActiveRecord::Base
  belongs_to :conversation
  belongs_to :date_place

  NUM_SUGGESTIONS = 3
  TIME_WINDOWS = {
    "Coffee" => "Afternoon/Evening, 4-6pm",
    "Brunch" => "Mid-morning, 11am - 2pm",
    "Dinner" => "Evening, 8-10pm",
    "Activities" => "Varies"
  }

  PROPERTIES = {
    day_of_week: :date,
    type_of_date: :string
  }

  jsonb_accessor :properties, PROPERTIES

  def time_window
    TIME_WINDOWS[self.type_of_date]
  end
end
