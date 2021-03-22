class ImageData {
  const ImageData(
      {required this.filename,
      required this.uploader,
      required this.uploadDate,
      required this.width,
      required this.height});

  // Note that Dart doesn't support decoding a DateTime from a double, so it must
  // be rounded.
  factory ImageData.fromJson(Map<String, dynamic> json) => ImageData(
        filename: json['filename'],
        uploader: json['uploader'],
        uploadDate: DateTime.fromMillisecondsSinceEpoch(json['upload_date'],
            isUtc: true),
        width: json['width'],
        height: json['height'],
      );

  final String filename;
  final String uploader;
  final DateTime uploadDate;
  final int width;
  final int height;
}
