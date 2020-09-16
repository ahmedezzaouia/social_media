import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/widgets/progress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as Im;
import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart';

class Upload extends StatefulWidget {
  final User currentUser;

  const Upload({
    Key key,
    @required this.currentUser,
  }) : super(key: key);
  @override
  _UploadState createState() => _UploadState();
}

class _UploadState extends State<Upload>
    with AutomaticKeepAliveClientMixin<Upload> {
  File pickedImage;
  bool isUploading = false;
  String postId = Uuid().v4();
  TextEditingController locationController = TextEditingController();
  TextEditingController captionController = TextEditingController();

  pickImage(BuildContext _context, {bool isCamera = false}) async {
    File image = await ImagePicker.pickImage(
        source: isCamera ? ImageSource.camera : ImageSource.gallery,
        maxHeight: 675,
        maxWidth: 960);

    setState(() {
      pickedImage = image;
    });
    Navigator.pop(_context);
  }

  void clearImag() {}
// compress image to reduce the size and kepp the quality
  compressImage() async {
    final tempDir = await getTemporaryDirectory();
    final path = tempDir.path;
    Im.Image imageFile = Im.decodeImage(pickedImage.readAsBytesSync());
    final compressedImageFile = File('$path/img_$postId.jpg')
      ..writeAsBytesSync(Im.encodeJpg(imageFile, quality: 85));
    setState(() {
      pickedImage = compressedImageFile;
    });
  }

  Future<String> uploadeImage(File file) async {
    StorageTaskSnapshot storageTaskSnapshot =
        await storageRef.child('post_$postId.jpg').putFile(file).onComplete;
    String mediaUrl = await storageTaskSnapshot.ref.getDownloadURL();
    return mediaUrl;
  }

  Future<void> createPostInFirestore(
      {String mediaUrl, String location, String description}) {
    return postsCollection
        .document(widget.currentUser.id)
        .collection('userPosts')
        .document(postId)
        .setData(
      {
        'postId': postId,
        'ownerId': widget.currentUser.id,
        'username': widget.currentUser.username,
        'mediaUrl': mediaUrl,
        'description': description,
        'location': location,
        'timestamp': timestamp,
        'likes': {},
      },
    );
  }

  void getUserLocation() async {
    Position position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    List<Placemark> placemarks = await Geolocator()
        .placemarkFromCoordinates(position.latitude, position.longitude);

    String location = '${placemarks[0].locality},${placemarks[0].country}';
    print(location);
    locationController.text = location;
  }

  void handleSubmit() async {
    setState(() {
      isUploading = true;
    });

    await compressImage();

    String mediaUrl = await uploadeImage(pickedImage);

    createPostInFirestore(
      mediaUrl: mediaUrl,
      location: locationController.text,
      description: captionController.text,
    );

    locationController.clear();
    captionController.clear();
    setState(() {
      isUploading = false;
      pickedImage = null;
      postId = Uuid().v4();
    });
  }

  selectImageDialog(BuildContext _context) {
    return showDialog(
        context: _context,
        builder: (ctx) {
          return SimpleDialog(
            title: Text('create a post'),
            children: [
              SimpleDialogOption(
                child: Text('photo with Camera '),
                onPressed: () => pickImage(ctx, isCamera: true),
              ),
              SimpleDialogOption(
                child: Text('image from gallery'),
                onPressed: () => pickImage(ctx),
              ),
              SimpleDialogOption(
                child: Text('Cancel'),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          );
        });
  }

  Scaffold buildUploadForm() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white70,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.black54,
          ),
          onPressed: clearImag,
        ),
        title: Text(
          'Caption Post',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        actions: [
          FlatButton(
            onPressed: isUploading ? null : () => handleSubmit(),
            child: Text(
              'Post',
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
          )
        ],
      ),
      body: ListView(
        children: [
          isUploading ? linearProgress() : Container(),
          Container(
            height: 220.0,
            width: MediaQuery.of(context).size.width * 0.8,
            child: Center(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: FileImage(pickedImage),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey,
                backgroundImage:
                    CachedNetworkImageProvider(widget.currentUser.photoUrl),
              ),
              title: Container(
                width: 250.0,
                child: TextField(
                  controller: captionController,
                  decoration: InputDecoration(
                    hintText: 'Write a caption...',
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
          ),
          Divider(),
          ListTile(
            leading: IconButton(
              icon: Icon(
                Icons.pin_drop,
                color: Colors.orange,
                size: 35.0,
              ),
              onPressed: () {},
            ),
            subtitle: Container(
              width: 250.0,
              child: TextField(
                controller: locationController,
                decoration: InputDecoration(
                  hintText: 'Where was this photo taken...',
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Container(
            width: 200.0,
            height: 100.0,
            alignment: Alignment.center,
            child: RaisedButton.icon(
              color: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
              onPressed: getUserLocation,
              icon: Icon(Icons.add_location, color: Colors.white),
              label: Text(
                'use current location!',
                style: TextStyle(color: Colors.white),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget buildSplashScreen() {
    return Container(
      color: Color(0xFF440091),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/images/upload.svg',
            height: 260.0,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: RaisedButton(
              color: Color(0xFF64B05B),
              onPressed: () => selectImageDialog(context),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              child: Text(
                'Upload Image',
                style: TextStyle(
                  fontSize: 22.0,
                  color: Colors.white,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return pickedImage == null ? buildSplashScreen() : buildUploadForm();
  }
}
