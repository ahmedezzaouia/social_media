import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/pages/post_screen.dart';
import 'package:fluttershare/pages/profile.dart';
import 'package:fluttershare/widgets/custom_image.dart';
import 'package:fluttershare/widgets/header.dart';
import 'package:fluttershare/widgets/progress.dart';
import 'package:timeago/timeago.dart' as timeago;

class ActivityFeed extends StatefulWidget {
  @override
  _ActivityFeedState createState() => _ActivityFeedState();
}

class _ActivityFeedState extends State<ActivityFeed> {
  Stream<List<ActivityFeedItem>> getActivityFeed() {
    return feedActivityRef
        .document(currentUser.id)
        .collection('feedItems')
        .orderBy('timestamp', descending: true)
        .limit(30)
        .snapshots()
        .map((snapshot) => snapshot.documents
            .map((_doc) => ActivityFeedItem.fromDocument(_doc))
            .toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueAccent[700],
      appBar: header(context, titleText: "Activity Feed"),
      body: Container(
          child: StreamBuilder<List<ActivityFeedItem>>(
        stream: getActivityFeed(),
        builder: (context, snapshot) {
          resetNotificationCount();
          if (!snapshot.hasData) {
            return circularProgress();
          } else if (snapshot.data.isEmpty) {
            return Container(
              color: Colors.blue[500],
              width: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    height: 150,
                    width: 150,
                    child: cachedNetworkImage(
                        'https://www.nobossextensions.com/images/extensions/icons/noboss-extensions-notices.png'),
                  ),
                  Text(
                    'there is no \n notification here',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
                ],
              ),
            );
          }
          return ListView(
            children: snapshot.data,
          );
        },
      )),
    );
  }
}

// Widget mediaPreview;
String activityItemText;

class ActivityFeedItem extends StatelessWidget {
  final String username;
  final String userId;
  final String type; // 'like', 'follow', 'comment'
  final String mediaUrl;
  final String postId;
  final String userProfileUrl;
  final String commentData;
  final Timestamp timestamp;

  ActivityFeedItem({
    this.username,
    this.userId,
    this.type,
    this.mediaUrl,
    this.postId,
    this.userProfileUrl,
    this.commentData,
    this.timestamp,
  });

  factory ActivityFeedItem.fromDocument(DocumentSnapshot doc) {
    return ActivityFeedItem(
      username: doc['username'],
      userId: doc['userId'],
      type: doc['type'],
      postId: doc['postId'],
      userProfileUrl: doc['userProfileUrl'],
      commentData: doc['comment'],
      timestamp: doc['timestamp'],
      mediaUrl: doc['mediaUrl'],
    );
  }

  configureMediaPreview() {
    // if (type == "like" || type == 'comment') {
    //   mediaPreview = GestureDetector(
    //     onTap: () => print('showing post'),
    //     child: Container(
    //       height: 50.0,
    //       width: 50.0,
    //       child: AspectRatio(
    //           aspectRatio: 16 / 9,
    //           child: Container(
    //             decoration: BoxDecoration(
    //               image: DecorationImage(
    //                 fit: BoxFit.cover,
    //                 image: CachedNetworkImageProvider(mediaUrl),
    //               ),
    //             ),
    //           )),
    //     ),
    //   );
    // } else {
    //   mediaPreview = Text('');
    // }

    if (type == 'like') {
      activityItemText = "liked your post";
    } else if (type == 'follow') {
      activityItemText = "is following you";
    } else if (type == 'comment') {
      activityItemText = 'replied: $commentData';
    } else {
      activityItemText = "Error: Unknown type '$type'";
    }
  }

  showPost(BuildContext _context) {
    Navigator.push(
      _context,
      MaterialPageRoute(
        builder: (ctx) => PostScreen(
          postId: postId,
          postOwner: currentUser.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    configureMediaPreview();

    return Padding(
      padding: EdgeInsets.only(bottom: 2.0),
      child: Container(
        color: Colors.white,
        child: ListTile(
          title: GestureDetector(
            onTap: () => showProfile(context, profileId: userId),
            child: RichText(
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                  style: TextStyle(
                    fontSize: 14.0,
                    color: Colors.black,
                  ),
                  children: [
                    TextSpan(
                      text: username,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: ' $activityItemText',
                    ),
                  ]),
            ),
          ),
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(userProfileUrl),
          ),
          subtitle: Text(
            timeago.format(timestamp.toDate()),
            overflow: TextOverflow.ellipsis,
          ),
          trailing: type != 'follow'
              ? GestureDetector(
                  onTap: () => showPost(context),
                  child: CachedNetworkImage(
                    imageUrl: mediaUrl,
                    height: 50,
                    width: 50,
                    fit: BoxFit.cover,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

showProfile(BuildContext _context, {String profileId}) {
  Navigator.push(
    _context,
    MaterialPageRoute(
      builder: (ctx) => Profile(profileId: profileId),
    ),
  );
}
