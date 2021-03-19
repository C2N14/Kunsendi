import 'package:flutter/material.dart';

import '../models/image_data.dart';
import '../widgets/image_card.dart';
import '../globals.dart';
import 'package:flutter/rendering.dart';

class ImagesFeed extends StatefulWidget {
  static String tag = 'ímages-feed';
  @override
  _ImagesFeedState createState() => new _ImagesFeedState();
}

class _ImagesFeedState extends State<ImagesFeed> {
  // Controller to hide the action button programatically.
  ScrollController? _scrollController;
  bool? _hideFAB;

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();
    _scrollController!.addListener(() {
      setState(() {
        this._hideFAB = _scrollController!.position.userScrollDirection !=
            ScrollDirection.forward;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Hello world!'),
        ),
        // body: Container()
        body: ListView(
          controller: this._scrollController,
          children: [],
        ),
        floatingActionButton: (this._hideFAB ?? false)
            ? null
            : FloatingActionButton(
                child: Icon(Icons.add_a_photo_outlined),
                onPressed: () {},
              ));
  }

  @override
  void dispose() {
    _scrollController?.dispose();
    super.dispose();
  }
}
