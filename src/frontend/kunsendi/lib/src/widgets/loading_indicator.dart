import 'package:flutter/material.dart';

class LoadingCircleIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          shape: BoxShape.circle),
      child: Center(
          child: SizedBox(
              width: 25, height: 25, child: CircularProgressIndicator())),
    );
  }
}

class LoadingOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
                padding: EdgeInsets.only(top: 30),
                child: LoadingCircleIndicator())));
  }
}
