json.data do
  json._meta do
    json.partial! 'api/v1/posts/meta', posts: @posts
  end
  json.items do
    json.array! @posts do |post|
      json.partial! 'api/v1/posts/post', post: post
    end
  end
end

json.partial! 'api/v1/shared/auth'
