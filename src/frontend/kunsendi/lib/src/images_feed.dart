import 'package:flutter/material.dart';

import 'models/image_data.dart';
import 'widgets/image_card.dart';

class ImagesFeed extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hello world!'),
      ),
      body: ListView(
        children: [
          ImageCard(
              imageData: ImageData(
                  author: 'pogo',
                  url:
                      'https://assets.pogo.org/image/content/2020/FDA_Panel_Reviewing_Pfizer_Vaccine_Excludes_Some_Experts_1150.jpg?mtime=20201209202119',
                  published: DateTime.now())),
          ImageCard(
              imageData: ImageData(
                  author: 'bigstock',
                  url:
                      'https://p.bigstockphoto.com/GeFvQkBbSLaMdpKXF1Zv_bigstock-Aerial-View-Of-Blue-Lakes-And--227291596.jpg',
                  published: DateTime.now())),
          ImageCard(
              imageData: ImageData(
                  author: 'arstechnica',
                  url:
                      'https://cdn.arstechnica.net/wp-content/uploads/2016/02/5718897981_10faa45ac3_b-640x624.jpg',
                  published: DateTime.now())),
          ImageCard(
              imageData: ImageData(
                  author: 'sproutsocial',
                  url:
                      'https://media.sproutsocial.com/uploads/2017/02/10x-featured-social-media-image-size.png',
                  published: DateTime.now())),
        ],
      ),
    );
  }
}
