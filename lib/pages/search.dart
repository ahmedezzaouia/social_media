import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/activity_feed.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/pages/profile.dart';

import 'package:fluttershare/widgets/progress.dart';
import 'package:cached_network_image/cached_network_image.dart';

class Search extends StatefulWidget {
  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search>
    with AutomaticKeepAliveClientMixin<Search> {
  Future<QuerySnapshot> searchResultFuture;
  TextEditingController _textEditingController = TextEditingController();

  void handleSearch(String query) {
    if (query.isEmpty) {
      query = 'no_users';
    }
    Future<QuerySnapshot> users = usersCollection
        .where('displayName', isGreaterThanOrEqualTo: query)
        .where('displayName', isLessThanOrEqualTo: query + 'z')
        .getDocuments();

    setState(() {
      searchResultFuture = users;
    });
  }

  AppBar buildSearchField() {
    return AppBar(
      backgroundColor: Color(0xFF242E8D),
      title: TextFormField(
        controller: _textEditingController,
        style: TextStyle(
          color: Colors.white,
        ),
        decoration: InputDecoration(
          hintText: 'Search for a user...',
          filled: true,
          hintStyle: TextStyle(
            color: Colors.white,
          ),
          prefixIcon: Icon(
            Icons.add_box,
            size: 28.0,
            color: Colors.white,
          ),
          suffixIcon: IconButton(
              icon: Icon(
                Icons.clear,
                color: Colors.white,
              ),
              onPressed: () {
                _textEditingController.clear();
              }),
        ),
        onFieldSubmitted: (_input) => handleSearch(_input),
      ),
    );
  }

  Widget buildNoContent() {
    final Orientation orientation = MediaQuery.of(context).orientation;
    return Container(
      color: Color(0xFF440091),
      child: Center(
        child: ListView(
          shrinkWrap: true,
          children: [
            SvgPicture.asset(
              'assets/images/search.svg',
              height: orientation == Orientation.portrait ? 300 : 200,
            ),
            Text(
              'Find users',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 50.0,
                fontStyle: FontStyle.italic,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget buildSearchResult() {
    return FutureBuilder<QuerySnapshot>(
      future: searchResultFuture,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }

        QuerySnapshot data = snapshot.data;
        if (data.documents.isEmpty) {
          return Center(child: Text('Sorry we Cant\' find this user'));
        }
        List<UserResult> searchResults = [];
        data.documents.forEach(
          (doc) {
            User user = User.fromDocument(doc);
            searchResults.add(UserResult(user: user));
          },
        );
        return ListView(
          children: searchResults,
        );
      },
    );
  }

  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: buildSearchField(),
      body: searchResultFuture == null ? buildNoContent() : buildSearchResult(),
    );
  }
}

class UserResult extends StatelessWidget {
  final User user;

  const UserResult({Key key, this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).primaryColor.withOpacity(0.7),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => showProfile(context, profileId: user.id),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey,
                backgroundImage: CachedNetworkImageProvider(user.photoUrl),
              ),
              title: Text(
                user.displayName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              subtitle: Text(
                user.username,
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Divider(
            height: 2.0,
            color: Colors.black54,
          )
        ],
      ),
    );
  }
}
