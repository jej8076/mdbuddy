import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mdbuddy/screens/markdown_editor/martdown_editor_screen.dart';
import 'package:mdbuddy/services/file_service.dart';
import 'themes/app_theme.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    String? _currentFilePath; // 현재 열려있는 파일 경로를 저장

    final FileService fileService = FileService();

    // void _pickFile() async {
    //   final filePath = await _fileService.pickFile();
    //   if (filePath != null) {
    //     final content = await _fileService.readFile(filePath);
    //     setState(() {
    //       _controller.text = content;
    //       _markdownData = content;
    //       _currentFilePath = filePath;
    //     });
    //   }
    // }

    // void _saveAsFile() async {
    //   final filePath = await _fileService.saveAsFile(_controller.text);
    //   if (filePath != null) {
    //     setState(() {
    //       _currentFilePath = filePath;
    //     });
    //     _showSuccessSnackBar("파일이 성공적으로 저장되었습니다.");
    //   }
    // }

    // void _showSuccessSnackBar(String message) {
    //   ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    //     content: Text(message),
    //     backgroundColor: Colors.green,
    //   ));
    // }
    //
    // void _showErrorSnackBar(String message) {
    //   ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    //     content: Text(message),
    //     backgroundColor: Colors.red,
    //   ));
    // }

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
              shortcut: const SingleActivator(LogicalKeyboardKey.keyN, meta: true),
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
