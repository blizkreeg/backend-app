json.data do
  json.array! @conversation.date_suggestions do |date_suggestion|
    json.day_of_week date_suggestion.day_of_week.strftime "%A, #{date_suggestion.day_of_week.day.ordinalize} %B"
    json.type_of_date date_suggestion.type_of_date
    json.time_window date_suggestion.time_window
    json.formatted_suggestion date_suggestion.formatted_suggestion
    json.place do
      json.partial! 'api/v1/date_places/date_place', date_place: date_suggestion.date_place
    end
  end
end
