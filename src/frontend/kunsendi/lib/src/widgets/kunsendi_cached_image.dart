import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../globals.dart';
import '../models/image_data.dart';

class KunsendiCachedImage extends StatelessWidget {
  @override
  const KunsendiCachedImage({Key? key, required this.imageData})
      : super(key: key);
  final ImageData imageData;

  @override
  Widget build(BuildContext context) {
    return Hero(
        tag: this.imageData.filename,
        child: CachedNetworkImage(
          imageUrl:
              '${AppGlobals.localStorage!.getString('selected_api_uri')}/v1/images/${this.imageData.filename}',
          placeholder: (context, url) => AspectRatio(
            aspectRatio: this.imageData.width / this.imageData.height,
            child: Center(child: CircularProgressIndicator()),
          ),
        ));
  }
}
