import 'package:flutter/material.dart';

import '../app_styles.dart';

class HomeButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Hero(
        tag: this.heroTag,
        child: RaisedButton(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0),
          ),
          onPressed: () {
            this.onPressedFunction();
          },
          padding: EdgeInsets.all(20.0),
          color: Colors.deepPurpleAccent,
          child: Text(this.text,
              style: Theme.of(context).textTheme.homeButtonTextStyle),
        ));
  }

  @override
  const HomeButton({Key key, this.text, this.heroTag, this.onPressedFunction})
      : super(key: key);
  final String text;
  final String heroTag;
  final Function onPressedFunction;
}
