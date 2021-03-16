import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';

// import 'package:kunsendi/src/images_feed.dart';
import 'src/globals.dart';
import 'src/pages/home_page.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppGlobals.init();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Future<bool> _hasActiveSession;
  // Future<bool> _hasActiveSession = _checkActiveSession();

  @override
  void initState() {
    super.initState();

    _hasActiveSession = _checkActiveSession();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Kunsendi',
        theme: ThemeData(
          brightness: Brightness.light,
          primarySwatch: Colors.deepPurple,
        ),
        darkTheme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.deepPurple,
            accentColor: Colors.deepPurpleAccent),
        themeMode: ThemeMode.system,
        // debugShowCheckedModeBanner: false,
        home: FutureBuilder(
          // future: this._refreshedActiveSession(),
          builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {},
        )
        // home: ImagesFeed(),
        );
  }

  Future<bool> _checkActiveSession() async {
    // final refreshToken = await App.secureStorage.read(key: 'refresh_token');
    // final apiUri = App.localStorage.getString('selected_api_uri');

    // if (apiUri == null || refreshToken == null) {
    //   return false;
    // }

    // final response = http.get('$apiUri/auth/sessions');
    // final api
    // final refreshToken = await App.secureStorage.read(key: 'refresh_token');

    // if (refreshToken == null || JwtDecoder.isExpired(refreshToken)) {
    //   return false;
    // }
  }

  // Future<void> _refreshTokens() async {
  // final refreshToken = await App.secureStorage.read(key: 'refresh_token');
  // final apiUri = App.localStorage.getString('selected_api_uri');

  // final response = await http.get('${App.localStorage.getString('')}')
  // }

  // Future<void> _refreshSession() async {
  //   final
  // }
}
