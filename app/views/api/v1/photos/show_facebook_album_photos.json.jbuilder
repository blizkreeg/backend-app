json.data do
  json.items do
    json.array! @album_photos do |photo|
      json.id photo['id']
      json.photo_url photo['images'].last['source']
    end
  end
end

json.partial! 'api/v1/shared/auth'
