import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/activity_feed.dart';
import 'package:fluttershare/pages/comments.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/pages/profile.dart';
import 'package:fluttershare/provider/timeline_provider.dart';
import 'package:fluttershare/widgets/custom_image.dart';
import 'package:fluttershare/widgets/progress.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';

class Post extends StatefulWidget {
  final String postId;
  final String ownerId;
  final String username;
  final String location;
  final String description;
  final String mediaUrl;
  final dynamic likes;
  final Timestamp timestamp;

  Post({
    this.postId,
    this.ownerId,
    this.username,
    this.location,
    this.description,
    this.mediaUrl,
    this.likes,
    this.timestamp,
  });

  factory Post.fromDocument(DocumentSnapshot doc) {
    return Post(
      postId: doc['postId'],
      ownerId: doc['ownerId'],
      username: doc['username'],
      location: doc['location'],
      description: doc['description'],
      mediaUrl: doc['mediaUrl'],
      likes: doc['likes'],
      timestamp: doc['timestamp'],
    );
  }

  int getLikeCount(likes) {
    // if no likes, return 0
    if (likes == null) {
      return 0;
    }
    int count = 0;
    // if the key is explicitly set to true, add a like
    likes.values.forEach((val) {
      if (val == true) {
        count += 1;
      }
    });
    return count;
  }

  @override
  _PostState createState() => _PostState(
        postId: this.postId,
        ownerId: this.ownerId,
        username: this.username,
        location: this.location,
        description: this.description,
        mediaUrl: this.mediaUrl,
        likes: this.likes,
        likeCount: getLikeCount(this.likes),
      );
}

class _PostState extends State<Post> {
  final String postId;
  final String ownerId;
  final String username;
  final String location;
  final String description;
  final String mediaUrl;
  int likeCount;
  Map likes;
  bool isLiked;
  bool showHeart = false;
  bool isDeleteLoading = false;

  _PostState({
    this.postId,
    this.ownerId,
    this.username,
    this.location,
    this.description,
    this.mediaUrl,
    this.likes,
    this.likeCount,
  });

  handleLikes() {
    bool _islikes = likes[currentUser.id] == true;

    if (_islikes) {
      postsCollection
          .document(ownerId)
          .collection('userPosts')
          .document(postId)
          .updateData(
        {
          'likes.${currentUser.id}': false,
        },
      );

      setState(() {
        isLiked = false;
        likeCount -= 1;
        likes[currentUser.id] = false;
      });
      removeLikeFromActivityFeed();
    } else if (!_islikes) {
      postsCollection
          .document(ownerId)
          .collection('userPosts')
          .document(postId)
          .updateData(
        {
          'likes.${currentUser.id}': true,
        },
      );

      setState(() {
        isLiked = true;
        likeCount += 1;
        likes[currentUser.id] = true;
        showHeart = true;
      });
      Timer(Duration(milliseconds: 500), () {
        setState(() {
          showHeart = false;
        });
      });

      addLikeToactivityFeed();
    }
  }

  addLikeToactivityFeed() {
    bool _isPostOwner = ownerId == currentUser.id;
    if (!_isPostOwner) {
      feedActivityRef
          .document(ownerId)
          .collection('feedItems')
          .document(postId)
          .setData(
        {
          'type': 'like',
          'username': currentUser.username,
          'userId': currentUser.id,
          'userProfileUrl': currentUser.photoUrl,
          'postId': postId,
          'mediaUrl': mediaUrl,
          'timestamp': timestamp,
        },
      );
      addNotificationCount(ownerId);
    }
  }

  removeLikeFromActivityFeed() async {
    bool _isPostOwner = ownerId == currentUser.id;
    if (!_isPostOwner) {
      // feedActivityRef
      //     .document(ownerId)
      //     .collection('feedItems')
      //     .document(postId)
      //     .get()
      //     .then(
      //   (doc) {
      //     if (doc.exists) {
      //       doc.reference.delete();
      //     }
      //   },
      // );

      DocumentSnapshot _doc = await feedActivityRef
          .document(ownerId)
          .collection('feedItems')
          .document(postId)
          .get();

      if (_doc.exists) {
        _doc.reference.delete();
      }
    }
  }

  buildPostHeader() {
    bool isOwnerPost = ownerId == currentUser.id;
    return FutureBuilder(
      future: usersCollection.document(ownerId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        User user = User.fromDocument(snapshot.data);
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(user.photoUrl),
            backgroundColor: Colors.grey,
          ),
          title: GestureDetector(
            onTap: () => showProfile(context, profileId: ownerId),
            child: Text(
              user.username,
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          subtitle: Text(location),
          trailing: isOwnerPost
              ? IconButton(
                  onPressed: showDeleteDialog,
                  icon: Icon(Icons.more_vert),
                )
              : null,
        );
      },
    );
  }

