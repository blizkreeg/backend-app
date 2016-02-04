json.(profile, :uuid, :email, :firstname, :lastname, :age, :born_on_year, :born_on_month, :born_on_day, :gender, :intent, :intent_text, :height, :profession, :faith, :highest_degree, :schools_attended, :location_city, :location_country, :date_preferences)
json.partial! 'api/v1/photos/photos', photos: profile.photos.valid
