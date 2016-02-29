/*

CLIENT-SIDE
Setup:


When device detects connected state:
1. set disconnectedAt to false

FIREBASE-SIDE
When server notices device is disconnected:
1. set disconnectedAt to timestamp

SERVER-SIDE
When child_changed on /conversations:
1. get disConnectedAt time for
find all messages that are >
when child_added to /messages list,

*/


var Firebase = require('firebase');
var FirebaseTokenGenerator = require("firebase-token-generator");
// var cluster = require('cluster');
var AWS = require('aws-sdk');

var tokenGenerator = new FirebaseTokenGenerator("da9HWjJ8UIE0gLhSCk2auIjZYDmIpm4VSPmVUZyV");
var token = tokenGenerator.createToken({ uid: '' }); // auth with no uuid

ref = new Firebase('https://glaring-fire-5389.firebaseio.com/');
ref.authWithCustomToken(token, function(error, authData) {
  if (error) {
    console.log("login failed!", error);
  } else {
    console.log(" login succeeded!");
  }
});

var conversationsRef = new Firebase('https://glaring-fire-5389.firebaseio.com/conversations');

// doing anything with this?
// conversationsRef.on('child_added', function(snapshot) {
//   console.log("new conversation started: " + snapshot.key());
// });

conversationsRef.on('child_changed', function(snapshot) {
  // auth with no uuid
  var token = tokenGenerator.createToken({ uid: '' });
  ref = new Firebase('https://glaring-fire-5389.firebaseio.com/');
  ref.authWithCustomToken(token, function(error, authData) {
    if (error) {
      console.log("login failed!", error);
    } else {
      console.log(" login succeeded!");
    }
  });

  console.log("new message in conversation " + snapshot.key());

  var conversation_uuid = snapshot.key();
  var participantsRef = new Firebase("https://glaring-fire-5389.firebaseio.com/conversations/" + conversation_uuid + "/metadata/participant_uuids");

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
          console.log(uuid + " - login succeeded!");
        }
      });

      connectionRef = new Firebase('https://glaring-fire-5389.firebaseio.com/users/' + uuid + '/disconnectedAt');
      connectionRef.once('value', function(snapshot) {
        var disconnectedAt = snapshot.val();
        if(disconnectedAt !== false) {
          console.log(uuid + ' disconected at ' + disconnectedAt);

          var messagesRef = new Firebase("https://glaring-fire-5389.firebaseio.com/conversations/" + conversation_uuid + "/messages");
          var query = messagesRef.orderByChild("sent_at").startAt(disconnectedAt).limitToLast(10);
          query.once("value", function(messages) {
            hasPendingMessages = false;
            messages.forEach(function(message) {
              console.log('content: ' + message.child("content").val());

              var recipient_uuid = message.child("recipient_uuid").val();
              if(recipient_uuid == uuid) {
                hasPendingMessages = true;
                // TBD: throw break exception
              }
            });
            if(hasPendingMessages) {
              console.log("HAS PENDING MESSAGES!!!");
              // the disconnected user has messages since being disconnected
              // CHECK THAT THE CONV. IS STILL OPEN AND THEN SEND PUSH NOTIFICATIONS
              // TBD: Send push notification here!
            }
          });
        }
      });
    });
  });
});
