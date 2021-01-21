import 'package:flutter/material.dart';
import 'app_styles.dart';

class LoginPage extends StatefulWidget {
  static String tag = 'login-page';
  @override
  _LoginPageState createState() => new _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    Widget _logo() {
      return MiscWidgets.homePageLogo;
    }

    Widget _usernameField() {
      return TextFormField(
        keyboardType: TextInputType.text,
        autofocus: false,
        decoration: InputDecoration(
          filled: true,
          fillColor: MiscStyling.homeFieldColor,
          hintText: 'Username',
          hintStyle: Theme.of(context).textTheme.homeHintTextStyle,
          contentPadding: MiscStyling.homeFieldPadding,
          border:
              OutlineInputBorder(borderRadius: MiscStyling.homeWidgetRadius),
        ),
      );
    }

    Widget _passwordField() {
      return TextFormField(
        keyboardType: TextInputType.visiblePassword,
        autofocus: false,
        obscureText: true,
        decoration: InputDecoration(
          filled: true,
          fillColor: MiscStyling.homeFieldColor,
          hintText: 'Password',
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
          // TODO: do something;
        },
        padding: MiscStyling.homeButtonPadding,
        color: MiscStyling.homeButtonColor,
        child: Text('LOG IN',
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
            _usernameField(),
            SizedBox(height: 18.0),
            _passwordField(),
            SizedBox(height: 56.0),
            _loginButton(),
          ],
        ),
      ),
    );
  }
}
