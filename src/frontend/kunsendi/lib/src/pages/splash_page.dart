import 'package:kunsendi/src/widgets/app_alert_dialog.dart';

import '../globals.dart';
import '../utils.dart';
import '../widgets/home_logo.dart';
import '../widgets/home_loading.dart';
import 'package:flutter/material.dart';

class SplashPage extends StatefulWidget {
  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool? _loading;
  bool? _showRetry;

  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() async {
    super.initState();
    // this._loading = true;

    _tryRestartSession();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: this._scaffoldMessengerKey,
        backgroundColor: Colors.deepPurple[800],
        body: Container()
        // body: Stack(
        //   children: <Widget>[
        //     Center(child: HomeLogo()),
        //     Align(
        //         alignment: Alignment.bottomCenter,
        //         child: HomeButton(
        //           text: 'Retry',
        //           heroTag: 'retry',
        //         ))
        //   ],
        // )
        // home: ImagesFeed(),
        );
  }

  Future<void> _tryRestartSession() async {
    setState(() {
      this._loading = true;
      this._showRetry = false;
    });

    final firstTime = !AppGlobals.localStorage!.containsKey('selected_api_uri');
    final loggedOut = firstTime
        ? false
        : (AppGlobals.localStorage!.containsKey('logged_out') &&
            (AppGlobals.localStorage!.getBool('logged_out') ?? true));

    // Disable "logged out" flag for future
    AppGlobals.localStorage!.setBool('logged_out', false);

    bool validSession, error = false;
    try {
      validSession = firstTime
          ? false
          : await ApiClient.getInstance().initSession(multipleTries: true);
    } on ApiAuthException {
      validSession = false;
      error = true;
    }

    setState(() {
      this._loading = false;
    });

    final showSnack = (String text) => this
        ._scaffoldMessengerKey
        .currentState!
        .showSnackBar(SnackBar(content: Text(text)));

    if (!firstTime && !error) {
      if (!loggedOut && !validSession) {
        showSnack('Logged out because of inactivity.');
      } else if (loggedOut) {
        showSnack('Sucessfully logged out.');
      }
    } else if (error) {
      showDialog(
          context: this._scaffoldMessengerKey.currentContext!,
          builder: (context) => AppAlertDialog(
              text:
                  'There was an error connecting to the server.\nCheck your connection and try again.'));
      setState(() {
        this._showRetry = true;
      });
    }
  }
}
