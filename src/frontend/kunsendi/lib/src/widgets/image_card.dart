import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/image_data.dart';

import '../globals.dart';

class ImageCard extends StatefulWidget {
  @override
  const ImageCard({Key? key, required this.imageData}) : super(key: key);
  final ImageData imageData;

  @override
  _ImageCardState createState() => _ImageCardState();
}

class _ImageCardState extends State<ImageCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Image.network(
              '${AppGlobals.localStorage!.getString('selected_api_uri')}/v1/images/${widget.imageData.filename}'), // TODO: fix this
          ListTile(
            title: Text(widget.imageData.uploader),
            subtitle: Text(
              DateFormat('yyyy-MM-dd — kk:mm')
                  .format(widget.imageData.uploadDate)
                  .toString(),
              // style: TextStyle(color: Colors.black.withOpacity(0.6)),
            ),
          ),
        ],
      ),
      margin: EdgeInsets.all(15),
    );
  }
}
