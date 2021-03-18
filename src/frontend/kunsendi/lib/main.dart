import 'package:flutter/material.dart';
import 'package:kunsendi/src/widgets/home_button.dart';
// import 'package:kunsendi/src/widgets/app_alert_dialog.dart';

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
    return SplashPage();
  }
}
