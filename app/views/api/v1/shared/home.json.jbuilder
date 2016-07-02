json.data do
  json.headline homescreen_headline
  json.subheadline homescreen_subheadline
  json.content_type @content_type
  if @content_type == 'text'
    json.title "Friends Don't Let Friends Be Single"
    json.body "#{current_profile.firstname}, wouldn't it be awesome if more people like you were on ekCoffee? :)\r\n\r\nDo you know the best way for us to reach them? Through you!\r\n\r\nHave you told a friend about us?"
  elsif @content_type == 'link'
    json.title "Singles That Brunch"
    json.body "Singles That Brunch is a weekly brunch event where you'll meet interesting singles from your city.\r\n\r\nJoin us over brunch and meet new people in real life! Just show up, we'll make the rest happen :-)"
    json.cta_button_title "See Upcoming Brunches"
    json.cta_url @link_url
  end
end
json.partial! 'api/v1/shared/auth'
