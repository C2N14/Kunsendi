import 'package:flutter/material.dart';

import '../globals.dart';

class HomeButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Hero(
        tag: this.heroTag,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24.0),
            ),
            padding: EdgeInsets.all(20.0),
            primary: Colors.deepPurpleAccent,
          ),
          onPressed: this.onPressed,
          child: Text(this.text,
              style: Theme.of(context).textTheme.homeButtonTextStyle),
        ));
  }

  @override
  const HomeButton(
      {Key? key, this.text = '', required this.heroTag, this.onPressed})
      : super(key: key);
  final String text;
  final String heroTag;
  final void Function()? onPressed;
}
