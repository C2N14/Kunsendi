import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kunsendi/src/utils.dart';
import 'package:kunsendi/src/widgets/app_alert_dialog.dart';

import '../widgets/kunsendi_cached_image.dart';
import '../models/image_data.dart';
import '../widgets/image_card.dart';
import '../globals.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';

class ImagesFeed extends StatefulWidget {
  static String tag = 'ímages-feed';
  @override
  _ImagesFeedState createState() => new _ImagesFeedState();
}

class _ImagesFeedState extends State<ImagesFeed> {
  // Controller to hide the action button programatically.
  ScrollController? _scrollController;
  bool? _hideFAB;

  List<KunsendiCachedImage>? _images;
  PickedFile? _pickedImage;

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();

    this._scrollController = ScrollController();
    this._scrollController!.addListener(() {
      setState(() {
        this._hideFAB = _scrollController!.position.userScrollDirection !=
            ScrollDirection.forward;
      });
    });
  }

  // Widget _confirmationDialog() {
  //   return AppAlertDialog(text: text);
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Kunsendi'),
        ),
        body: ListView(
          controller: this._scrollController,
          children: [],
        ),
        floatingActionButton: (this._hideFAB ?? false)
            ? null
            : FloatingActionButton(
                child: Icon(Icons.add_a_photo_outlined),
                onPressed: _selectImage,
              ));
  }

  @override
  void dispose() {
    _scrollController?.dispose();
    super.dispose();
  }

  Stream<KunsendiCachedImage?> _getImages(DateTime? upTo) async* {
    ApiResponse? response;
    try {
      response = await ApiClient.getInstance().listImages(to: upTo);
    } on TimeoutException {
      yield null;
    }

    for (var img in response?.payload) {
      yield KunsendiCachedImage(imageData: ImageData.fromJson(img));
    }
  }

  Future<void> _selectImage() async {
    print((await ApiClient.getInstance().listImages()).payload);

    // Some arbitrary file size restrictions to try to keep it below reasonable limits.
    final pickedFile = await _picker.getImage(
        source: ImageSource.gallery,
        imageQuality: 75,
        maxWidth: 2000,
        maxHeight: 2000);

    if (pickedFile == null) {
      return;
    }

    showDialog(
        context: this.context,
        builder: (context) => AlertDialog(
              title: Text('Are you sure you want to upload this file?'),
              actions: [
                TextButton(
                    child: Text('YES'),
                    onPressed: () async {
                      this._closeDialog();
                      this._postImage(File(pickedFile.path));
                    }),
                TextButton(child: Text('CANCEL'), onPressed: this._closeDialog)
              ],
            ));
  }

  Future<void> _postImage(File imageFile) async {
    bool tooLarge = false, requestError = false;

    showDialog(
        context: this.context,
        builder: (context) => WillPopScope(
            child: SimpleDialog(
              children: [
                Center(child: CircularProgressIndicator()),
                Text('Please wait...')
              ],
            ),
            onWillPop: () => Future.value(false)));

    // Fail when file is too large (over 10MB).
    print(await imageFile.length());
    if (await imageFile.length() > 1e+7) {
      tooLarge = true;
    } else {
      // Check for abnormal server response.
      try {
        final response = await ApiClient.getInstance().postImage(imageFile);
        requestError = response.statusCode != HttpStatus.created;
        print(response.payload);
      } on TimeoutException {
        requestError = true;
      }
    }

    this._closeDialog();

    // Show the result dialog.
    showDialog(
        context: this.context,
        builder: (context) => AppAlertDialog(
            text: tooLarge
                ? 'The file picked is too large.'
                : requestError
                    ? 'There was an error with the request.'
                    : 'File uploaded successfully'));
  }

  void _closeDialog() {
    Navigator.of(this.context, rootNavigator: true).pop();
  }
}
