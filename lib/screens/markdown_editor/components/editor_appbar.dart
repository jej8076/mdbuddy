import 'package:flutter/material.dart';
import 'package:mdbuddy/provider/help_dialog_provider.dart';

class EditorAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Function pickFile;
  final Function saveFile;
  final Function saveAsFile;
  final Function toggleLayout;
  final Function toggleViewerMode;
  final bool isVertical;
  final bool isViewerMode;

  const EditorAppBar({
    Key? key,
    required this.pickFile,
    required this.saveFile,
    required this.saveAsFile,
    required this.toggleLayout,
    required this.toggleViewerMode,
    required this.isVertical,
    required this.isViewerMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        'MD BUDDY',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      backgroundColor: Colors.grey,
      leadingWidth: 340,
      leading: SizedBox(
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.folder_open),
              onPressed: () => pickFile(),
              tooltip: "파일 열기",
            ),
            IconButton(
              icon: Icon(Icons.save),
              onPressed: () => saveFile(),
              tooltip: "저장",
            ),
            IconButton(
              icon: Icon(Icons.save_as),
              onPressed: () => saveAsFile(),
              tooltip: "다른 이름으로 저장",
            ),
            IconButton(
              icon: Icon(isVertical ? Icons.view_sidebar : Icons.view_column),
              onPressed: () => toggleLayout(),
              tooltip: "레이아웃 변경",
            ),
            IconButton(
              icon: Icon(isViewerMode ? Icons.edit : Icons.visibility),
              onPressed: () => toggleViewerMode(),
              tooltip: isViewerMode ? "Edit Mode" : "Viewer Mode",
            ),
            IconButton(
              icon: Icon(Icons.help_outline),
              onPressed: () => showMarkdownHelpDialog(context),
              tooltip: "마크다운 사용법",
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
