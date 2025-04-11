import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import 'package:mdbuddy/help/md-help.dart' show showMarkdownHelpDialog;

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
  String? _currentFilePath; // 현재 열려있는 파일 경로를 저장

  // 마크다운 도움말 창 표시 여부
  bool _showMarkdownHelp = false;

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
          _currentFilePath = file.path; // 현재 열린 파일 경로 저장
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Please select a markdown (.md) file."),
        ));
      }
    }
  }

  // 저장 기능 - 기존 파일이 있으면 덮어쓰고, 없으면 다른 이름으로 저장
  void _saveFile() async {
    try {
      // 이미 열려있는 파일이 있으면 덮어쓰기
      if (_currentFilePath != null) {
        File file = File(_currentFilePath!);
        await file.writeAsString(_controller.text);

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("파일이 성공적으로 저장되었습니다."),
          backgroundColor: Colors.green,
        ));
      } else {
        // 열려있는 파일이 없으면 다른 이름으로 저장하기 실행
        _saveAsFile();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("파일 저장 중 오류가 발생했습니다: $e"),
        backgroundColor: Colors.red,
      ));
    }
  }

  // 다른 이름으로 저장하기 기능
  void _saveAsFile() async {
    try {
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: '마크다운 파일 저장하기',
        fileName: 'my_markdown.md',
        allowedExtensions: ['md'],
        type: FileType.custom,
      );

      if (outputFile != null) {
        // 현재 마크다운 내용을 파일에 저장
        File file = File(outputFile);
        await file.writeAsString(_controller.text);

        // 현재 파일 경로 업데이트
        setState(() {
          _currentFilePath = outputFile;
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("파일이 성공적으로 저장되었습니다."),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("파일 저장 중 오류가 발생했습니다: $e"),
        backgroundColor: Colors.red,
      ));
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

  // 탭 키 처리를 위한 함수
  bool _handleKeyPress(KeyEvent event) {
    if ((event is KeyDownEvent || event is KeyRepeatEvent) &&
        event.logicalKey == LogicalKeyboardKey.tab) {
      final currentText = _controller.text;
      final selection = _controller.selection;

      // 텍스트에 탭 문자 삽입
      final newText = currentText.replaceRange(
          selection.start,
          selection.end,
          '\t'
      );

      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
            offset: selection.baseOffset + 1
        ),
      );

      return true; // 이벤트 처리됨
    }
    return false; // 이벤트 처리되지 않음
  }

  @override
  void initState() {
    super.initState();

    // 키 이벤트 리스너 등록 (HardwareKeyboard 사용)
    HardwareKeyboard.instance.addHandler(_handleKeyPress);
  }

  @override
  void dispose() {
    // 키 이벤트 리스너 해제 (HardwareKeyboard 사용)
    HardwareKeyboard.instance.removeHandler(_handleKeyPress);
    // TextEditingController 해제
    _controller.dispose();
    super.dispose();
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
        leadingWidth: 340,  // 버튼을 추가할 수 있도록 너비 증가
        leading: SizedBox(
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.folder_open),
                onPressed: _pickFile,
                tooltip: "파일 열기",
              ),
              IconButton(
                icon: Icon(Icons.save),
                onPressed: _saveFile,
                tooltip: "저장",
              ),
              IconButton(
                icon: Icon(Icons.save_as),
                onPressed: _saveAsFile,
                tooltip: "다른 이름으로 저장",
              ),
              IconButton(
                icon: Icon(_isVertical ? Icons.view_sidebar : Icons.view_column),
                onPressed: _toggleLayout,
                tooltip: "레이아웃 변경",
              ),
              IconButton(
                icon: Icon(_isViewerMode ? Icons.edit : Icons.visibility),
                onPressed: _toggleViewerMode,
                tooltip: _isViewerMode ? "Edit Mode" : "Viewer Mode",
              ),
              IconButton(
                icon: Icon(Icons.help_outline),
                onPressed: () => showMarkdownHelpDialog(context),
                tooltip: "마크다운 사용법",
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
            child: Container(
              color: Colors.grey[200], // TextField 전체 배경을 회색으로 설정
              child: Container(
                color: Colors.grey[200], // TextField 전체 배경을 회색으로 설정
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  decoration: InputDecoration(
                    // hintText: 'Column Enter markdown text here...',
                    border: InputBorder.none,
                    filled: false, // 배경색 비활성화 (Container에서 처리)
                  ),
                  onChanged: (text) {
                    _updateMarkdown(); // 텍스트가 변경될 때마다 바로 업데이트
                  },
                  keyboardType: TextInputType.multiline,
                  autofocus: true,
                ),
              ),
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
              color: Colors.grey[200], // TextField 전체 배경을 회색으로 설정
              alignment: Alignment.topCenter,
              child: Container(
                color: Colors.grey[200], // TextField 전체 배경을 회색으로 설정
                alignment: Alignment.topCenter,
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  decoration: InputDecoration(
                    hintText: 'Row Enter markdown text here...',
                    border: InputBorder.none,
                    filled: false, // 배경색 비활성화 (Container에서 처리)
                  ),
                  onChanged: (text) {
                    _updateMarkdown(); // 텍스트가 변경될 때마다 바로 업데이트
                  },
                  keyboardType: TextInputType.multiline,
                  autofocus: true,
                ),
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
