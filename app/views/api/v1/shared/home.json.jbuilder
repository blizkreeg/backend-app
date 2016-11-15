json.cache!([@content_type, @cta_title, @cta_content, @cta_button_title, @cta_url], expires_in: 24.hours) do
  json.data do
    json.headline homescreen_headline
    json.subheadline homescreen_subheadline
    json.content_type @content_type
    if @content_type == 'text'
      json.title @cta_title
      json.body @cta_content
    elsif @content_type == 'link'
      json.title @cta_title
      json.body @cta_content
      json.cta_button_title @cta_button_title
      json.cta_url @cta_url
    end
  end
end
json.partial! 'api/v1/shared/auth'
