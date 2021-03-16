import 'package:flutter/material.dart';

import 'src/pages/images_feed.dart';
import 'src/globals.dart';

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
  late Future<bool?> _hasActiveSession;
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
          builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
            return ImagesFeed();
          },
        )
        // home: ImagesFeed(),
        );
  }

  Future<bool?> _checkActiveSession() async {
    //
  }
}
