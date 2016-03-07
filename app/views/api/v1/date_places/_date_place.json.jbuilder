json.(date_place, :id, :name, :street_address, :part_of_city, :city, :price_range)
json.num_dates date_place.real_dates.count
json.photos do
  json._meta do
    json.partial! 'api/v1/photos/meta'
  end
  json.public_ids date_place.photos_public_ids
end