  backToProfileScreen() {
    Navigator.pop(context);
    Navigator.pop(context);
  }

  showDeleteDialog() {
    return showDialog(
      context: context,
      builder: (_context) => StatefulBuilder(
        builder: (contextBuilder, _setState) {
          Widget showLoadingWiget() {
            return Container(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SpinKitChasingDots(
                    color: Colors.blue[800],
                    size: 50.0,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Deleting Post...',
                    style: TextStyle(color: Colors.blue[800]),
                  )
                ],
              ),
            );
          }

          loadingWidget() {
            isDeleteLoading = true;
          }

          stopLoadingWidget() {
            isDeleteLoading = false;
          }

          deletePost() async {
            print('delete methode excute...');

            _setState.call(loadingWidget);

            print('isDeletingLoading @$isDeleteLoading');
            try {
              //1- remove the post from post collection
              await postsCollection
                  .document(currentUser.id)
                  .collection('userPosts')
                  .document(postId)
                  .delete();

              //2- remove the image froma storage
              await storageRef.child('post_$postId.jpg').delete();

              //3- remove all activity feed related to this post
              var feedRef = await feedActivityRef
                  .document(currentUser.id)
                  .collection('feedItems')
                  .where('postId', isEqualTo: postId)
                  .getDocuments();
              feedRef.documents.forEach(
                (feedDoc) {
                  if (feedDoc.exists) {
                    feedDoc.reference.delete();
                  }
                },
              );

              //4 - remove all comments related to the Post
              var comments = await commentsRef
                  .document(postId)
                  .collection('comments')
                  .getDocuments();
              comments.documents.forEach(
                (commentDoc) {
                  if (commentDoc.exists) {
                    commentDoc.reference.delete();
                  }
                },
              );
              await commentsRef.document(postId).delete();
            } on Exception catch (e) {
              print(
                  'error accured while you remove the post Due To : ${e.toString()}');
            }

            _setState.call(stopLoadingWidget);
            _setState.call(backToProfileScreen);
          }

          Widget showOptionDialog() {
            return Column(
              children: [
                SimpleDialogOption(
                  onPressed: () => deletePost(),
                  child: Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                SimpleDialogOption(
                  onPressed: () => Navigator.pop(_context),
                  child: Text(
                    'Cancel',
                  ),
                ),
              ],
            );
          }

          return SimpleDialog(
            title: Text('Delete this Post?'),
            children: [
              isDeleteLoading ? showLoadingWiget() : showOptionDialog(),
            ],
          );
        },
      ),
    );
  }

  buildPostImage() {
    return GestureDetector(
      onDoubleTap: handleLikes,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          cachedNetworkImage(mediaUrl),
          // showHeart
          //     ? Animator(
          //         duration: Duration(milliseconds: 300),
          //         tween: Tween(begin: 0.8, end: 1.8),
          //         curve: Curves.elasticInOut,
          //         cycles: 0,
          //         builder: (anim) => Transform.scale(
          //           scale: anim.value,
          //           child: Icon(
          //             Icons.favorite,
          //             size: 80.0,
          //             color: Colors.redAccent,
          //           ),
          //         ),
          //       )
          //     : Container(),

          showHeart
              ? TweenAnimationBuilder(
                  tween: Tween(begin: 0.0, end: 130.0),
                  duration: Duration(milliseconds: 150),
                  curve: Curves.linear,
                  builder: (context, value, child) => Icon(
                    Icons.favorite,
                    size: value,
                    color: Colors.redAccent,
                  ),
                )
              : Container()
        ],
      ),
    );
  }

  buildPostFooter() {
    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Padding(padding: EdgeInsets.only(top: 40.0, left: 20.0)),
            GestureDetector(
              onTap: handleLikes,
              child: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                size: 28.0,
                color: Colors.pink,
              ),
            ),
            Padding(padding: EdgeInsets.only(right: 20.0)),
            GestureDetector(
              onTap: () => showComments(
                  postId: postId, mediaUrl: mediaUrl, ownerId: ownerId),
              child: Icon(
                Icons.chat,
                size: 28.0,
                color: Colors.blue[900],
              ),
            ),
          ],
        ),
        Row(
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(left: 20.0),
              child: Text(
                "$likeCount likes",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(left: 20.0),
              child: Text(
                "$username ",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(child: Text(description))
          ],
        ),
      ],
    );
  }

  void showComments({String postId, String mediaUrl, String ownerId}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => Comments(
          postId: postId,
          postMediaUrl: mediaUrl,
          postOwnerId: ownerId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // if (likes[currentUser.id] == true) {
    //   isLiked = true;
    // } else {
    //   isLiked = false;
    // }
    isLiked = likes[currentUser.id] == true;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        buildPostHeader(),
        buildPostImage(),
        buildPostFooter()
      ],
    );
  }
}
