import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kunsendi/src/widgets/kunsendi_cached_image.dart';

class ImageCard extends StatefulWidget {
  @override
  _ImageCardState createState() => _ImageCardState();

  @override
  ImageCard({Key? key, required this.image}) : super(key: key);
  final KunsendiCachedImage image;
}

class _ImageCardState extends State<ImageCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          this.widget.image,
          ListTile(
            title: Text(this.widget.image.imageData.uploader),
            subtitle: Text(
              DateFormat('yyyy-MM-dd — kk:mm')
                  .format(this.widget.image.imageData.uploadDate)
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
