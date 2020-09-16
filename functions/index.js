const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { topic } = require("firebase-functions/lib/providers/pubsub");
admin.initializeApp();

// exports.onFeedCreated = functions.firestore
//   .document("/feed/{userUid}/feedItems/{feedID}")
//   .onCreate((snapshot, context) => {
//     console.log("feeed item is created " + userUid);
//     let userUid = context.params.userUid;
//     // const feedID = context.feedID;
//     let feedData = snapshot.data();

//     let body = "";

//     if (feedData.type === "follow") {
//       body = "starting following you...";
//     } else if (feedData.type === "like") {
//       body = "likes your Post...";
//     } else if (feedData.type === "comment") {
//       body = "reply on your Post...";
//     }

//     admin.messaging().sendToTopic(userUid, {
//       notification: {
//         title: "feedData.username",
//         body: "body",
//         clickAction: "FLUTTER_NOTIFICATION_CLICK",
//       },
//     });
//   });

// exports.onFeedActivityCreated = functions.firestore
//   .document("feed/{userID}/feedItems/{feedID}")
//   .onCreate((snapshot, context) => {
//     let userID = context.params.userID;
//     console.log("feeed item is created " + userID);
//     const feedData = snapshot.data();
//     let body = "";

//     if (feedData.type === "follow") {
//       body = "starting following you...";
//     } else if (feedData.type === "like") {
//       body = "likes your Post...";
//     } else if (feedData.type === "comment") {
//       body = "reply on your Post...";
//     }

//     return admin.messaging().sendToTopic(userID, {
//       notification: {
//         title: userID,
//         body: body,
//         clickAction: "FLUTTER_NOTIFICATION_CLICK",
//       },
//     });

//     // return admin.messaging.sendToTopic(to,userID,{

//   // });
// });
