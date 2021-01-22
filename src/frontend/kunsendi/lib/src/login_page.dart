import 'package:flutter/material.dart';
import 'package:kunsendi/src/widgets/home_logo.dart';

import 'widgets/home_button.dart';
import 'widgets/home_text_field.dart';
import 'widgets/home_loading.dart';

class LoginPage extends StatefulWidget {
  static String tag = 'login-page';
  @override
  _LoginPageState createState() => new _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
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
                    hintText: 'Password',
                    inputType: TextInputType.visiblePassword,
                    obscure: true),
                SizedBox(height: 56.0),
                HomeButton(
                  heroTag: 'login_button',
                  onPressedFunction: () {
                    // TODO: do something
                  },
                  text: 'LOG IN',
                ),
              ],
            ),
          ),
          HomeLoadingOverlay(),
        ]));
  }
}
