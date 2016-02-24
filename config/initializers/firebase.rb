case Rails.env
when 'development'
  firebase_db_uri = 'https://glaring-fire-5389.firebaseio.com/'
when 'test'
  firebase_db_uri = 'https://glaring-fire-5389.firebaseio.com/'
when 'production'
  firebase_db_uri = 'https://glaring-fire-5389.firebaseio.com/'
end

# create conversations endpoint
c_uri = firebase_db_uri + 'conversations'

$firebase_conversations = Firebase::Client.new(c_uri)
