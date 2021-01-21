import 'package:flutter/material.dart';
import 'app_styles.dart';
import 'login_page.dart';
import 'register_page.dart';

class HomePage extends StatefulWidget {
  static String tag = 'login-page';
  @override
  _HomePageState createState() => new _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    Widget _logo() {
      return MiscWidgets.homePageLogo;
    }

    Widget _hostnameField() {
      return TextFormField(
        keyboardType: TextInputType.url,
        autofocus: false,
        decoration: InputDecoration(
          filled: true,
          fillColor: MiscStyling.homeFieldColor,
          hintText: 'Server Hostname',
          hintStyle: Theme.of(context).textTheme.homeHintTextStyle,
          contentPadding: MiscStyling.homeFieldPadding,
          border:
              OutlineInputBorder(borderRadius: MiscStyling.homeWidgetRadius),
        ),
      );
    }

    Widget _loginButton() {
      return RaisedButton(
        shape: RoundedRectangleBorder(
          borderRadius: MiscStyling.homeWidgetRadius,
        ),
        onPressed: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => LoginPage()));
        },
        padding: MiscStyling.homeButtonPadding,
        color: MiscStyling.homeButtonColor,
        child: Text('LOG IN',
            style: Theme.of(context).textTheme.homeButtonTextStyle),
      );
    }

    Widget _registerButton() {
      return RaisedButton(
        shape: RoundedRectangleBorder(
          borderRadius: MiscStyling.homeWidgetRadius,
        ),
        onPressed: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => RegisterPage()));
        },
        padding: MiscStyling.homeButtonPadding,
        color: MiscStyling.homeButtonColor,
        child: Text('REGISTER',
            style: Theme.of(context).textTheme.homeButtonTextStyle),
      );
    }

    return Scaffold(
      backgroundColor: MiscStyling.homePageColor,
      body: Center(
        child: ListView(
          shrinkWrap: true,
          physics: BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(28.0, 50.0, 28.0, 50.0),
          children: <Widget>[
            _logo(),
            SizedBox(height: 64.0),
            _hostnameField(),
            SizedBox(height: 56.0),
            _loginButton(),
            SizedBox(height: 20.0),
            _registerButton(),
          ],
        ),
      ),
    );
  }
}
