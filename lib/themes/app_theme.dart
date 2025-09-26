import 'package:flutter/material.dart';
import 'package:mdbuddy/constants/fonts/app_fonts.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primarySwatch: Colors.blue,
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.white,
      fontFamily: AppFonts.CHOSUN_SG,
      textTheme: TextTheme(
        bodyMedium: TextStyle(
            fontSize: 16, color: Colors.black, fontFamily: AppFonts.CHOSUN_SG),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.deepPurple,
      scaffoldBackgroundColor: Colors.black,
      fontFamily: AppFonts.CHOSUN_SG,
      textTheme: TextTheme(
        bodyMedium: TextStyle(
            fontSize: 16, color: Colors.white, fontFamily: AppFonts.CHOSUN_SG),
      ),
    );
  }
}
