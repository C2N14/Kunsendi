import 'package:flutter/material.dart';
import 'package:kunsendi/src/login_page.dart';
import 'package:kunsendi/src/widgets/home_logo.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:convert';

import 'widgets/home_button.dart';
import 'widgets/home_text_field.dart';
import 'widgets/home_loading.dart';

import 'package:http/http.dart' as http;

class RegisterPage extends StatefulWidget {
  static String tag = 'login-page';
  @override
  _RegisterPageState createState() => new _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  // Same regexes as server.
  final _usernameRegexp = RegExp(r'^(?=.*[\w].*)([\w._-]*)$');
  final _emailRegexp = RegExp(r'^[^@]*@[^@]*$');

  String _username;
  String _email;
  String _password;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.deepPurple[800],
        body: Stack(children: <Widget>[
          Form(
            key: _formKey,
            child: Center(
              child: ListView(
                shrinkWrap: true,
                physics: BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(28.0, 40.0, 28.0, 40.0),
                children: <Widget>[
                  HomeLogo(),
                  SizedBox(height: 64.0),
                  HomeTextField(
                    hintText: 'Username',
                    keyboardType: TextInputType.text,
                    validator: (String value) {
                      if (value.isEmpty) {
                        return 'Please enter a username';
                      } else if (value.length < 4 || value.length > 16) {
                        return 'Enter a username between 4 and 16 characters';
                      } else if (!_usernameRegexp.hasMatch(value)) {
                        return 'Invalid username';
                      }
                    },
                    onChanged: (String value) {
                      setState(() {
                        this._username = value;
                      });
                    },
                  ),
                  SizedBox(height: 18.0),
                  HomeTextField(
                      hintText: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      validator: (String value) {
                        if (value.isEmpty) {
                          return 'Please enter an email';
                        } else if (value.length > 255) {
                          return 'Invalid email length';
                        } else if (!_emailRegexp.hasMatch(value)) {
                          return 'Invalid email format';
                        }
                      },
                      onChanged: (String value) {
                        setState(() {
                          this._email = value;
                        });
                      }),
                  SizedBox(height: 18.0),
                  HomeTextField(
                    hintText: 'Password',
                    keyboardType: TextInputType.visiblePassword,
                    obscureText: true,
                    validator: (String value) {
                      if (value.isEmpty) {
                        return 'Please enter a password';
                      }
                    },
                    onChanged: (String value) {
                      setState(() {
                        this._password = value;
                      });
                    },
                  ),
                  SizedBox(height: 18.0),
                  HomeTextField(
                    hintText: 'Confirm password',
                    keyboardType: TextInputType.visiblePassword,
                    obscureText: true,
                    validator: (String value) {
                      if (value.isEmpty) {
                        return 'Please confirm your password';
                      } else if (value != this._password) {
                        return 'Passwords do not match';
                      }
                    },
                  ),
                  SizedBox(height: 56.0),
                  HomeButton(
                    heroTag: 'register_button',
                    text: 'REGISTER',
                    onPressed: () {
                      if (_formKey.currentState.validate()) {
                        _register(
                            context: context,
                            pageBuilder: (context) => LoginPage());
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          Visibility(
            visible: this._loading,
            child: HomeLoadingOverlay(),
          ),
        ]));
  }

  Future<void> _register({BuildContext context, Function pageBuilder}) async {
    // Display the loading circle indicator.
    setState(() {
      this._loading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final apiUri = prefs.getString('selected_api_uri');

    final response = await http.post('$apiUri/v1/auth/sessions',
        body: json.encode({
          'username': this._username,
          'email': this._email,
          'password': this._password,
        }),
        headers: {'Content-type': 'application/json'});

    // TODO: the rest...

    // Hide the loading circle indicator.
    setState(() {
      this._loading = false;
    });
  }
}
