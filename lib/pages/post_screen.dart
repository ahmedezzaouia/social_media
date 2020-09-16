import 'package:flutter/material.dart';
import 'package:fluttershare/widgets/header.dart';
import 'package:fluttershare/widgets/post.dart';
import 'package:fluttershare/widgets/progress.dart';
import 'home.dart';

class PostScreen extends StatelessWidget {
  final String postOwner;
  final String postId;

  const PostScreen({Key key, this.postOwner, this.postId}) : super(key: key);

  Future<Post> getPost() async {
    final _doc = await postsCollection
        .document(postOwner)
        .collection('userPosts')
        .document(postId)
        .get();
    return Post.fromDocument(_doc);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, titleText: 'Post'),
      body: FutureBuilder(
        future: getPost(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (!snapshot.hasData) {
            return circularProgress();
          }
          Post post = snapshot.data;
          return ListView(
            children: [post],
          );
        },
      ),
    );
  }
}
