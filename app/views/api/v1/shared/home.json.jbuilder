json.data do
  json.headline homescreen_headline
  json.subheadline homescreen_subheadline
  json.content_type @content_type
  if @content_type == 'text'
    json.title "Friends Don't Let Friends Be Single"
    json.body "#{current_profile.firstname}, wouldn't it be awesome if more people like you were on ekCoffee? :)\r\n\r\nDo you know the best way for us to reach them? Through you!\r\n\r\nHave you told a friend about us?"
  elsif @content_type == 'link'
    json.title @cta_title
    json.body @cta_content
    json.cta_button_title @cta_button_title
    json.cta_url @cta_url
  end
end
json.partial! 'api/v1/shared/auth'
