import 'package:flutter/material.dart';

class AppAlertDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(title: Text(this.text), actions: [
      TextButton(
          child: Text('OK'),
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
          })
    ]);
  }

  @override
  const AppAlertDialog({Key? key, required this.text}) : super(key: key);
  final String text;
}
