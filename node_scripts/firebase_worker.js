var Queue = require('firebase-queue'),
    Firebase = require('firebase'),
    FirebaseTokenGenerator = require("firebase-token-generator"),
    unirest = require('unirest');;

var tokenGenerator = new FirebaseTokenGenerator("da9HWjJ8UIE0gLhSCk2auIjZYDmIpm4VSPmVUZyV");
var token = tokenGenerator.createToken({ uid: '' }); // auth with no uuid

var queueRef = new Firebase('https://glaring-fire-5389.firebaseio.com/queue');
var queue = new Queue(queueRef, function(data, progress, resolve, reject) {
  // Update the progress state of the task
  setTimeout(function() {
    progress(50);
  }, 500);

  metadataRef = new Firebase("https://glaring-fire-5389.firebaseio.com/conversations/" + data.conversation_uuid + "/metadata");
  metadataRef.once("value", function(metadata) {
    var conversationOpen = metadata.child("open").val();
    if(conversationOpen === true) {
      var participantsRef = new Firebase("https://glaring-fire-5389.firebaseio.com/conversations/" + data.conversation_uuid + "/metadata/participant_uuids");
      participantsRef.once('value', function(participants) {
        // check if either of the participants are disconnected
        participants.forEach(function(participant) {
          var uuid = participant.val();
          var token = tokenGenerator.createToken({ uid: uuid });

          // auth with the uuid
          ref = new Firebase('https://glaring-fire-5389.firebaseio.com/');
          ref.authWithCustomToken(token, function(error, authData) {
            if (error) {
              console.log(uuid + "- login failed!", error);
            } else {
              // console.log(uuid + " - login succeeded!");
            }
          });

          connectionRef = new Firebase('https://glaring-fire-5389.firebaseio.com/users/' + uuid + '/disconnectedAt');
          connectionRef.once('value', function(snapshot) {
            var disconnectedAt = snapshot.val();
            if(disconnectedAt !== false) {
              // console.log(uuid + ' disconected at ' + disconnectedAt);
              var messagesRef = new Firebase("https://glaring-fire-5389.firebaseio.com/conversations/" + data.conversation_uuid + "/messages");
              var query = messagesRef.orderByChild("sent_at").startAt(disconnectedAt).limitToLast(10);
              query.once("value", function(messages) {
                var hasPendingMessages = false;
                var BreakException = {};
                var senderName = null;
                try {
                  messages.forEach(function(message) {
                    // console.log('content: ' + message.child("content").val());
                    var recipient_uuid = message.child("recipient_uuid").val();

                    if(recipient_uuid == uuid) {
                      var sender_uuid = message.child("sender_uuid").val();
                      senderName = metadata.child(sender_uuid + "_firstname").val();
                      // console.log('sent by ' + senderName);
                      hasPendingMessages = true;
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
                  // CHECK THAT THE CONV. IS STILL OPEN AND THEN SEND PUSH NOTIFICATIONS
                  // TBD: Send push notification here!
                  unirest.post(process.env.HOST_URL + '/v1/accounts/send-push-notification')
                  .headers({'Accept': 'application/json', 'Content-Type': 'application/json'})
                  .send({ "data": { "single_user": true, "uuid": uuid, "notification_type": "new_conversation_message", "notification_params": { name: senderName } } })
                  .end(function (response) {
                    if(response.status == 200) {
                      console.log("sent 'new_conversation_message' push notification to " + uuid);
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
