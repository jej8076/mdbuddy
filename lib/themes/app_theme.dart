import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primarySwatch: Colors.blue,
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.white,
      textTheme: TextTheme(
        bodyMedium: TextStyle(fontSize: 16, color: Colors.black),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.deepPurple,
      scaffoldBackgroundColor: Colors.black,
      textTheme: TextTheme(
        bodyMedium: TextStyle(fontSize: 16, color: Colors.white),
      ),
    );
  }
}
