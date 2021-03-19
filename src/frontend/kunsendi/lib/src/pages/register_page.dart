import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:kunsendi/src/utils.dart';

import '../globals.dart';
import '../widgets/app_alert_dialog.dart';
import '../widgets/home_button.dart';
import '../widgets/home_loading.dart';
import '../widgets/home_logo.dart';
import '../widgets/home_text_field.dart';
import 'login_page.dart';

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

  String? _username;
  String? _email;
  String? _password;

  final _usernameController = TextEditingController();
  String? _checkedUsername;
  bool? _usernameIsAvailable;
  Timer? _usernameDebounce;

  // Checks if there is a username collision with the server.
  void _checkUsernameCollision() async {
    // Debounce to reduce server load.
    this._usernameDebounce?.cancel();
    this._usernameDebounce = Timer(Duration(milliseconds: 750), () async {
      final checkedUsername = _usernameController.value.text;
      final response =
          await ApiClient.getInstance().getUsernameAvailable(checkedUsername);

      // Cancel if value changed in the meantime.
      if (checkedUsername != _usernameController.value.text) {
        return;
      }

      setState(() {
        this._checkedUsername = checkedUsername;
        this._usernameIsAvailable = response.payload['available'];
      });
    });
  }

  Widget _usernameField() {
    return HomeTextField(
      hintText: 'Username',
      keyboardType: TextInputType.text,
      controller: _usernameController,
      validator: (String? value) {
        if (value?.isEmpty ?? true) {
          return 'Please enter a username';
        } else if (value!.length < 4 || value.length > 16) {
          return 'Invalid username length';
        } else if (!_usernameRegexp.hasMatch(value)) {
          return 'Invalid username';
        } else if (value != _checkedUsername) {
          _checkUsernameCollision();
          return 'Validating username...';
        }
        return (_usernameIsAvailable ?? true) ? null : 'Username already taken';
      },
      onChanged: (String? value) {
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
        validator: (String? value) {
          if (value?.isEmpty ?? true) {
            return 'Please enter an email';
          } else if (value!.length > 255) {
            return 'Invalid email length';
          } else if (!_emailRegexp.hasMatch(value)) {
            return 'Invalid email format';
          }
        },
        onChanged: (String? value) {
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
      validator: (String? value) {
        if (value?.isEmpty ?? true) {
          return 'Please enter a password';
        } else if (value!.length < 8 || value.length > 128) {
          return 'Invalid password length';
        }
      },
      onChanged: (String? value) {
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
      validator: (String? value) {
        if (value?.isEmpty ?? true) {
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
        if (this._formKey.currentState?.validate() ?? false) {
          this._formKey.currentState?.save();
          this._register(pageBuilder: (context) => LoginPage());
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.deepPurple[800],
        body: Stack(children: <Widget>[
          Form(
            key: this._formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
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
    this._usernameDebounce?.cancel();
  }

  Future<void> _register(
      {required Widget Function(BuildContext) pageBuilder}) async {
    // Display the loading circle indicator.
    setState(() {
      this._loading = true;
    });

    ApiResponse? response;
    try {
      response = await ApiClient.getInstance()
          .register(this._username!, this._email!, this._password!);
    } on TimeoutException {}

    // Hide the loading circle indicator.
    setState(() {
      this._loading = false;
    });

    if (response?.statusCode != HttpStatus.created) {
      String dialogText;

      // Different text depending on the response.
      switch (response?.statusCode) {
        // Different text depending on the response.
        case HttpStatus.internalServerError:
          dialogText = 'There was an error with the server request.';
          break;
        case null:
          dialogText = "Couldn't establish connection to the server.";
          break;
        default:
          dialogText =
              "There was an error with the request.\nVerify your input and try again.";
      }

      showDialog(
          context: this.context,
          builder: (context) => AppAlertDialog(text: dialogText));
    } else {
      AppGlobals.localStorage!.setString('username', this._username ?? '');

      // Go to the login page.
      Navigator.pushReplacement(
          this.context, MaterialPageRoute(builder: pageBuilder));

      // Show a snackbar in the login page.
      SchedulerBinding.instance?.addPostFrameCallback((_) {
        ScaffoldMessenger.of(this.context)
            .showSnackBar(SnackBar(content: Text('Successfully registered.')));
      });
    }
  }
}
