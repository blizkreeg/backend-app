json.data do
  json.headline homescreen_headline
  json.subheadline homescreen_subheadline
  json.content_type @content_type
  if @content_type == 'text'
    json.title "Friends Don't Let Friends Be Single"
    json.body "#{current_profile.firstname}, wouldn't it be awesome if more people like you were on ekCoffee? :)\r\n\r\nDo you know the best way for us to reach them? Through you!\r\n\r\nHave you told a friend about us?"
  elsif @content_type == 'link'
    json.title "Singles That Brunch is in Pune!"
    json.body "Pune folks, meet interesting singles from your city over a delicious Sunday Brunch! After five events in Mumbai, we are bringing our popular Singles That Brunch series to your city! ☕ 🍽 \r\n\r\nThis coming Sunday, we're hosting our first one in Pune at Elephant & Co in Kalyani Nagar. We saw this place and instantly fell in love with it. You will too!"
    json.cta_button_title "Get Your Brunch Ticket"
    json.cta_url @link_url
  end
end
json.partial! 'api/v1/shared/auth'
