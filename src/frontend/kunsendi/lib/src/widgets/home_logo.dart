import 'package:flutter/material.dart';

class HomeLogo extends StatelessWidget {
  static const assetName = 'assets/logo.png';

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'logo',
      child: CircleAvatar(
        backgroundColor: Colors.transparent,
        radius: 80.0,
        child: Image.asset(assetName),
      ),
    );
  }
}
