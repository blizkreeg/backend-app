json.id photo.id
json.url photo.url
json.width photo.width
json.height photo.height
json.primary photo.primary

json.sizes do
  json.set! '100x100', photo.properties["source"]
end
