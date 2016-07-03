json.data do
  json.headline homescreen_headline
  json.subheadline homescreen_subheadline
  json.content_type @content_type
  if @content_type == 'text'
    json.title "Friends Don't Let Friends Be Single"
    json.body "#{current_profile.firstname}, wouldn't it be awesome if more people like you were on ekCoffee? :)\r\n\r\nDo you know the best way for us to reach them? Through you!\r\n\r\nHave you told a friend about us?"
  elsif @content_type == 'link'
    json.title "Fancy a brunch with other singles?"
    json.body "Grab your umbrellas and beat the monsoons with warm waffles and some laughs with a fellow group of interesting singles from Mumbai!\r\n\r\nYour first coffee is on us!"
    json.cta_button_title "RSVP - Grandmama's Cafe, Sunday July 10th"
    json.cta_url @link_url
  end
end
json.partial! 'api/v1/shared/auth'
