import 'package:flutter/material.dart';

import '../models/image_data.dart';
import '../widgets/image_card.dart';
import '../globals.dart';

class ImagesFeed extends StatefulWidget {
  static String tag = 'ímages-feed';
  @override
  _ImagesFeedState createState() => new _ImagesFeedState();
}

class _ImagesFeedState extends State<ImagesFeed> {
  String? _loggedUsername;

  @override
  void initState() {
    super.initState();

    this._loggedUsername = AppGlobals.localStorage?.getString('username');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hello world!'),
      ),
      // body: Container()
      body: ListView(
        children: [
          ImageCard(
              imageData: ImageData(
                  uploader: 'pogo',
                  filename:
                      'https://assets.pogo.org/image/content/2020/FDA_Panel_Reviewing_Pfizer_Vaccine_Excludes_Some_Experts_1150.jpg?mtime=20201209202119',
                  uploadDate: DateTime.now(),
                  width: 0,
                  height: 0)),
          ImageCard(
              imageData: ImageData(
                  uploader: 'bigstock',
                  filename:
                      'https://p.bigstockphoto.com/GeFvQkBbSLaMdpKXF1Zv_bigstock-Aerial-View-Of-Blue-Lakes-And--227291596.jpg',
                  uploadDate: DateTime.now(),
                  width: 0,
                  height: 0)),
          ImageCard(
              imageData: ImageData(
                  uploader: 'arstechnica',
                  filename:
                      'https://cdn.arstechnica.net/wp-content/uploads/2016/02/5718897981_10faa45ac3_b-640x624.jpg',
                  uploadDate: DateTime.now(),
                  width: 0,
                  height: 0)),
          ImageCard(
              imageData: ImageData(
                  uploader: 'sproutsocial',
                  filename:
                      'https://media.sproutsocial.com/uploads/2017/02/10x-featured-social-media-image-size.png',
                  uploadDate: DateTime.now(),
                  width: 0,
                  height: 0)),
        ],
      ),
    );
  }
}
