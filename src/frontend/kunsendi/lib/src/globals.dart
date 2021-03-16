import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

extension AppTextStyles on TextTheme {
  TextStyle get homeButtonTextStyle => GoogleFonts.poppins(
      fontSize: 18.0, color: Colors.white, fontWeight: FontWeight.bold);
  TextStyle get homeHintTextStyle => TextStyle(color: Colors.grey[600]);
}

class AppGlobals {
  static SharedPreferences? localStorage;
  static FlutterSecureStorage? secureStorage;

  static Future<void> init() async {
    localStorage = await SharedPreferences.getInstance();
    secureStorage = FlutterSecureStorage();
  }
}
