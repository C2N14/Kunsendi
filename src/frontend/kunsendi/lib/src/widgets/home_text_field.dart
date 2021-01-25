import 'package:flutter/material.dart';

import '../app_styles.dart';

class HomeTextField extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextFormField(
        autocorrect: false,
        autofocus: false,
        enableSuggestions: false,
        keyboardType: this.keyboardType,
        obscureText: this.obscureText,
        validator: this.validator ?? (value) => null,
        onChanged: this.onChanged ?? (value) => null,
        decoration: InputDecoration(
          hintText: this.hintText,
          filled: true,
          fillColor: Theme.of(context).scaffoldBackgroundColor,
          hintStyle: Theme.of(context).textTheme.homeHintTextStyle,
          contentPadding: EdgeInsets.fromLTRB(35.0, 20.0, 35.0, 20.0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24.0),
          ),
        ));
  }

  @override
  HomeTextField(
      {Key key,
      this.keyboardType = TextInputType.text,
      this.hintText,
      this.obscureText = false,
      this.validator,
      this.onChanged})
      : super(key: key);
  final TextInputType keyboardType;
  final String hintText;
  final bool obscureText;
  final Function validator;
  final Function onChanged;
}
