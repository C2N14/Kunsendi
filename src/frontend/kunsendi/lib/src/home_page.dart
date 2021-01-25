import 'dart:io';

import 'package:flutter/material.dart';
import 'login_page.dart';
import 'register_page.dart';
import 'package:http/http.dart' as http;

import 'widgets/home_logo.dart';
import 'widgets/home_button.dart';
import 'widgets/home_text_field.dart';
import 'widgets/home_loading.dart';
// import 'globals.dart' as globals;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  static String tag = 'login-page';
  @override
  _HomePageState createState() => new _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  Uri _serverApiUri;

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
                    hintText: 'Server hostname',
                    keyboardType: TextInputType.url,
                    validator: (String value) {
                      if (value.isEmpty) {
                        return 'Please enter a hostname';
                      }

                      // Strip trailing slash (is there really no better way to do this with dart?).
                      final hostname = (value[value.length - 1] == '/')
                          ? value.substring(0, value.length - 1)
                          : value;

                      // This is used to figure out if the hostname has a scheme specified.
                      final splitUri = hostname.split('://');

                      Uri parsedUri;
                      try {
                        // TODO: change this to https by default?
                        parsedUri = (splitUri.length == 2)
                            ? Uri(
                                scheme: splitUri[0],
                                host: splitUri[1],
                                path: '/api')
                            : Uri(scheme: 'http', host: hostname, path: '/api');
                      } on FormatException catch (_) {
                        return 'Invalid hostname format';
                      }

                      // Maybe this souldn't happen here, but I can't seem to find
                      // another effective way to achieve this.
                      setState(() {
                        this._serverApiUri = parsedUri;
                      });
                    },
                  ),
                  SizedBox(height: 56.0),
                  HomeButton(
                    heroTag: 'login_button',
                    text: 'LOG IN',
                    onPressed: () {
                      if (_formKey.currentState.validate()) {
                        _validateApiUri(
                            context: context,
                            pageBuilder: (context) => LoginPage());
                      }
                    },
                  ),
                  SizedBox(height: 20.0),
                  HomeButton(
                    heroTag: 'register_button',
                    text: 'REGISTER',
                    onPressed: () {
                      if (_formKey.currentState.validate()) {
                        _validateApiUri(
                            context: context,
                            pageBuilder: (context) => RegisterPage());
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
          )
        ]));
  }

  Future<bool> _validApiResponse(Uri serverApiUri) async {
    http.Response response;
    try {
      response = await http.get('$serverApiUri/v1/status');
    } on FormatException catch (_) {
      return false;
    } on SocketException catch (_) {
      return false;
    }

    Map<String, dynamic> payload;
    try {
      payload = jsonDecode(response.body);
    } on FormatException catch (_) {
      return false;
    }

    return response.statusCode == HttpStatus.ok &&
        payload.containsKey('uptime');
  }

  Future<void> _validateApiUri(
      {BuildContext context, Function pageBuilder}) async {
    // Display the loading circle indicator.
    setState(() {
      this._loading = true;
    });

    final validApi = await _validApiResponse(this._serverApiUri);

    // Hide the loading circle indicator.
    setState(() {
      this._loading = false;
    });

    if (!validApi) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Couldn\'t validate hostname.\nVerify your input or try with a different one.',
          ),
          actions: <Widget>[
            FlatButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pop();
                }),
          ],
        ),
      );
    } else {
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('selected_api_uri', this._serverApiUri.toString());

      Navigator.push(context, MaterialPageRoute(builder: pageBuilder));
    }
  }
}
