json.(real_date, :meeting_day, :meeting_time, :post_date_rating, :post_date_feedback, :other_date_place_name)
json.date_profile do
  json.partial! 'api/v1/profiles/profile', profile: real_date.date_profile
end
json.date_place do
  if real_date.date_place.blank?
    json.null!
  else
    json.partial! 'api/v1/date_places/date_place', date_place: real_date.date_place
  end
end
