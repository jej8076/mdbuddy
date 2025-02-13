import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        textTheme: TextTheme(
          bodyMedium: TextStyle(fontSize: 16, color: Colors.black),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.black,
        textTheme: TextTheme(
          bodyMedium: TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
      themeMode: ThemeMode.system,
      home: MarkdownEditor(),
    );
  }
}

class MarkdownEditor extends StatefulWidget {
  @override
  _MarkdownEditorState createState() => _MarkdownEditorState();
}

class _MarkdownEditorState extends State<MarkdownEditor> {
  TextEditingController _controller = TextEditingController();
  String _markdownData = "";
  bool _isVertical = true; // true: 위아래 모드, false: 좌우 모드
  bool _isViewerMode = false; // true: Viewer 모드 (텍스트 입력 숨김)

  void _updateMarkdown() {
    setState(() {
      _markdownData = _controller.text;
    });
  }

  void _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      File file = File(result.files.single.path!);
      String content = await file.readAsString();

      if (file.path.endsWith(".md")) {
        setState(() {
          _controller.text = content;
          _markdownData = content;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Please select a markdown (.md) file."),
        ));
      }
    }
  }

  void _toggleLayout() {
    setState(() {
      _isVertical = !_isVertical;
    });
  }

  void _toggleViewerMode() {
    setState(() {
      _isViewerMode = !_isViewerMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'MD BUDDY',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.amber,
        leadingWidth: 200,
        leading: SizedBox(
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.folder_open),
                onPressed: _pickFile,
              ),
              IconButton(
                icon: Icon(_isVertical ? Icons.view_sidebar : Icons.view_column),
                onPressed: _toggleLayout,
              ),
              IconButton(
                icon: Icon(_isViewerMode ? Icons.edit : Icons.visibility),
                onPressed: _toggleViewerMode,
                tooltip: _isViewerMode ? "Edit Mode" : "Viewer Mode",
              ),
            ],
          ),
        ),
      ),
      body: _isViewerMode
          ? Markdown(
        data: _markdownData,
      ) // 🔹 Viewer 모드에서는 Markdown 미리보기만 표시
          : _isVertical
          ? Column(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              maxLines: null,
              decoration: InputDecoration(
                hintText: 'Column Enter markdown text here...',
                border: InputBorder.none,
                filled: true, // ✅ 배경색 활성화
                fillColor: Colors.grey[200], // ✅ 배경색 설정 (연한 회색)
              ),
              onChanged: (text) {
                if (text.endsWith('\n')) {
                  _updateMarkdown();
                }
              },
            ),
          ),
          Divider(height: 2, thickness: 2),
          Expanded(
            child: Markdown(
              data: _markdownData,
            ),
          ),
        ],
      )
          : Row(
        children: [
          Expanded(
            child: Container(
              alignment: Alignment.topCenter,
              child: TextField(
                controller: _controller,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: 'Row Enter markdown text here...',
                  border: InputBorder.none,
                  filled: true,
                  fillColor: Colors.grey[200], // ✅ 배경색 설정 (연한 회색)
                ),
                onChanged: (text) {
                  if (text.endsWith('\n')) {
                    _updateMarkdown();
                  }
                },
              ),
            ),
          ),
          VerticalDivider(width: 2, thickness: 2),
          Expanded(
            child: Markdown(
              data: _markdownData,
            ),
          ),
        ],
      ),
    );
  }
}
