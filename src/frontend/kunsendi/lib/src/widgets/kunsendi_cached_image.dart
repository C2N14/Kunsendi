import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/image_data.dart';
import '../utils.dart';

class KunsendiCachedImage extends StatelessWidget {
  @override
  KunsendiCachedImage({Key? key, required this.imageData}) : super(key: key);

  final ImageData imageData;

  /// Note that in this [CachedNetworkImage] [imageUrl] is actually the
  /// filename because of [ApiCacheManager].
  @override
  Widget build(BuildContext context) {
    return Hero(
        tag: this.imageData.filename,
        child: CachedNetworkImage(
          cacheManager: ApiCacheManager(),
          imageUrl: '${this.imageData.filename}',
          placeholder: (context, url) => AspectRatio(
              aspectRatio: imageData.width / imageData.height,
              child: Center(child: CircularProgressIndicator())),
        ));
  }
}
