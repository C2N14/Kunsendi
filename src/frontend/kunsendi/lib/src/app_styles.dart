import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

extension AppTextStyles on TextTheme {
  TextStyle get homeButtonTextStyle => GoogleFonts.poppins(
      fontSize: 18.0, color: Colors.white, fontWeight: FontWeight.bold);
  TextStyle get homeHintTextStyle => TextStyle(color: Colors.grey[600]);
}

class MiscStyling {
  static final homeWidgetRadius = BorderRadius.circular(24.0);

  static final homeButtonPadding = EdgeInsets.all(20.0);
  static final homeButtonColor = Colors.deepPurpleAccent;

  static final homeFieldPadding = EdgeInsets.fromLTRB(35.0, 20.0, 35.0, 20.0);
  static final homeFieldColor = Colors.white;

  static final homePageColor = Colors.deepPurple[800];
  static final homePageLogo = Hero(
    tag: 'hero',
    child: CircleAvatar(
      backgroundColor: Colors.transparent,
      radius: 80.0,
      child: Image.asset('assets/logo.png'),
    ),
  );
}

class MiscWidgets {
  static final homePageLogo = Hero(
    tag: 'hero',
    child: CircleAvatar(
      backgroundColor: Colors.transparent,
      radius: 80.0,
      child: Image.asset('assets/logo.png'),
    ),
  );
}
