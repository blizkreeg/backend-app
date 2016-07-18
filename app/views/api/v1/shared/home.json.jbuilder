json.data do
  json.headline homescreen_headline
  json.subheadline homescreen_subheadline
  json.content_type @content_type
  if @content_type == 'text'
    json.title "Friends Don't Let Friends Be Single"
    json.body "#{current_profile.firstname}, wouldn't it be awesome if more people like you were on ekCoffee? :)\r\n\r\nDo you know the best way for us to reach them? Through you!\r\n\r\nHave you told a friend about us?"
  elsif @content_type == 'link'
    json.title "How We Spent Our Sunday"
    json.body "This past Sunday we hosted our fourth popular Singles That Brunch event at The Bombay Canteen. It was a great group of singles and everyone had a fun time! Here are some photos from the event."
    json.cta_button_title "Photos from our recent brunch"
    json.cta_url @link_url
  end
end
json.partial! 'api/v1/shared/auth'
