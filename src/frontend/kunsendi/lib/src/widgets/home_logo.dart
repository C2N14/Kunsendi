import 'package:flutter/material.dart';

class HomeLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'logo',
      child: CircleAvatar(
        backgroundColor: Colors.transparent,
        radius: 80.0,
        child: Image.asset('assets/logo.png'),
      ),
    );
  }
}
