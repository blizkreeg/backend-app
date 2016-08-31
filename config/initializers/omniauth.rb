OmniAuth.config.logger = EKC.logger

FACEBOOK_APP_ID =
case Rails.env
when "development"
  "10153059890934253"
when "production"
  "257207614252"
when "test"
  "10153123223159253"
end


FACEBOOK_APP_SECRET =
case Rails.env
when "development"
  "bb4f4ccefe30d3dd2d777ef66f402bdb"
when "production"
  "bd8409e26e736da28d06add8ee47ba28"
when "test"
  "ac3b7517145770a96392006051bf249d"
end

case Rails.env
when "development"
  # OmniAuth.config.full_host = "http://localhost:3000"
when "production"
  OmniAuth.config.full_host = "https://admin.ekcoffee.com"
when "test"
  OmniAuth.config.full_host = "https://test-app.ekcoffee.com"
end

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :facebook, FACEBOOK_APP_ID, FACEBOOK_APP_SECRET,
           :scope => 'email,public_profile,user_friends,user_photos,user_birthday,user_education_history,user_work_history,user_relationships',
           :display => 'page',
           :image_size => 'large',
           :info_fields => 'id, birthday, education, email, first_name, last_name, gender, location, relationship_status, work'
end
