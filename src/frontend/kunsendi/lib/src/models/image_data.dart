class ImageData {
  const ImageData(
      {this.filename, this.uploader, this.uploadDate, this.width, this.height});
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
