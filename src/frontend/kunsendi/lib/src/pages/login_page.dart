import 'dart:io';

import 'package:flutter/material.dart';

import '../globals.dart';
import '../widgets/app_alert_dialog.dart';
import '../widgets/home_button.dart';
import '../widgets/home_loading.dart';
import '../widgets/home_logo.dart';
import '../widgets/home_text_field.dart';
import 'images_feed.dart';
import '../utils.dart';

class LoginPage extends StatefulWidget {
  static String tag = 'login-page';
  @override
  _LoginPageState createState() => new _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  String? _username;
  String? _password;

  final _usernameController = TextEditingController();
  void _loadSavedUsername() async {
    // final prefs = await SharedPreferences.getInstance();
    final savedUsername = AppGlobals.localStorage!.getString('username');
    setState(() {
      _usernameController.text = savedUsername ?? '';
      this._username = savedUsername ?? '';
    });
  }

  Widget _usernameField() {
    return HomeTextField(
      hintText: 'Username',
      keyboardType: TextInputType.text,
      controller: this._usernameController,
      validator: (String? value) {
        if (value?.isEmpty ?? true) {
          return 'Please enter a username';
        }
      },
      onChanged: (String? value) {
        setState(() {
          this._username = value;
        });
      },
    );
  }

  Widget _passwordField() {
    return HomeTextField(
      hintText: 'Password',
      keyboardType: TextInputType.visiblePassword,
      obscureText: true,
      validator: (String? value) {
        if (value?.isEmpty ?? true) {
          return 'Please enter a password';
        }
      },
      onChanged: (String? value) {
        setState(() {
          this._password = value;
        });
      },
    );
  }

  Widget _loginButton() {
    return HomeButton(
        heroTag: 'login_button',
        text: 'LOG IN',
        onPressed: () {
          if (this._formKey.currentState?.validate() ?? false) {
            this._formKey.currentState?.save();
            _logIn(context: context, pageBuilder: (context) => ImagesFeed());
            // _logIn(context: context, closure: (context) => ImagesFeed());
          }
        });
  }

  @override
  void initState() {
    super.initState();

    _loadSavedUsername();
  }

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
                  _usernameField(),
                  SizedBox(height: 18.0),
                  _passwordField(),
                  SizedBox(height: 56.0),
                  _loginButton(),
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
    this._usernameController.dispose();

    super.dispose();
  }

  Future<void> _logIn(
      {required BuildContext context,
      required Widget Function(BuildContext) pageBuilder}) async {
    // Display the loading circle indicator.
    setState(() {
      this._loading = true;
    });

    final response = await ApiClient.getInstance()
        .login(this._username ?? '', this._password ?? '');

    // Hide the loading circle indicator.
    setState(() {
      this._loading = false;
    });

    if (response.statusCode != HttpStatus.created) {
      showDialog(
          context: context,
          builder: (context) => AppAlertDialog(
                text: response.statusCode == HttpStatus.internalServerError
                    ? 'There was an error with the server request.'
                    : 'Couldn\'t verify credentials.\nVerify your input and try again.',
              ));
    } else {
      // Securely save the returned tokens.
      await AppGlobals.secureStorage!
          .write(key: 'access_token', value: response.payload['access_token']);
      await AppGlobals.secureStorage!.write(
          key: 'refresh_token', value: response.payload['refresh_token']);
      AppGlobals.localStorage!
          .setString('logged_username', this._username ?? '');

      Navigator.push(context, MaterialPageRoute(builder: pageBuilder));
    }
  }
}
