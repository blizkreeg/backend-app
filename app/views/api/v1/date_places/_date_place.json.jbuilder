json.(date_place, :id, :name, :street_address, :part_of_city, :city, :price_range)
if date_place.real_dates.count > 0
  json.num_dates date_place.real_dates.count
else
  json.num_dates (1..5).to_a.sample
end
json.photos do
  json._meta do
    json.partial! 'api/v1/photos/meta'
  end
  json.public_ids date_place.photos_public_ids
end
