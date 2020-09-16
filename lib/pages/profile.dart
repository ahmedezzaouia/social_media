import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/edit_profile.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/widgets/header.dart';
import 'package:fluttershare/widgets/post.dart';
import 'package:fluttershare/widgets/post_tile.dart';
import 'package:fluttershare/widgets/progress.dart';

class Profile extends StatefulWidget {
  final String profileId;

  const Profile({Key key, @required this.profileId}) : super(key: key);
  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  String currentUserId = currentUser?.id;
  List<Post> posts = [];
  // bool isLoading = false;
  int postsCount = 0;
  String postOreintation = 'grid';
  bool isFollowing = false;
  int followingCount = 0;
  int followersCount = 0;
  @override
  void initState() {
    super.initState();
    // getProfilePosts();
    checkIfFollowing();
    getFollowingCount();
    getFollowersCount();
  }

  getFollowingCount() async {
    var data = await followingRef
        .document(widget.profileId)
        .collection('userFollowing')
        .getDocuments();

    setState(() {
      followingCount = data.documents.length;
    });
  }

  getFollowersCount() async {
    var data = await followerRef
        .document(widget.profileId)
        .collection('userFollowers')
        .getDocuments();

    setState(() {
      followersCount = data.documents.length;
    });
  }

  checkIfFollowing() async {
    var doc = await followingRef
        .document(currentUserId)
        .collection('userFollowing')
        .document(widget.profileId)
        .get();

    setState(() {
      isFollowing = doc.exists;
    });
  }

  // getProfilePosts() async {
  //   setState(() {
  //     isLoading = true;
  //   });

  //   QuerySnapshot snapshot = await postsCollection
  //       .document(widget.profileId)
  //       .collection('userPosts')
  //       .orderBy('timestamp', descending: true)
  //       .getDocuments();

  //   setState(() {
  //     isLoading = false;
  //   });
  //   posts = snapshot.documents.map((doc) => Post.fromDocument(doc)).toList();
  //   postsCount = snapshot.documents.length;
  // }

  buildCountColumn(String label, int count) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 22.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 4.0),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 15.0,
              color: Colors.grey,
            ),
          ),
        )
      ],
    );
  }

  buildbutton({String text, Function function}) {
    return Container(
      padding: const EdgeInsets.only(top: 2.0),
      child: FlatButton(
        onPressed: function,
        child: Container(
          child: Text(
            text,
            style: TextStyle(color: isFollowing ? Colors.black : Colors.white),
          ),
          height: 27,
          width: 200,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isFollowing ? Colors.white : Colors.blue,
            border: Border.all(color: Colors.blue),
            borderRadius: BorderRadius.circular(5.0),
          ),
        ),
      ),
    );
  }

  editProfile() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (ctx) => EditProfile(currentUserId: currentUserId)));
  }

  buildProfileButton() {
    bool isProfileOwner = currentUserId == widget.profileId;
    if (isProfileOwner) {
      return buildbutton(
        text: 'Edite profile',
        function: editProfile,
      );
    } else if (isFollowing) {
      return buildbutton(text: 'Unfollow', function: handlFollowOrUnfollowUser);
    } else if (!isFollowing) {
      return buildbutton(text: 'follow', function: handlFollowOrUnfollowUser);
    }
  }
//  handleUnfollowUser() {
//     setState(() {
//       isFollowing = false;
//     });
//     // remove follower
//     followersRef
//         .document(widget.profileId)
//         .collection('userFollowers')
//         .document(currentUserId)
//         .get()
//         .then((doc) {
//       if (doc.exists) {
//         doc.reference.delete();
//       }
//     });
//     // remove following
//     followingRef
//         .document(currentUserId)
//         .collection('userFollowing')
//         .document(widget.profileId)
//         .get()
//         .then((doc) {
//       if (doc.exists) {
//         doc.reference.delete();
//       }
//     });
//     // delete activity feed item for them
//     activityFeedRef
//         .document(widget.profileId)
//         .collection('feedItems')
//         .document(currentUserId)
//         .get()
//         .then((doc) {
//       if (doc.exists) {
//         doc.reference.delete();
//       }
//     });
//   }

