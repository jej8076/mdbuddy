import 'package:flutter/material.dart';
import 'package:mdbuddy/screens/markdown_editor/martdown_editor_screen.dart';
import 'themes/app_theme.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: MarkdownEditor(),
    );
  }
}
