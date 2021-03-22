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
import 'package:flutter/foundation.dart';

class ImagesFeed extends StatefulWidget {
  static String tag = 'ímages-feed';
  @override
  _ImagesFeedState createState() => new _ImagesFeedState();
}

class _ImagesFeedState extends State<ImagesFeed> {
  // Controller to hide the action button programmatically.
  ScrollController? _scrollController;
  bool? _hideFAB;
  bool? _hideList;
  bool _done = true;

  List<KunsendiCachedImage> _images = [];

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();

    this._scrollController = ScrollController();
    this._scrollController!.addListener(this._scrollListener);

    // Load the images for the first time.
    this._refreshImages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kunsendi'),
      ),
      body: RefreshIndicator(
        onRefresh: this._refreshImages,
        child: AnimatedOpacity(
          opacity: (this._hideList ?? false) ? 0.0 : 1.0,
          duration: Duration(milliseconds: 300),
          child: ListView.builder(
              physics: AlwaysScrollableScrollPhysics(),
              controller: this._scrollController,
              itemCount: this._images.length,
              itemBuilder: (context, index) {
                return ImageCard(image: this._images[index]);
              }),
        ),
      ),
      floatingActionButton: (this._hideFAB ?? false)
          ? null
          : FloatingActionButton(
              child: Icon(Icons.add_a_photo_outlined),
              onPressed: _selectImage,
            ),
    );
  }

  @override
  void dispose() {
    _scrollController?.dispose();
    super.dispose();
  }

  /// Used for hiding the FloatingActionButton and for lazily generating more
  /// images.
  void _scrollListener() {
    ScrollPosition currentPosition = _scrollController!.position;
    bool noMoreResults = true;

    setState(() {
      this._hideFAB =
          currentPosition.userScrollDirection != ScrollDirection.forward;
      if (!this._done && currentPosition.extentAfter < 500) {
        // Make sure it queries for images after the last displayed.
        final lastImageData =
            this._images.isNotEmpty ? this._images.last.imageData : null;

        this
            ._fetchImages(upTo: lastImageData?.uploadDate, results: 15)
            .forEach((element) {
          noMoreResults = false;
          this._images.add(element);
        });
        this._done = noMoreResults;
      }
    });
  }

  /// Pops navigator to close a dialog.
  void _closeDialog() {
    Navigator.of(this.context, rootNavigator: true).pop();
  }

  /// Clears all the images and gets new ones.
  Future<void> _refreshImages() async {
    // Fade the list out
    setState(() {
      this._hideList = true;
    });

    this._done = false;

    // Remove all images and make list visible again.
    setState(() {
      this._images.clear();
      this._hideList = false;
    });

    this._images = await this._fetchImages(results: 15).toList();
    setState(() {});
  }

  /// [Stream] to query for new images.
  Stream<KunsendiCachedImage> _fetchImages(
      {DateTime? upTo, int? results, String? excludedFilename}) async* {
    debugPrint('getting images...');

    ApiResponse? response;
    bool errorResponse = false;

    try {
      response =
          await ApiClient.getInstance().listImages(to: upTo, limit: results);
      errorResponse = response.statusCode != HttpStatus.ok;
    } on TimeoutException {
      errorResponse = true;
    } on Exception catch (e) {
      debugPrint(e.toString());
      debugPrint(response?.payload?.toString() ?? 'no response body');
    }

    if (errorResponse) {
      // TODO: error toast
      return;
    }

    for (var img in response!.payload) {
      if (img['filename'] != excludedFilename) {
        yield KunsendiCachedImage(imageData: ImageData.fromJson(img));
      }
    }
  }

  /// Logic to start the image selection process.
  Future<void> _selectImage() async {
    // this._refreshImages();

    // return;
    // Some arbitrary file size restrictions to try to keep it below reasonable
    // limits.
    final pickedFile = await _picker.getImage(
        source: ImageSource.gallery,
        imageQuality: 75,
        maxWidth: 1000,
        maxHeight: 1000);

    if (pickedFile == null) {
      return;
    }

    showDialog(
        context: this.context,
        builder: (context) => AlertDialog(
              title: Text('Are you sure you want to upload this file?'),
              actions: [
                TextButton(
                    child: Text('UPLOAD'),
                    onPressed: () async {
                      this._closeDialog();
                      this._postImage(File(pickedFile.path));
                    }),
                TextButton(child: Text('CANCEL'), onPressed: this._closeDialog)
              ],
            ));
  }

  /// Run once image selection is confirmed.
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
    ApiClient apiClient = ApiClient.getInstance();
    debugPrint('file size: ${await imageFile.length()}');

    if (await imageFile.length() > 1e+7) {
      tooLarge = true;
    } else {
      // Check for abnormal server response.
      try {
        final response = await apiClient.postImage(imageFile);
        requestError = response.statusCode != HttpStatus.created;
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

    if (tooLarge || requestError) {
      return;
    }

    // Get data of image just uploaded.
    ImageData? imageData;
    try {
      final response = await apiClient.listImages(
          uploader: AppGlobals.localStorage!.getString('logged_username'),
          limit: 1);
      imageData = ImageData.fromJson(response.payload[0]);
    } on TimeoutException {
      debugPrint("couldn't get the posted image, timed out.");
      return;
    }

    // Insert posted image at the top of the list.
    this.setState(() {
      this._images.insert(0, KunsendiCachedImage(imageData: imageData!));
    });
  }
}
