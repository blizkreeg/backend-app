json.(profile, :uuid, :email, :firstname, :lastname, :age, :born_on_year, :born_on_month, :born_on_day, :gender, :intent, :height, :profession, :faith, :highest_degree, :location_city, :location_country)
json.partial! 'api/v1/photos/photos', photos: profile.photos.valid
