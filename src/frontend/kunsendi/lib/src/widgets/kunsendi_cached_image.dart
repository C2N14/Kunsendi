import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/image_data.dart';
import '../utils.dart';

class KunsendiCachedImage extends StatelessWidget {
  @override
  KunsendiCachedImage({Key? key, required this.imageData})
      : _placeholder = AspectRatio(
            aspectRatio: imageData.width / imageData.height,
            child: Center(child: CircularProgressIndicator())),
        super(key: key);

  final ImageData imageData;
  final Widget _placeholder;

  // Note that in CachedNetworkImage imageUrl is actually the filename.
  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: this.imageData.filename,
      child: CachedNetworkImage(
          // cacheManager: _KunsendiCacheManager(),
          imageUrl: 'this.imageData.filename',
          placeholder: (context, url) => this._placeholder),
    );
  }
}

// // This is an AWFUL way to try to make CachedNetworkImage use the ApiClient,
// // but since WebClient is not exposed (https://github.com/Baseflow/flutter_cache_manager/issues/101)
// // some trickery in overriding the methods related to downloading files.
// // Most likely, this is not nearly as efficient as the original implementation,
// // but for the time being it will do.
// class _KunsendiCacheManager extends CacheManager with ImageCacheManager {
//   static const key = 'kunsendiCachedImageData';

//   final Duration 

//   static final _KunsendiCacheManager _instance = _KunsendiCacheManager._();
//   factory _KunsendiCacheManager() {
//     return _instance;
//   }

//   _KunsendiCacheManager._()
//       : super(Config(
//           key,
//         ));

//   @override
//   Future<FileInfo> downloadFile(String filename,
//       {String? key,
//       Map<String, String>? authHeaders,
//       bool force = false}) async {
//     // key ??= filename;

//     final response = await ApiClient.getInstance().getImage(filename);

//     return FileInfo(
//       File(response.payload), FileSource.Online, DateTime.now().add(maxAge)
//     );
//   }
// }


