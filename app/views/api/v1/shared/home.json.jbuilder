json.data do
  json.headline homescreen_headline
  json.subheadline homescreen_subheadline
  json.content_type @content_type
  if @content_type == 'text'
    json.title "Friends Don't Let Friends Be Single"
    json.body "#{current_profile.firstname}, wouldn't it be awesome if more people like you were on ekCoffee? :)\r\n\r\nDo you know the best way for us to reach them? Through you!\r\n\r\nHave you told a friend about us?"
  elsif @content_type == 'link'
    json.title "EKCOFFEE EXPERIENCES"
    json.body "Do you have a hobby? A passion? An interest? It could be board games, trekking, book club, concerts, or something else. \r\n\r\nDo you wish you could meet other singles through it? Are you open to playing a host?\r\n\r\nGreat! Then we invite you to check out ekCoffee Singles Experiences."
    json.cta_button_title "I'm curious. Tell me more."
    json.cta_url @link_url
  end
end
json.partial! 'api/v1/shared/auth'
