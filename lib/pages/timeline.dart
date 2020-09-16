import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/provider/timeline_provider.dart';
import 'package:fluttershare/widgets/custom_image.dart';
import 'package:fluttershare/widgets/header.dart';
import 'package:fluttershare/widgets/post.dart';
import 'package:fluttershare/widgets/progress.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'dart:io';

class Timeline extends StatefulWidget {
  final String currentId;

  Timeline({Key key, this.currentId}) : super(key: key);

  @override
  _TimelineState createState() => _TimelineState();
}

class _TimelineState extends State<Timeline>
    with AutomaticKeepAliveClientMixin<Timeline> {
  bool isRefresh = false;
  TimeLineProvider providerData;
  bool isConnected = true;
  List<Post> privieusPosts;

  @override
  void initState() {
    checkInternetConnection();
    initializeCloudMessaging();
    super.initState();
  }

  initializeCloudMessaging() {
    FirebaseMessaging fm = FirebaseMessaging();
    fm.requestNotificationPermissions();

    fm.subscribeToTopic(currentUser.id);
    print('<<<<<<<<<<<<<< userId from Messaging :${currentUser.id} >>>>>>>>>');
  }

  checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        print('********** the device is connected *********');
      }
    } on SocketException catch (_) {
      print('************  the device is not connected *******************');
      isConnected = false;
    }
  }

  bool get wantKeepAlive => true;
  @override
  Widget build(context) {
    super.build(context);
    print('build Timeline....');
    print('currentID is :${widget.currentId}');
    providerData = Provider.of<TimeLineProvider>(context, listen: false);
    return Scaffold(
      appBar: header(context, titleText: 'Home'),
      body: RefreshIndicator(
        onRefresh: refreshPosts,
        child: isRefresh ? secondFutureCall() : firstFuturebuilderCall(),
      ),
    );
  }

  buildNoPosts() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        cachedNetworkImage(
            'https://havecamerawilltravel.com/photographer/files/2017/05/instagram-archive-posts-02-havecamerawilltravel-com.jpg'),
      ],
    );
  }

  Widget firstFuturebuilderCall() {
    return FutureBuilder<List<Post>>(
      future: getPostsFromFollowings(widget.currentId),
      builder: (BuildContext _context, AsyncSnapshot _snapshot) {
        print('first call of FutureBuilder');
        if (!isConnected) {
          return Center(
            child: Text(
              'no access to internet',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
          );
        }

        if (!_snapshot.hasData) {
          return circularProgress();
        }
        List<Post> posts = _snapshot.data;
        privieusPosts = posts;
        if (posts.isEmpty) {
          return buildNoPosts();
        }
        return listBuilderWidget(posts);
      },
    );
  }

  Widget secondFutureCall() {
    return Container(
      child: FutureBuilder(
        future: getPostsFromFollowings(widget.currentId),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (!isConnected) {
            return Center(
              child: Text(
                'no access to internet',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
            );
          }
          if (!snapshot.hasData) {
            print('second future witing state ');
            return listBuilderWidget(privieusPosts);
          }
          List<Post> posts = snapshot.data;
          if (posts.isEmpty) {
            return buildNoPosts();
          }
          return Container(
            child: listBuilderWidget(posts),
          );
        },
      ),
    );
  }

  Widget listBuilderWidget(List<Post> _posts) {
    return Scrollbar(
      child: ListView.builder(
        itemCount: _posts.length,
        itemBuilder: (BuildContext context, int index) {
          return _posts[index];
        },
      ),
    );
  }

  Future refreshPosts() async {
    setState(() {
      isRefresh = true;
    });

    // getPostsFromFollowings(widget.currentId);
  }

  Future<List<Post>> getPostsFromFollowings(String _userID) async {
    List<Post> postsLine = [];

    var userFollowingDocuments = await followingRef
        .document(_userID)
        .collection('userFollowing')
        .getDocuments();

    for (var following in userFollowingDocuments.documents) {
      String followingId = following.documentID;
      print('from loop 1');
      var postsDocuments = await postsCollection
          .document(followingId)
          .collection('userPosts')
          .getDocuments();

      for (var _doc in postsDocuments.documents) {
        print('from loop 2');

        postsLine.add(Post.fromDocument(_doc));
      }
    }

    postsLine.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    print('list from futureBuilder :${postsLine.length}');

    // if (providerData.commingPosts.isEmpty) {
    //   print('execute isEmpty list condition');
    //   providerData.setPosts(postsLine);
    // } else {
    //   print('execute isNotEmpty list condition');

    //   providerData.addPosts(postsLine);
    // }

    return postsLine;
  }
}
