var Queue = require('firebase-queue'),
    Firebase = require('firebase'),
    FirebaseTokenGenerator = require("firebase-token-generator"),
    unirest = require('unirest');;

var dbUrl;

if(process.env.RAILS_ENV == 'development') {
  dbUrl = 'https://glaring-fire-5389.firebaseio.com';
}
else if(process.env.RAILS_ENV == 'test') {
  dbUrl = 'https://glaring-fire-5389.firebaseio.com';
}
else if(process.env.RAILS_ENV == 'production') {
  dbUrl = 'https://ekcoffee-production.firebaseio.com';
}

var tokenGenerator = new FirebaseTokenGenerator(process.env.FIREBASE_SECRET);
var token = tokenGenerator.createToken({ uid: '' }); // auth with no uuid

var quitProcess = false;

console.log('connected to ' + dbUrl);

var queueRef = new Firebase(dbUrl + '/queue');
var queue = new Queue(queueRef, function(data, progress, resolve, reject) {
  // Update the progress state of the task
  setTimeout(function() {
    progress(50);
  }, 500);

  metadataRef = new Firebase(dbUrl + "/conversations/" + data.conversation_uuid + "/metadata");
  metadataRef.once("value", function(metadata) {
    var conversationOpen = metadata.child("open").val();
    if(conversationOpen === true) {
      var participantsRef = new Firebase(dbUrl + "/conversations/" + data.conversation_uuid + "/metadata/participant_uuids");
      participantsRef.once('value', function(participants) {
        // check if either of the participants are disconnected
        participants.forEach(function(participant) {
          var uuid = participant.val();
          var token = tokenGenerator.createToken({ uid: uuid });

          // auth with the uuid
          ref = new Firebase(dbUrl + '/');
          ref.authWithCustomToken(token, function(error, authData) {
            if (error) {
              console.log(uuid + "- login failed!", error);
            } else {
              // console.log(uuid + " - login succeeded!");
            }
          });

          connectionRef = new Firebase(dbUrl + '/users/' + uuid + '/disconnectedAt');
          connectionRef.once('value', function(snapshot) {
            var disconnectedAt = snapshot.val();
            if(disconnectedAt !== false) {
              // console.log(uuid + ' disconected at ' + disconnectedAt);
              var messagesRef = new Firebase(dbUrl + "/conversations/" + data.conversation_uuid + "/messages");
              var query = messagesRef.orderByChild("sent_at").startAt(disconnectedAt).limitToLast(10);
              var sentLastPushNotificationAt = metadata.child('sent_push_to_' + uuid).val();
              if(sentLastPushNotificationAt > disconnectedAt) {
                // we've already sent push notification of a message since the user disconnected. let's not spam them.
                // console.log('user disconnected ' + (sentLastPushNotificationAt - disconnectedAt)/1000 + 's ago; not sending push notification');
                return;
              }
              query.once("value", function(messages) {
                var hasPendingMessages = false;
                var BreakException = {};
                var senderName = null;
                var mostRecentMessage = null;
                try {
                  messages.forEach(function(message) {
                    // console.log('content: ' + message.child("content").val());
                    var recipient_uuid = message.child("recipient_uuid").val();

                    if(recipient_uuid == uuid) {
                      var sender_uuid = message.child("sender_uuid").val();
                      senderName = metadata.child(sender_uuid + "_firstname").val();
                      mostRecentMessage = message.child("content").val();
                      hasPendingMessages = true;
                      // console.log('message from: ' + senderName + ', message: ' + mostRecentMessage);
                      // throw BreakException;
                    }
                  });
                } catch(e) {
                  if(e !== BreakException) {
                    throw e;
                  }
                }
                if(hasPendingMessages) {
                  // console.log("has pending messages from" + senderName);
                  // the disconnected user has messages since being disconnected
                  unirest.post(process.env.HOST_URL + '/v1/accounts/send-push-notification')
                  .headers({'Accept': 'application/json', 'Content-Type': 'application/json'})
                  .send({ "data": { "single_user": true, "uuid": uuid, "notification_type": "new_conversation_message", "notification_params": { name: senderName, title: senderName, body: mostRecentMessage } } })
                  .end(function (response) {
                    if(response.status == 200) {
                      metadataRef.child('sent_push_to_' + uuid).set((new Date).getTime());
                      console.log("sent 'new_conversation_message' push notification to " + uuid + '; title=' + senderName + '; body=' + mostRecentMessage);

                      if(quitProcess) {
                        process.exit();
                      }
                    } else {
                      console.log(response.status);
                      console.log(response.body);
                    }
                  });
                }
              });
            }
          });
        });
      });
    }
  });

  // Finish the job asynchronously
  setTimeout(function() {
    resolve();
  }, 1000);
});

process.on('SIGTERM', function() {
  quitProcess = true;
  setTimeout(function() {
    console.log('waited 2s...killing process');
    process.exit();
  }, 2000);
});
