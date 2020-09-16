import 'package:flutter/material.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/provider/timeline_provider.dart';
import 'package:provider/provider.dart';

header(
  BuildContext context, {
  bool isAppTitle = false,
  String titleText,
  bool removeBackIcon = false,
  bool isProfilePage = false,
}) {
  return AppBar(
    automaticallyImplyLeading: removeBackIcon ? false : true,
    title: Text(
      isAppTitle ? 'FlutterShare' : titleText,
      style: TextStyle(
        fontSize: isAppTitle ? 50.0 : 22.0,
        color: Colors.white,
        fontFamily: isAppTitle ? 'Signatra' : '',
      ),
    ),
    centerTitle: true,
    backgroundColor: Color(0xFF242E8D),
    actions: [
      isProfilePage
          ? IconButton(
              icon: Icon(Icons.exit_to_app),
              onPressed: () {
                // Provider.of<TimeLineProvider>(context, listen: false)
                //     .resetListForNewLogin();
                currentUser = null;
                googleSignIn.signOut();
                Navigator.push(
                    context, MaterialPageRoute(builder: (ctx) => Home()));
              })
          : Container(),
    ],
  );
}
