json.data do
  if @content_type == 'text'
    json.title "Section title"
    json.body "Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book."
  elsif @content_type == 'link'
    json.title "Link title"
    json.body "Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when..."
    json.cta_button_title "Click on this"
    json.cta_url "http://ekcoffee.com"
  elsif @content_type == 'none'
    json.null!
  end
end
json.partial! 'api/v1/shared/auth'
