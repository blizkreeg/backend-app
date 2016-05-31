json.data do
  json.headline homescreen_headline
  json.subheadline homescreen_subheadline
  json.content_type @content_type
  if @content_type == 'text'
    json.title "Section title"
    json.body "Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book."
  elsif @content_type == 'link'
    json.title "Singles That Brunch"
    json.body "Singles That Brunch is a weekly brunch event where you'll meet interesting singles from your city.\r\n\r\nJoin us over brunch and meet new people in real life! Just show up, we'll make the rest happen :-)"
    json.cta_button_title "See Upcoming Brunches"
    json.cta_url ENV['HOST_URL'] + "/rsvp-stb?uuid=#{@current_profile.uuid}"
  end
end
json.partial! 'api/v1/shared/auth'
