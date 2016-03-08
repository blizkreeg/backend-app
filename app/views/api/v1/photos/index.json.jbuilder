json.data do
  json._meta do
    json.partial! 'api/v1/photos/meta'
  end
  json.items do
    json.array! @photos do |photo|
      json.partial! 'api/v1/photos/photo', photo: photo
    end
  end
end

json.partial! 'api/v1/shared/auth'
