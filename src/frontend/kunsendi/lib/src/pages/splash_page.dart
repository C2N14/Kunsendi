import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:kunsendi/src/pages/home_page.dart';
import 'package:kunsendi/src/pages/images_feed.dart';

import '../globals.dart';
import '../utils.dart';
import '../widgets/home_logo.dart';
import '../widgets/loading_indicator.dart';
import 'package:flutter/material.dart';

class SplashPage extends StatefulWidget {
  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool? _loading;

  @override
  void initState() {
    super.initState();
    // this._loading = true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Make sure logo is already loaded
    precacheImage(AssetImage(HomeLogo.assetName), this.context);

    // Start the session check.
    _tryRestartSession();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.deepPurple[800],
        body: Stack(
          children: [
            Center(child: HomeLogo()),
            Visibility(
                visible: this._loading ?? false, child: LoadingOverlay()),
          ],
        ));
  }

  Future<void> _tryRestartSession() async {
    // Hide the loading circle indicator and retry button.
    setState(() {
      this._loading = true;
    });

    final firstTime = !AppGlobals.localStorage!.containsKey('selected_api_uri');
    final loggedOut = firstTime
        ? false
        : (AppGlobals.localStorage!.containsKey('logged_out') &&
            (AppGlobals.localStorage!.getBool('logged_out') ?? true));

    // Disable "logged out" flag for future
    AppGlobals.localStorage!.setBool('logged_out', false);

    bool validSession = false;
    if (!firstTime && !loggedOut) {
      try {
        validSession = await ApiClient.getInstance().initSession();
      } on TimeoutException {}
    }

    // Hide the loading circle indicator.
    setState(() {
      this._loading = false;
    });

    // Session acquiring successful.
    if (validSession) {
      // Skip home page.
      Navigator.pushReplacement(
          this.context, MaterialPageRoute(builder: (context) => ImagesFeed()));

      // Show a snackbar in the new page.
      SchedulerBinding.instance?.addPostFrameCallback((_) {
        ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(
            content: Text(
                'Logged in as ${AppGlobals.localStorage!.getString('logged_username')}.')));
      });
    }
    // Either logged out manually, or never had session.
    else {
      if (loggedOut) {
        ScaffoldMessenger.of(this.context)
            .showSnackBar(SnackBar(content: Text('Successfully logged out.')));
      }
      // Go to home page.
      Navigator.pushReplacement(
          this.context, MaterialPageRoute(builder: (context) => HomePage()));
    }
  }
}
