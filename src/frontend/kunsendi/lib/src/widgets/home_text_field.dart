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
        initialValue: this.initialValue,
        validator: this.validator ?? (value) => null,
        onChanged: this.onChanged ?? (value) => null,
        controller: this.controller,
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
      this.initialValue,
      this.validator,
      this.onChanged,
      this.controller})
      : super(key: key);
  final TextInputType keyboardType;
  final String hintText;
  final bool obscureText;
  final String initialValue;
  final Function validator;
  final Function onChanged;
  final TextEditingController controller;
}
