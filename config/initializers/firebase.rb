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
  firebase_db_uri = 'https://glaring-fire-5389.firebaseio.com/'
when 'test'
  firebase_db_uri = 'https://glaring-fire-5389.firebaseio.com/'
when 'production'
  firebase_db_uri = 'https://ekcoffee-production.firebaseio.com/'
end

# create conversations endpoint
c_uri = firebase_db_uri + 'conversations'

$firebase_conversations = Firebase::Client.new(c_uri)
