json.data do
  json.headline homescreen_headline
  json.subheadline homescreen_subheadline
  json.content_type @content_type
  if @content_type == 'text'
    json.title "Friends Don't Let Friends Be Single"
    json.body "#{current_profile.firstname}, wouldn't it be awesome if more people like you were on ekCoffee? :)\r\n\r\nDo you know the best way for us to reach them? Through you!\r\n\r\nHave you told a friend about us?"
  elsif @content_type == 'link'
    json.title "Announcing, ekCoffee Socials"
    json.body "Don't you sometimes wish you could meet more singles over an activity that you enjoy doing? \r\n\r\nIf so, we've got just the thing for you. ekCoffee Socials is a new way for you to meet singles in a group. Post an activity or join one and meet interesting people while doing something fun!"
    json.cta_button_title "Learn More"
    json.cta_url @link_url
  end
end
json.partial! 'api/v1/shared/auth'
