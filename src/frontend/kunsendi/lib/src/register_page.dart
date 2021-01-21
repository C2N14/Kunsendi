import 'package:flutter/material.dart';
import 'app_styles.dart';

class RegisterPage extends StatefulWidget {
  static String tag = 'login-page';
  @override
  _RegisterPageState createState() => new _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
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

    Widget _emailField() {
      return TextFormField(
        keyboardType: TextInputType.emailAddress,
        autofocus: false,
        decoration: InputDecoration(
          filled: true,
          fillColor: MiscStyling.homeFieldColor,
          hintText: 'Email',
          hintStyle: Theme.of(context).textTheme.homeHintTextStyle,
          contentPadding: MiscStyling.homeFieldPadding,
          border:
              OutlineInputBorder(borderRadius: MiscStyling.homeWidgetRadius),
        ),
      );
    }

    Widget _passwordField() {
      return TextFormField(
        keyboardType: TextInputType.emailAddress,
        autofocus: false,
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

    Widget _confirmPasswordField() {
      return TextFormField(
        keyboardType: TextInputType.emailAddress,
        autofocus: false,
        decoration: InputDecoration(
          filled: true,
          fillColor: MiscStyling.homeFieldColor,
          hintText: 'Confirm password',
          hintStyle: Theme.of(context).textTheme.homeHintTextStyle,
          contentPadding: MiscStyling.homeFieldPadding,
          border:
              OutlineInputBorder(borderRadius: MiscStyling.homeWidgetRadius),
        ),
      );
    }

    Widget _registerButton() {
      return RaisedButton(
        shape: RoundedRectangleBorder(
          borderRadius: MiscStyling.homeWidgetRadius,
        ),
        onPressed: () {
          // TODO: do something;
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
            _usernameField(),
            SizedBox(height: 18.0),
            _emailField(),
            SizedBox(height: 18.0),
            _passwordField(),
            SizedBox(height: 18.0),
            _confirmPasswordField(),
            SizedBox(height: 56.0),
            _registerButton(),
          ],
        ),
      ),
    );
  }
}
