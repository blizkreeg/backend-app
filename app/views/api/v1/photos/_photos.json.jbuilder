json.photos do
  json._meta do
    json.public_host 'http://res.cloudinary.com/ekcoffee/image/upload/'
    json.transformations do
      json.thumbnail 'c_thumb,g_face:center,r_max'
      json.profile 'c_fill,g_faces:center'
      json.fullscreen 'c_fill,g_faces:center'
    end
  end
  json.items do
    json.array! photos do |photo|
      json.partial! 'api/v1/photos/photo', photo: photo
    end
  end
end
