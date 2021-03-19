import 'package:flutter/material.dart';

import 'src/globals.dart';
import 'src/pages/splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppGlobals.init();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
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
      home: SplashPage(),
    );
  }
}
