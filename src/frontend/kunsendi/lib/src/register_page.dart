import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kunsendi/src/login_page.dart';
import 'package:kunsendi/src/widgets/app_alert_dialog.dart';
import 'package:kunsendi/src/widgets/home_logo.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'widgets/home_button.dart';
import 'widgets/home_loading.dart';
import 'widgets/home_text_field.dart';

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

  final _usernameController = TextEditingController();
  String _checkedUsername;
  bool _usernameIsAvailable;
  Timer _usernameDebounce;

  // Checks if there is a username collision with the server.
  void _checkUsernameCollision() async {
    if (this._usernameDebounce?.isActive ?? false) {
      this._usernameDebounce.cancel();
    }
    this._usernameDebounce = Timer(Duration(milliseconds: 750), () async {
      final checkedUsername = _usernameController.value.text;
      final apiUri =
          (await SharedPreferences.getInstance()).getString('selected_api_uri');
      final response = await http
          .get('$apiUri/v1/auth/users/${_usernameController.value.text}');
      final payload = json.decode(response.body);

      // Cancel if value changed in the meantime.
      if (checkedUsername != _usernameController.value.text) {
        return;
      }

      setState(() {
        this._checkedUsername = checkedUsername;
        this._usernameIsAvailable = payload['available'];
      });
    });
  }

  Widget _usernameField() {
    return HomeTextField(
      hintText: 'Username',
      keyboardType: TextInputType.text,
      controller: _usernameController,
      validator: (String value) {
        if (value.isEmpty) {
          return 'Please enter a username';
        } else if (value.length < 4 || value.length > 16) {
          return 'Invalid username length';
        } else if (!_usernameRegexp.hasMatch(value)) {
          return 'Invalid username';
        } else if (value != _checkedUsername) {
          _checkUsernameCollision();
          return 'Validating username...';
        }
        return _usernameIsAvailable ? null : 'Username already taken';
      },
      onChanged: (String value) {
        setState(() {
          this._username = value;
        });
      },
    );
  }

  Widget _emailField() {
    return HomeTextField(
        hintText: 'Email',
        keyboardType: TextInputType.emailAddress,
        validator: (String value) {
          if (value.isEmpty) {
            return 'Please enter an email';
          } else if (value.length > 255) {
            return 'Invalid email length';
          } else if (!_emailRegexp.hasMatch(value)) {
            return 'Invalid email format';
          } else {
            // final prefs = await
          }
        },
        onChanged: (String value) {
          setState(() {
            this._email = value;
          });
        });
  }

  Widget _passwordField() {
    return HomeTextField(
      hintText: 'Password',
      keyboardType: TextInputType.visiblePassword,
      obscureText: true,
      validator: (String value) {
        if (value.isEmpty) {
          return 'Please enter a password';
        } else if (value.length < 8 || value.length > 128) {
          return 'Invalid password length';
        }
      },
      onChanged: (String value) {
        setState(() {
          this._password = value;
        });
      },
    );
  }

  Widget _passwordConfirmationField() {
    return HomeTextField(
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
    );
  }

  Widget _registerButton() {
    return HomeButton(
      heroTag: 'register_button',
      text: 'REGISTER',
      onPressed: () {
        if (_formKey.currentState.validate()) {
          _register(context: context, pageBuilder: (context) => LoginPage());
        }
      },
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.deepPurple[800],
        body: Stack(children: <Widget>[
          Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.always,
            child: Center(
              child: ListView(
                shrinkWrap: true,
                physics: BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(28.0, 40.0, 28.0, 40.0),
                children: <Widget>[
                  HomeLogo(),
                  SizedBox(height: 64.0),
                  _usernameField(),
                  SizedBox(height: 18.0),
                  _emailField(),
                  SizedBox(height: 18.0),
                  _passwordField(),
                  SizedBox(height: 18.0),
                  _passwordConfirmationField(),
                  SizedBox(height: 56.0),
                  _registerButton(),
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

  @override
  void dispose() {
    super.dispose();

    this._usernameController.dispose();
    this._usernameDebounce.cancel();
  }

  Future<void> _register({BuildContext context, Function pageBuilder}) async {
    // Display the loading circle indicator.
    setState(() {
      this._loading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final apiUri = prefs.getString('selected_api_uri');

    final response = await http.post('$apiUri/v1/auth/users',
        body: json.encode({
          'username': this._username,
          'email': this._email,
          'password': this._password,
        }),
        headers: {'Content-type': 'application/json'});

    final registered = response.statusCode == HttpStatus.created;

    // Hide the loading circle indicator.
    setState(() {
      this._loading = false;
    });

    if (!registered) {
      showDialog(
          context: context,
          builder: (context) => AppAlertDialog(
                text:
                    'There was an error with the request.\nVerify your input and try again.',
              ));
    } else {
      prefs.setString('username', this._username);

      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: pageBuilder));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Successfully registered.'),
      ));
    }
  }
}
