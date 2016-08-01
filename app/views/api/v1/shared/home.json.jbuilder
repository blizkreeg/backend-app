json.data do
  json.headline homescreen_headline
  json.subheadline homescreen_subheadline
  json.content_type @content_type
  if @content_type == 'text'
    json.title "Friends Don't Let Friends Be Single"
    json.body "#{current_profile.firstname}, wouldn't it be awesome if more people like you were on ekCoffee? :)\r\n\r\nDo you know the best way for us to reach them? Through you!\r\n\r\nHave you told a friend about us?"
  elsif @content_type == 'link'
    json.title "Singles That Brunch is back!"
    json.body "We're back with the fith edition of Singles That Brunch. This coming Sunday, we're hosting our popular singles brunch at Desi Deli in Bandra (W). This is a very cute and cozy establishment! You're going to love this one!"
    json.cta_button_title "RSVP for Singles Brunch at Desi Deli"
    json.cta_url @link_url
  end
end
json.partial! 'api/v1/shared/auth'
