import 'package:flutter/material.dart';
import 'package:kunsendi/src/widgets/home_logo.dart';

import 'widgets/home_button.dart';
import 'widgets/home_text_field.dart';
import 'widgets/home_loading.dart';

class RegisterPage extends StatefulWidget {
  static String tag = 'login-page';
  @override
  _RegisterPageState createState() => new _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.deepPurple[800],
        body: Stack(children: <Widget>[
          Center(
            child: ListView(
              shrinkWrap: true,
              physics: BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(28.0, 40.0, 28.0, 40.0),
              children: <Widget>[
                HomeLogo(),
                SizedBox(height: 64.0),
                HomeTextField(
                  hintText: 'Username',
                  inputType: TextInputType.text,
                ),
                SizedBox(height: 18.0),
                HomeTextField(
                  hintText: 'Email',
                  inputType: TextInputType.emailAddress,
                ),
                SizedBox(height: 18.0),
                HomeTextField(
                  hintText: 'Password',
                  inputType: TextInputType.visiblePassword,
                  obscure: true,
                ),
                SizedBox(height: 18.0),
                HomeTextField(
                  hintText: 'Confirm password',
                  inputType: TextInputType.visiblePassword,
                  obscure: true,
                ),
                SizedBox(height: 56.0),
                HomeButton(
                  heroTag: 'register_button',
                  onPressedFunction: () {
                    // TODO: do something
                  },
                  text: 'REGISTER',
                ),
              ],
            ),
          ),
          HomeLoadingOverlay(),
        ]));
  }
}
