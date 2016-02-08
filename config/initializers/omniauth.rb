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
when "production"
when "test"
  OmniAuth.config.full_host = "http://ekcoffee2-3000.terminal.com"
end

LINKEDIN_KEY = "75ou43ja7worou"
LINKEDIN_SECRET = "YUm2akI7ZrZPasUv"

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :facebook, FACEBOOK_APP_ID, FACEBOOK_APP_SECRET,
           :scope => 'email,public_profile,user_friends,user_photos,user_birthday,user_education_history,user_work_history',
           :display => 'page',
           :image_size => 'large',
           :info_fields => 'id, birthday, education, email, first_name, last_name, gender, location, relationship_status, work'
  provider :linkedin, LINKEDIN_KEY, LINKEDIN_SECRET,
           :scope => 'r_basicprofile',
           :fields => ["id", "first-name", "last-name", "educations", "num-connections", "positions", "headline", "industry",
                       "picture-url", "public-profile-url", "location"]
end