//   handleFollowUser() {
//     setState(() {
//       isFollowing = true;
//     });
//     // Make auth user follower of THAT user (update THEIR followers collection)
//     followersRef
//         .document(widget.profileId)
//         .collection('userFollowers')
//         .document(currentUserId)
//         .setData({});
//     // Put THAT user on YOUR following collection (update your following collection)
//     followingRef
//         .document(currentUserId)
//         .collection('userFollowing')
//         .document(widget.profileId)
//         .setData({});
//     // add activity feed item for that user to notify about new follower (us)
//     activityFeedRef
//         .document(widget.profileId)
//         .collection('feedItems')
//         .document(currentUserId)
//         .setData({
//       "type": "follow",
//       "ownerId": widget.profileId,
//       "username": currentUser.username,
//       "userId": currentUserId,
//       "userProfileImg": currentUser.photoUrl,
//       "timestamp": timestamp,
//     });
//   }
  handlFollowOrUnfollowUser() {
    setState(() {
      isFollowing = !isFollowing;
    });
    var refFollowing = followingRef
        .document(currentUserId)
        .collection('userFollowing')
        .document(widget.profileId);

    var refFollower = followerRef
        .document(widget.profileId)
        .collection('userFollowers')
        .document(currentUserId);
    //user is making follow
    if (isFollowing) {
      refFollowing.setData({});
      refFollower.setData({});

      feedActivityRef.document(widget.profileId).collection('feedItems').add(
        {
          'type': 'follow',
          'username': currentUser.username,
          'userId': currentUserId,
          'userProfileUrl': currentUser.photoUrl,
          'timestamp': timestamp,
        },
      );
      addNotificationCount(widget.profileId);
    } else {
      refFollowing.delete();
      refFollower.delete();
    }
  }

  buildProfileHeader() {
    return StreamBuilder(
      stream:
          usersCollection.document(widget.profileId).snapshots().map((event) {
        return event;
      }),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        User user = User.fromDocument(snapshot.data);
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 40.0,
                    backgroundColor: Colors.grey,
                    backgroundImage: CachedNetworkImageProvider(user.photoUrl),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            buildCountColumn('Posts', postsCount),
                            buildCountColumn('Followers', followersCount),
                            buildCountColumn('following', followingCount),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            buildProfileButton(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Container(
                alignment: Alignment.centerLeft,
                margin: const EdgeInsets.only(top: 16.0),
                child: Text(user.username,
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    )),
              ),
              Container(
                alignment: Alignment.centerLeft,
                margin: const EdgeInsets.only(top: 4.0),
                child: Text(user.displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    )),
              ),
              Container(
                alignment: Alignment.centerLeft,
                margin: const EdgeInsets.only(top: 2.0),
                child: Text(
                  user.bio,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildProfilPosts() {
    return StreamBuilder(
      stream: postsCollection
          .document(widget.profileId)
          .collection('userPosts')
          .snapshots()
          .map((_snapshot) => _snapshot.documents
              .map((_doc) => Post.fromDocument(_doc))
              .toList()),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        print('litsner from StraemBuilder posts....');
        if (!snapshot.hasData) {
          return circularProgress();
        }
        List<Post> posts = snapshot.data;
        if (posts.isEmpty) {
          return buildNoContent();
        }
        postsCount = posts.length;
        List<GridTile> gridetitles = [];
        posts.forEach((post) {
          gridetitles.add(GridTile(child: PostTile(post: post)));
        });
        if (postOreintation == 'grid') {
          return GridView.count(
            crossAxisCount: 3,
            mainAxisSpacing: 1.5,
            crossAxisSpacing: 1.5,
            childAspectRatio: 1.0,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            children: gridetitles,
          );
        } else {
          print('switch to list posts ');
          return Column(children: posts);
        }
      },
    );

    // if (isLoading) {
    //   return circularProgress();
    // } else if (posts.isEmpty) {
    //   return buildNoContent();
    // } else if (postOreintation == 'grid') {
    //   List<GridTile> gridetitles = [];
    //   posts.forEach((post) {
    //     gridetitles.add(GridTile(child: PostTile(post: post)));
    //   });
    //   return GridView.count(
    //     crossAxisCount: 3,
    //     mainAxisSpacing: 1.5,
    //     crossAxisSpacing: 1.5,
    //     childAspectRatio: 1.0,
    //     shrinkWrap: true,
    //     physics: NeverScrollableScrollPhysics(),
    //     children: gridetitles,
    //   );
    // } else {
    //   return Column(
    //     children: posts,
    //   );
    // }
  }

  setTheOrientation(String orientation) {
    setState(() {
      postOreintation = orientation;
    });
  }

  Widget buildtoggleOrientation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          onPressed: () => setTheOrientation('grid'),
          color: postOreintation == 'grid'
              ? Theme.of(context).primaryColor
              : Colors.grey,
          icon: Icon(Icons.grid_on),
        ),
        IconButton(
          onPressed: () => setTheOrientation('list'),
          icon: Icon(Icons.list),
          color: postOreintation == 'list'
              ? Theme.of(context).primaryColor
              : Colors.grey,
        ),
      ],
    );
  }

  Widget buildNoContent() {
    return Container(
      child: Center(
        child: ListView(
          shrinkWrap: true,
          children: [
            SvgPicture.asset(
              'assets/images/no_content.svg',
              height: 160,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Text(
                'No Post',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 40.0,
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, titleText: 'Profile', isProfilePage: true),
      body: ListView(
        children: [
          buildProfileHeader(),
          Divider(),
          buildtoggleOrientation(),
          Divider(),
          buildProfilPosts(),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}
