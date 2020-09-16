import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/activity_feed.dart';
import 'package:fluttershare/pages/create_account.dart';
import 'package:fluttershare/pages/profile.dart';
import 'package:fluttershare/pages/search.dart';
import 'package:fluttershare/pages/timeline.dart';
import 'package:fluttershare/pages/upload.dart';
import 'package:fluttershare/provider/timeline_provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

final GoogleSignIn googleSignIn = GoogleSignIn();
final CollectionReference usersCollection =
    Firestore.instance.collection('users');
final CollectionReference postsCollection =
    Firestore.instance.collection('posts');
final CollectionReference commentsRef =
    Firestore.instance.collection('comments');
final CollectionReference feedActivityRef =
    Firestore.instance.collection('feed');

final CollectionReference followingRef =
    Firestore.instance.collection('following');

final CollectionReference followerRef =
    Firestore.instance.collection('followers');

final StorageReference storageRef = FirebaseStorage.instance.ref();
final DateTime timestamp = DateTime.now();
User currentUser;

addNotificationCount(String _userId) async {
  var userData = await usersCollection.document(_userId).get();
  int userNotificationCount = userData.data['notificationCount'];
  usersCollection.document(_userId).updateData(
    {'notificationCount': userNotificationCount + 1},
  );
}

resetNotificationCount() async {
  await usersCollection
      .document(currentUser.id)
      .updateData({'notificationCount': 0});
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  PageController pageController;

  bool isAuth = false;
  int pageIndex = 0;

  @override
  void initState() {
    super.initState();

    pageController = PageController();
    googleSignIn.onCurrentUserChanged.listen(
      (account) {
        handleSignIn(account);
      },
    );

    googleSignIn.signInSilently().then(
      (account) {
        handleSignIn(account);
      },
    );
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  void handleSignIn(GoogleSignInAccount account) async {
    if (account != null) {
      await createUserInfirestor();
      setState(() {
        isAuth = true;
      });
    } else {
      print('user not authenticate');
      setState(() {
        isAuth = false;
      });
    }
  }

  createUserInfirestor() async {
    GoogleSignInAccount _user = googleSignIn.currentUser;
    DocumentSnapshot doc = await usersCollection.document(_user.id).get();

// 1. check if the user not exist in firestore
    if (!doc.exists) {
      //2. if not exist,then take them to create account page
      final String username = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (ctx) => CreateAccount(),
        ),
      );

      //3.take the username from create account and make new user to database
      usersCollection.document(_user.id).setData(
        {
          'id': _user.id,
          'username': username,
          'photoUrl': _user.photoUrl,
          'email': _user.email,
          'displayName': _user.displayName,
          'bio': '',
          'timestamp': timestamp,
        },
      );
    }
    doc = await usersCollection.document(_user.id).get();
    setState(() {
      currentUser = User.fromDocument(doc);
      // Provider.of<TimeLineProvider>(context, listen: false)
      //     .getPostsFromFollowings(currentUser?.id);
    });
  }

  login() {
    googleSignIn.signIn();
  }

  logOut() {
    googleSignIn.signOut();
  }

  void onTapBottonNavigator(int index) {
    pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
    setState(() {
      pageIndex = index;
    });
  }

  onPageChanged(int index) {
    setState(() {
      pageIndex = index;
    });
  }

  Stream<int> getUserNotificationCount() {
    return usersCollection
        .document(currentUser.id)
        .snapshots()
        .map((_docSnap) => _docSnap.data['notificationCount']);
  }

  iconWithBadge() {
    return Container(
      height: 25,
      width: 30,
      child: Stack(
        children: [
          Icon(Icons.notifications_paused),
          StreamBuilder(
              stream: getUserNotificationCount(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Container();
                }
                int notificationCount = snapshot.data;
                if (notificationCount == 0) {
                  return Container();
                }
                return Container(
                  height: notificationCount.bitLength + 13.0,
                  width: notificationCount.bitLength + 15.0,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '$notificationCount+',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                );
              }),
        ],
      ),
    );
  }

  Widget buildAuthScreen() {
    return Scaffold(
      body: PageView(
        children: [
          Timeline(
            currentId: currentUser?.id,
            key: PageStorageKey('save'),
          ),
          ActivityFeed(),
          Upload(
            currentUser: currentUser,
          ),
          Search(),
          Profile(profileId: currentUser?.id),
        ],
        controller: pageController,
        onPageChanged: onPageChanged,
      ),
      bottomNavigationBar: CupertinoTabBar(
        activeColor: Theme.of(context).primaryColor,
        currentIndex: pageIndex,
        onTap: onTapBottonNavigator,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.whatshot),
          ),
          BottomNavigationBarItem(
            icon: iconWithBadge(),
          ),
          BottomNavigationBarItem(
              icon: Icon(
            Icons.photo_camera,
            size: 35.0,
          )),
          BottomNavigationBarItem(icon: Icon(Icons.search)),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle)),
        ],
      ),
    );
  }

  Scaffold buildUnAuthScreen() {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF9041B8),
              Color(0xFF26629E),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Social Media',
              style: TextStyle(
                fontSize: 90.0,
                fontFamily: 'Signatra',
                color: Colors.white,
              ),
            ),
            GestureDetector(
              onTap: login,
              child: Container(
                width: 260,
                height: 60,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/google_signin_button.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return isAuth ? buildAuthScreen() : buildUnAuthScreen();
  }
}
