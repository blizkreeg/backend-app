json.cache! profile, expires_in: 24.hours do
  json.(profile, :uuid, :email, :firstname, :lastname, :age, :born_on_year, :born_on_month, :born_on_day, :gender, :intent, :intent_text, :height, :profession, :faith, :highest_degree, :schools_attended, :employer_name, :location_city, :location_country, :date_preferences, :state, :incomplete, :incomplete_fields, :inactive, :seeking_minimum_age, :seeking_maximum_age, :seeking_minimum_height, :seeking_maximum_height, :seeking_faith, :disable_notifications_setting, :butler_conversation_uuid)
  json.about_me_details do
    json.array! profile.about_me_order do |attr_name|
      json.attribute attr_name
      json.label profile.send("#{attr_name}_label")
      json.value profile.send(attr_name.to_sym)
    end
  end
  json.partial! 'api/v1/photos/photos', photos: profile.photos.approved.ordered
end

if defined?(match) && match.present?
  json.mutual_friends_count match.num_common_friends
else
  json.mutual_friends_count 0
end
