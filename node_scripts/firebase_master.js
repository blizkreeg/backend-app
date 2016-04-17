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

var Queue = require('firebase-queue'),
    Firebase = require('firebase'),
    FirebaseTokenGenerator = require("firebase-token-generator");
// var cluster = require('cluster');

var tokenGenerator = new FirebaseTokenGenerator("da9HWjJ8UIE0gLhSCk2auIjZYDmIpm4VSPmVUZyV");
var token = tokenGenerator.createToken({ uid: '' }); // auth with no uuid
var numCPUs = 4;
var quitProcess = false;

// if(cluster.isMaster) {
//   var conversationsRef = new Firebase('https://glaring-fire-5389.firebaseio.com/conversations');

//   for (var i = 0; i < numCPUs; i++) {
//     worker = cluster.fork();
//     worker.on('message', function(message) {

//     });
//   }
// } else {

// }

var conversationsRef = new Firebase('https://glaring-fire-5389.firebaseio.com/conversations');
var taskRef = new Firebase("https://glaring-fire-5389.firebaseio.com/queue/tasks");

conversationsRef.on('child_changed', function(snapshot) {
  // auth with no uuid
  var token = tokenGenerator.createToken({ uid: '' });
  ref = new Firebase('https://glaring-fire-5389.firebaseio.com/');
  ref.authWithCustomToken(token, function(error, authData) {
    if (error) {
      console.log("login failed!", error);
    } else {
      // console.log(" login succeeded!");
    }
  });

  var conversation_uuid = snapshot.key();
  console.log("new message in conversation " + conversation_uuid);
  taskRef.push({
    type: 'conversation_changed',
    'conversation_uuid': conversation_uuid
  });

  if(quitProcess) {
    process.exit();
  }
});

// doing anything with this?
// conversationsRef.on('child_added', function(snapshot) {
//   console.log("new conversation started: " + snapshot.key());
// });

process.on('SIGTERM', function() {
  quitProcess = true;
  setTimeout(function() {
    console.log('waited 1s...killing process');
    process.exit();
  }, 1000);
});
