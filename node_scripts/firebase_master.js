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
exec("echo '" + process.pid + "' > tmp/pids/firebase_master.pid");

var tokenGenerator = new FirebaseTokenGenerator(process.env.FIREBASE_SECRET);
var token = tokenGenerator.createToken({ uid: '' }); // auth with no uuid
var numCPUs = 4;
var quitProcess = false;

var conversationsRef = new Firebase(dbUrl + '/conversations');
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
