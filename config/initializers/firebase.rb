## Rules for indexing

# {
#     "rules": {
#       ".read": "true",
#       ".write": "true",
#       "queue": {
#         "tasks": {
#           ".indexOn": "_state"
#         }
#       },
#       "conversations": {
#         "$conversation_uuid": {
#           "messages": {
#             ".indexOn": "sent_at"
#           }
#         }
#       }
#     }
# }

## Rules for auth

# //{
# //    "rules": {
# //      ".read": "auth !== null",
# //      ".write": "auth !== null",
# //      "users": {
# //        "$uid": {
# //          ".read": "auth != null",
# //          ".write": "auth != null"
# //        }
# //      }
# //    }
# //}
# // && auth.uid == $uid
# //{
# //    "rules": {
# //      ".read": "auth !== null",
# //      ".write": "auth !== null",
# //      "users": {
# //        "$uid": {
# //          ".read": "auth != null && auth.uid == $uid",
# //          ".write": "auth != null && auth.uid == $uid"
# //        }
# //      }
# //    }
# //}

case Rails.env
when 'development'
  Rails.application.config.firebase_db_url = 'https://glaring-fire-5389.firebaseio.com/'
when 'test'
  Rails.application.config.firebase_db_url = 'https://glaring-fire-5389.firebaseio.com/'
when 'production'
  Rails.application.config.firebase_db_url = 'https://ekcoffee-production.firebaseio.com/'
end

# create conversations endpoint
c_uri = Rails.application.config.firebase_db_url + 'conversations'
butler_c_uri = Rails.application.config.firebase_db_url + 'butler-conversations'

$firebase_conversations = Firebase::Client.new(c_uri)
$firebase_butler_conversations = Firebase::Client.new(butler_c_uri)
