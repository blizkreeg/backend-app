json.public_host Constants::CLOUDINARY_HOST_URL
json.transformations do
  json.thumbnail Photo::THUMBNAIL_TRANSFORMATIONS
  json.profile Photo::PROFILE_TRANSFORMATIONS
  json.fullscreen Photo::FULLSCREEN_TRANSFORMATIONS
end
