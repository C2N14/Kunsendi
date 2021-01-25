// import 'globals.dart' as globals;
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:kunsendi/src/widgets/home_logo.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'images_feed.dart';
import 'widgets/home_button.dart';
import 'widgets/home_loading.dart';
import 'widgets/home_text_field.dart';

class LoginPage extends StatefulWidget {
  static String tag = 'login-page';
  @override
  _LoginPageState createState() => new _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  String _username;
  String _password;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.deepPurple[800],
        body: Stack(children: <Widget>[
          Form(
            key: this._formKey,
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
                  SizedBox(height: 56.0),
                  HomeButton(
                    heroTag: 'login_button',
                    text: 'LOG IN',
                    onPressed: () {
                      if (_formKey.currentState.validate()) {
                        _logIn(
                            context: context,
                            pageBuilder: (context) => ImagesFeed());
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

  Future<void> _logIn({BuildContext context, Function pageBuilder}) async {
    // Display the loading circle indicator.
    setState(() {
      this._loading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final apiUri = prefs.getString('selected_api_uri');

    final response = await http.post('$apiUri/v1/auth/sessions',
        body: json.encode({
          'username': this._username,
          'password': this._password,
        }),
        headers: {'Content-type': 'application/json'});

    bool loggedIn = false, requestError = false;
    Map<String, dynamic> payload;

    if (response.statusCode == HttpStatus.created) {
      try {
        payload = json.decode(response.body);

        loggedIn = payload.containsKey('access_token') &&
            payload.containsKey('refresh_token');
      } on FormatException catch (_) {
        requestError = true;
      }
    }

    // Hide the loading circle indicator.
    setState(() {
      this._loading = false;
    });

    if (!loggedIn) {
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                  title: Text(
                    requestError
                        ? 'There was an error with the server request.'
                        : 'Couldn\'t verify credentials.\nVerify your input and try again.',
                  ),
                  actions: <Widget>[
                    FlatButton(
                        child: Text('OK'),
                        onPressed: () {
                          Navigator.of(context, rootNavigator: true).pop();
                        })
                  ]));
    } else {
      // Securely save the returned tokens.
      final secureStorage = FlutterSecureStorage();
      for (var token in <String>['access_token', 'refresh_token']) {
        await secureStorage.write(key: token, value: payload[token]);
      }

      Navigator.push(context, MaterialPageRoute(builder: pageBuilder));
    }
  }
}
