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

console.log('connected to ' + dbUrl);

var Queue = require('firebase-queue'),
    Firebase = require('firebase'),
    FirebaseTokenGenerator = require("firebase-token-generator");

var sys = require('util')
var exec = require('child_process').exec;

console.log('process pid: ' + process.pid);
exec("echo '" + process.pid + "' > tmp/pids/firebase_butler_master.pid");

var tokenGenerator = new FirebaseTokenGenerator(process.env.FIREBASE_SECRET);
var token = tokenGenerator.createToken({ uid: '' }); // auth with no uuid
var quitProcess = false;

var conversationsRef = new Firebase(dbUrl + '/butler-conversations');
var taskRef = new Firebase(dbUrl + "/queue/tasks");

conversationsRef.on('child_changed', function(snapshot) {
  // auth with no uuid
  var token = tokenGenerator.createToken({ uid: '' });
  ref = new Firebase(dbUrl + '/');
  ref.authWithCustomToken(token, function(error, authData) {
    if (error) {
      console.log("login failed!", error);
    } else {
      // console.log(" login succeeded!");
    }
  });

  var conversation_uuid = snapshot.key();
  console.log("new message in conversation: " + conversation_uuid + '; adding to queue.');

  messagesRef = new Firebase(dbUrl + '/butler-conversations/' + conversation_uuid + '/messages');
  // getting two messages here for the forEach loop below - suboptimal
  // check if Firebase has function to get just one message
  messagesRef.orderByChild("processed").equalTo(null).limitToFirst(2).on('value', function(messages) {
    newMessages = messages.numChildren();
    if(newMessages > 0) {
      messages.forEach(function(message) {
        taskRef.push({
          type: 'new_butler_message',
          'profile_uuid': message.child("sender_uuid").val()
        });
      });
    }
  });

  if(quitProcess) {
    process.exit();
  }
});

process.on('SIGTERM', function() {
  quitProcess = true;
  setTimeout(function() {
    console.log('waited 1s...killing process');
    process.exit();
  }, 1000);
});
