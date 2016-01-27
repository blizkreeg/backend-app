json.photos do
  json.array! photos do |photo|
    json.partial! 'api/v1/photos/photo', photo: photo
  end
end
