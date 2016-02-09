json.(profile, :uuid, :email, :firstname, :lastname, :age, :born_on_year, :born_on_month, :born_on_day, :gender, :intent, :intent_text, :height, :profession, :faith, :highest_degree, :schools_attended, :location_city, :location_country, :date_preferences, :state, :incomplete, :incomplete_fields)
json.mutual_friends_count profile.mutual_friends_count(current_profile)
json.about_me_details do
  json.array! profile.about_me_order do |attr_name|
    json.attribute attr_name
    json.label profile.send("#{attr_name}_label")
    json.value profile.send(attr_name.to_sym)
  end
end
json.partial! 'api/v1/photos/photos', photos: profile.photos.valid
