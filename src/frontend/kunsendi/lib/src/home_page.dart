import 'dart:io';

import 'package:flutter/material.dart';
import 'app_styles.dart';
import 'login_page.dart';
import 'register_page.dart';
import 'package:http/http.dart' as http;

import 'widgets/home_logo.dart';
import 'widgets/home_button.dart';
import 'widgets/home_text_field.dart';
import 'widgets/home_loading.dart';

class HomePage extends StatefulWidget {
  static String tag = 'login-page';
  @override
  _HomePageState createState() => new _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
                  hintText: 'Server hostname',
                  inputType: TextInputType.url,
                ),
                SizedBox(height: 56.0),
                HomeButton(
                  heroTag: 'login_button',
                  onPressedFunction: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => LoginPage()));
                  },
                  text: 'LOG IN',
                ),
                SizedBox(height: 20.0),
                HomeButton(
                  heroTag: 'register_button',
                  onPressedFunction: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => RegisterPage()));
                  },
                  text: 'REGISTER',
                ),
              ],
            ),
          ),
          HomeLoadingOverlay()
        ]));
  }

  Future<bool> _validHostname(String hostname) async {
    final response = await http.get(hostname);
    return response.statusCode == HttpStatus.ok;
  }
}
