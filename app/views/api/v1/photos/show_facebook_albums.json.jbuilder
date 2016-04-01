json.data do
  json.items do
    json.array! @facebook_albums do |album|
      json.id album['id']
      json.name album['name']
      if album['cover_photo'].blank?
        json.cover_photo_url nil
      else
        json.cover_photo_url @current_profile.facebook_authentication.get_photo(album['cover_photo'])['source']
      end
    end
  end
end

json.partial! 'api/v1/shared/auth'
