import 'package:flutter/material.dart';
import 'package:mdbuddy/screens/markdown_editor/martdown_editor_screen.dart';

import '../../services/file_service.dart';
import '../../utils/key_handler.dart';
import 'components/editor_appbar.dart';
import 'components/markdown_input.dart';
import 'components/markdown_preview.dart';

class MarkdownEditorState extends State<MarkdownEditor> {
  final TextEditingController _controller = TextEditingController();
  String _markdownData = "";
  bool _isVertical = true; // true: 위아래 모드, false: 좌우 모드
  bool _isViewerMode = false; // true: Viewer 모드 (텍스트 입력 숨김)
  String? _currentFilePath; // 현재 열려있는 파일 경로를 저장
  final KeyHandler _keyHandler = KeyHandler();
  final FileService _fileService = FileService();

  final List<LineStyle> _markdownStyles = [
    // 기본 텍스트 스타일
    LineStyle(color: Colors.black, fontWeight: FontWeight.normal, fontSize: 16),
    // 헤더 스타일 (H1)
    LineStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold, fontSize: 24),
    // 헤더 스타일 (H2)
    LineStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold, fontSize: 20),
    // 코드 블록 스타일
    LineStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w400, fontSize: 15, fontFamily: 'Courier'),
  ];

  void _updateMarkdown() {
    setState(() {
      _markdownData = _controller.text;
    });
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

  void _pickFile() async {
    final filePath = await _fileService.pickFile();
    if (filePath != null) {
      final content = await _fileService.readFile(filePath);
      setState(() {
        _controller.text = content;
        _markdownData = content;
        _currentFilePath = filePath;
      });
    }
  }

  void _saveFile() async {
    if (_currentFilePath != null) {
      final success = await _fileService.saveFile(_currentFilePath!, _controller.text);
      if (success) {
        _showSuccessSnackBar("파일이 성공적으로 저장되었습니다.");
      } else {
        _showErrorSnackBar("파일 저장 중 오류가 발생했습니다.");
      }
    } else {
      _saveAsFile();
    }
  }

  void _saveAsFile() async {
    final filePath = await _fileService.saveAsFile(_controller.text);
    if (filePath != null) {
      setState(() {
        _currentFilePath = filePath;
      });
      _showSuccessSnackBar("파일이 성공적으로 저장되었습니다.");
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.green,
    ));
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    ));
  }

  @override
  void initState() {
    super.initState();
    _keyHandler.initKeyboardListener(_controller);
  }

  @override
  void dispose() {
    _keyHandler.disposeKeyboardListener();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: EditorAppBar(
        pickFile: _pickFile,
        saveFile: _saveFile,
        saveAsFile: _saveAsFile,
        toggleLayout: _toggleLayout,
        toggleViewerMode: _toggleViewerMode,
        isVertical: _isVertical,
        isViewerMode: _isViewerMode,
      ),
      body: _isViewerMode
          ? MarkdownPreview(markdownData: _markdownData)
          : _isVertical
          ? Column(
        children: [
          Expanded(
            child: LineStyledTextField(
              controller: _controller,
              lineStyles: _markdownStyles,
              onChanged: (text) {
                // 텍스트 변경 처리
                setState(() {});
              },
              hintText: '마크다운을 입력하세요...',
            ),
          ),
          Divider(height: 2, thickness: 2),
          Expanded(
            child: MarkdownPreview(markdownData: _markdownData),
          ),
        ],
      )
          : Row(
        children: [
          Expanded(
            child: LineStyledTextField(
              controller: _controller,
              lineStyles: _markdownStyles,
              onChanged: (text) {
                // 텍스트 변경 처리
                setState(() {});
              },
              hintText: '마크다운을 입력하세요...',
            ),
          ),
          VerticalDivider(width: 2, thickness: 2),
          Expanded(
            child: MarkdownPreview(markdownData: _markdownData),
          ),
        ],
      ),
    );
  }
}
