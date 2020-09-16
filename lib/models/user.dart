import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String email;
  final String username;
  final String displayName;
  final String photoUrl;
  final String bio;

  User({
    this.bio,
    this.displayName,
    this.email,
    this.id,
    this.photoUrl,
    this.username,
  });

  factory User.fromDocument(DocumentSnapshot doc) {
    return User(
      id: doc['id'],
      displayName: doc['displayName'],
      email: doc['email'],
      photoUrl: doc['photoUrl'],
      username: doc['username'],
      bio: doc['bio'],
    );
  }
}
