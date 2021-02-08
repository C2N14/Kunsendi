import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kunsendi/src/widgets/app_alert_dialog.dart';

import '../globals.dart';
import '../widgets/home_button.dart';
import '../widgets/home_loading.dart';
import '../widgets/home_logo.dart';
import '../widgets/home_text_field.dart';
import 'login_page.dart';
import 'register_page.dart';

class HomePage extends StatefulWidget {
  static String tag = 'login-page';
  @override
  _HomePageState createState() => new _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  Uri _serverApiUri;

  final _hostnameController = TextEditingController();
  void _loadSavedHostname() async {
    // final prefs = await SharedPreferences.getInstance();
    // Strips the trailing /api path from the saved uri
    final savedHostname = App.localStorage
        .getString('selected_api_uri')
        ?.replaceAll(RegExp(r'\/api$'), '');
    setState(() {
      _hostnameController.text = savedHostname;
    });
  }

  Widget _hostnameField() {
    return HomeTextField(
      hintText: 'Server hostname',
      keyboardType: TextInputType.url,
      controller: _hostnameController,
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
              ? Uri(scheme: splitUri[0], host: splitUri[1], path: '/api')
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
    );
  }

  Widget _loginButton() {
    return HomeButton(
      heroTag: 'login_button',
      text: 'LOG IN',
      onPressed: () {
        if (this._formKey.currentState.validate()) {
          this._formKey.currentState.save();
          this._validateApiUri(
              context: context, pageBuilder: (context) => LoginPage());
        }
      },
    );
  }

  Widget _registerButton() {
    return HomeButton(
        heroTag: 'register_button',
        text: 'REGISTER',
        onPressed: () {
          if (this._formKey.currentState.validate()) {
            this._formKey.currentState.save();
            this._validateApiUri(
                context: context, pageBuilder: (context) => RegisterPage());
          }
        });
  }

  @override
  void initState() {
    super.initState();

    _loadSavedHostname();
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
                  _hostnameField(),
                  SizedBox(height: 56.0),
                  _loginButton(),
                  SizedBox(height: 20.0),
                  _registerButton(),
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

  @override
  void dispose() {
    this._hostnameController.dispose();

    super.dispose();
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
        builder: (context) => AppAlertDialog(
          text:
              'Couldn\'t validate hostname.\nVerify your input or try with a different one.',
        ),
      );
    } else {
      // final prefs = await SharedPreferences.getInstance();
      App.localStorage
          .setString('selected_api_uri', this._serverApiUri.toString());

      Navigator.push(
        context,
        MaterialPageRoute(builder: pageBuilder),
      );
      // closure(this._serverApiUri.toString());
    }
  }
}
