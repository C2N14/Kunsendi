import 'package:flutter/material.dart';

import '../app_styles.dart';

class HomeTextField extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextFormField(
        keyboardType: this.inputType,
        autofocus: false,
        obscureText: this.obscure,
        decoration: InputDecoration(
          filled: true,
          fillColor: Theme.of(context).scaffoldBackgroundColor,
          hintText: this.hintText,
          hintStyle: Theme.of(context).textTheme.homeHintTextStyle,
          contentPadding: EdgeInsets.fromLTRB(35.0, 20.0, 35.0, 20.0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24.0),
          ),
        ));
  }

  @override
  HomeTextField({Key key, this.inputType, this.hintText, this.obscure = false})
      : super(key: key);
  final TextInputType inputType;
  final String hintText;
  final bool obscure;
}
