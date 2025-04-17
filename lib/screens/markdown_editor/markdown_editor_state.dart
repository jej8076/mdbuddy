import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mdbuddy/bloc/markdown_line_style_bloc.dart';
import 'package:mdbuddy/utils/markdown_line_style_provider.dart';
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
    return BlocProvider<MarkdownLineStyleBloc>(
      create: (context) => MarkdownLineStyleBloc(), // Bloc 인스턴스 생성
      child: Scaffold(
        appBar: EditorAppBar(
          pickFile: _pickFile,
          saveFile: _saveFile,
          saveAsFile: _saveAsFile,
          toggleLayout: _toggleLayout,
          toggleViewerMode: _toggleViewerMode,
          isVertical: _isVertical,
          isViewerMode: _isViewerMode,
        ),
        body: BlocBuilder<MarkdownLineStyleBloc, MarkdownLineStyleState>(
          builder: (context, state) {
            final lineStyles = state.lineStyles;
            return Column(
              children: [
                Expanded(
                  child: LineStyledTextField(
                    controller: _controller,
                    lineStyles: lineStyles,
                    onChanged: (text) {
                      setState(() {});
                    },
                    hintText: '마크다운을 입력하세요...',
                  ),
                ),
                // Divider(height: 2, thickness: 2),
                // Expanded(
                //   child: MarkdownPreview(markdownData: _markdownData),
                // ),
              ],
            );
          },
        ),
      ),
    );
  }
}
