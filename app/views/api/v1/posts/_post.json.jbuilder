json.post_id post.id
json.title post.title
json.excerpt post.excerpt
json.type post.type
json.image_public_id post.image_public_id
json.posted_on post.posted_on.strftime("%A, %b ") + post.posted_on.day.ordinalize + post.posted_on.strftime(" %Y")

if post.video?
  json.video_url post.video_url
end

if post.article?
  json.link_to_url post.link_to_url
end

json.share_text post.default_share_text
