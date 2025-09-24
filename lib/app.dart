import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mdbuddy/screens/markdown_editor/martdown_editor_screen.dart';

import 'themes/app_theme.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PlatformMenuBar(
      menus: [
        PlatformMenu(
          label: 'App',
          menus: [
            // App 메뉴 항목들
          ],
        ),
        PlatformMenu(
          label: 'File',
          menus: [
            PlatformMenuItem(
              label: 'New',
              shortcut:
                  const SingleActivator(LogicalKeyboardKey.keyN, meta: true),
              onSelected: () {
                print('New menu item selected');
              },
            ),
            // 기타 File 메뉴 항목들
          ],
        ),
        PlatformMenu(
          label: 'Edit',
          menus: [
            // Edit 메뉴 항목들
          ],
        ),
        PlatformMenu(
          label: 'View',
          menus: [
            // View 메뉴 항목들
          ],
        ),
        // 기타 필요한 메뉴들
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: MarkdownEditor(),
      ),
    );
  }
}
