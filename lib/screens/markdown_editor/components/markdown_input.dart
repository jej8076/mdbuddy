import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class LineStyle {
  final Color color;
  final FontWeight fontWeight;
  final double fontSize;
  final String? fontFamily;
  final FontStyle fontStyle;
  final TextDecoration decoration;

  LineStyle({
    required this.color,
    required this.fontWeight,
    required this.fontSize,
    this.fontFamily,
    this.fontStyle = FontStyle.normal,
    this.decoration = TextDecoration.none,
  });
}

class LineStyledTextField extends StatefulWidget {
  final TextEditingController controller;
  final List<LineStyle> lineStyles;
  final ValueChanged<String>? onChanged;
  final int? maxLines;
  final String? hintText;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final EdgeInsets padding;

  const LineStyledTextField({
    Key? key,
    required this.controller,
    required this.lineStyles,
    this.onChanged,
    this.maxLines,
    this.hintText,
    this.textInputAction,
    this.focusNode,
    this.padding = const EdgeInsets.all(8.0),
  }) : super(key: key);

  @override
  _LineStyledTextFieldState createState() => _LineStyledTextFieldState();
}

class _LineStyledTextFieldState extends State<LineStyledTextField> implements TextInputClient {
  late FocusNode _focusNode;
  bool _showCursor = false;
  Timer? _cursorTimer;
  int _cursorPosition = 0;
  int? _selectionStart = 0;
  int? _selectionEnd = 0;
  bool _isShiftPressed = false;
  GlobalKey _canvasKey = GlobalKey();
  TextInputConnection? _textInputConnection;
  TextEditingValue _currentValue = TextEditingValue.empty;

  @override
  void insertContent(KeyboardInsertedContent content) {}

  @override
  void performSelector(String selectorName) {}

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChange);
    _startCursorBlink();
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _focusNode.removeListener(_onFocusChange);
    widget.controller.removeListener(_onTextChange);
    _cursorTimer?.cancel();
    _closeKeyboard();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _startCursorBlink();
      _openKeyboard();
    } else {
      _cursorTimer?.cancel();
      _closeKeyboard();
      setState(() {
        _showCursor = false;
      });
    }
  }

  void _onTextChange() {
    if (widget.onChanged != null) {
      widget.onChanged!(widget.controller.text);
    }
    setState(() {});
  }

  void _startCursorBlink() {
    _cursorTimer?.cancel();
    _cursorTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      if (mounted) {
        setState(() {
          _showCursor = !_showCursor;
        });
      }
    });
  }

  void _openKeyboard() {
    if (_textInputConnection == null || !_textInputConnection!.attached) {
      _textInputConnection = TextInput.attach(
          this,
          TextInputConfiguration(inputType: TextInputType.multiline)
      );
      _textInputConnection!.show();
    }
  }

  void _closeKeyboard() {
    if (_textInputConnection != null && _textInputConnection!.attached) {
      _textInputConnection!.close();
      _textInputConnection = null;
    }
  }

  // TextInputClient 인터페이스 구현
  @override
  void updateEditingValue(TextEditingValue value) {
    _currentValue = value;
    final oldText = widget.controller.text;
    final newText = value.text;

    if (oldText != newText) {
      widget.controller.text = newText;
      setState(() {
        _cursorPosition = value.selection.baseOffset;
      });
    }
  }

  @override
  void performAction(TextInputAction action) {
    // 텍스트 입력 액션 처리 (예: done, next 등)
    if (action == TextInputAction.newline || action == TextInputAction.done) {
      _insertText('\n');
    }
  }

  @override
  void updateFloatingCursor(RawFloatingCursorPoint point) {}

  @override
  void showAutocorrectionPromptRect(int start, int end) {}

  @override
  void connectionClosed() {}

  @override
  TextEditingValue get currentTextEditingValue => TextEditingValue(
    text: widget.controller.text,
    selection: TextSelection.collapsed(offset: _cursorPosition),
  );

  @override
  AutofillScope? get currentAutofillScope => null;

  @override
  void performPrivateCommand(String action, Map<String, dynamic> data) {}

  @override
  void insertTextPlaceholder(Size size) {}

  @override
  void removeTextPlaceholder() {}

  @override
  void showToolbar() {}

  @override
  void hideToolbar() {}

  @override
  void didChangeInputControl(TextInputControl? oldControl, TextInputControl? newControl) {}

  void _insertText(String text) {
    final currentText = widget.controller.text;
    final beforeCursor = currentText.substring(0, _cursorPosition);
    final afterCursor = currentText.substring(_cursorPosition);

    final newText = beforeCursor + text + afterCursor;
    widget.controller.text = newText;

    setState(() {
      _cursorPosition += text.length;
    });

    if (_textInputConnection != null && _textInputConnection!.attached) {
      _textInputConnection!.setEditingState(
        TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: _cursorPosition),
        ),
      );
    }
  }

  void _handleTapDown(TapDownDetails details) {
    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
    }

    // 터치 위치에 따른 커서 위치 계산
    final tapPosition = details.localPosition;
    final cursorPos = _calculateCursorPositionFromOffset(tapPosition);

    setState(() {
      _cursorPosition = cursorPos;
    });

    // 텍스트 입력 연결에 현재 선택 위치 업데이트
    if (_textInputConnection != null && _textInputConnection!.attached) {
      _textInputConnection!.setEditingState(
        TextEditingValue(
          text: widget.controller.text,
          selection: TextSelection.collapsed(offset: _cursorPosition),
        ),
      );
    }
  }

  int _calculateCursorPositionFromOffset(Offset tapPosition) {
    final text = widget.controller.text;
    if (text.isEmpty) return 0;

    final lines = text.split('\n');
    double y = widget.padding.top;
    int position = 0;

    // 탭된 줄 찾기
    for (int i = 0; i < lines.length; i++) {
      final lineStyle = widget.lineStyles[i % widget.lineStyles.length];

      final textPainter = TextPainter(
        text: TextSpan(
          text: lines[i],
          style: TextStyle(
            fontSize: lineStyle.fontSize,
            fontWeight: lineStyle.fontWeight,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      // 탭 위치가 이 줄의 범위 내에 있는지 확인
      if (tapPosition.dy >= y && tapPosition.dy < y + textPainter.height) {
        // 이 줄 내에서 가장 가까운 문자 위치 찾기
        final offset = tapPosition.dx - widget.padding.left;

        // 문자별 위치 계산 (간단한 구현)
        if (offset <= 0) {
          return position;
        } else if (offset >= textPainter.width) {
          return position + lines[i].length;
        } else {
          // 대략적인 위치 계산 (정확한 구현은 더 복잡합니다)
          final ratio = offset / textPainter.width;
          return position + (lines[i].length * ratio).round();
        }
      }

      // 다음 줄로 이동
      y += textPainter.height;
      position += lines[i].length + 1; // +1 for newline character
    }

    // 디폴트로 텍스트 끝 반환
    return text.length;
  }

  // 현재 커서가 몇번째 줄에 있는 지 확인하는 함수
  int getCurrentRow(String text, int cursorPosition) {
    if (cursorPosition < 0 || cursorPosition > text.length) {
      return -1; // 유효하지 않은 커서 위치
    }

    int rowNumber = 1;
    for (int i = 0; i < cursorPosition; i++) {
      if (text[i] == '\n') {
        rowNumber++;
      }
    }
    return rowNumber;
  }

  void _handleArrowUp() {
    if (_cursorPosition > 0 && widget.controller.text.isNotEmpty) {
      final text = widget.controller.text;

      int nowLine = getCurrentRow(text, _cursorPosition);

      setState(() {
        _cursorPosition--;
      });

    }
  }

  void _handleBackspace() {
    if (_cursorPosition > 0 && widget.controller.text.isNotEmpty) {
      final text = widget.controller.text;
      final newText = text.substring(0, _cursorPosition - 1) + text.substring(_cursorPosition);

      widget.controller.text = newText;
      setState(() {
        _cursorPosition--;
      });

      // 텍스트 입력 연결 업데이트
      if (_textInputConnection != null && _textInputConnection!.attached) {
        _textInputConnection!.setEditingState(
          TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: _cursorPosition),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(skipTraversal: true),
      onKeyEvent: (KeyEvent event) {

        if(event is KeyDownEvent){
          if (event.logicalKey == LogicalKeyboardKey.shiftLeft || event.logicalKey == LogicalKeyboardKey.shiftRight) {
            setState(() {
              _isShiftPressed = true;
              print("isShift:${_isShiftPressed}, _cursorPosition : ${_cursorPosition}, _selectionStart: ${_selectionStart}, _selectionEnd: ${_selectionEnd}");
            });
          }
        }

        if(event is KeyUpEvent){
          if (event.logicalKey == LogicalKeyboardKey.shiftLeft || event.logicalKey == LogicalKeyboardKey.shiftRight) {
            setState(() {
              _isShiftPressed = false;
              _selectionStart = null;
              _selectionEnd = null;
              print("isShift:${_isShiftPressed}, _cursorPosition : ${_cursorPosition}, _selectionStart: ${_selectionStart}, _selectionEnd: ${_selectionEnd}");
            });
          }
        }

        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.backspace) {
            _handleBackspace();
            return;
          }

          if(event.logicalKey == LogicalKeyboardKey.arrowLeft){
            setState(() {
              if(_isShiftPressed && _selectionStart == null){
                _selectionStart = _cursorPosition;
              }
              _cursorPosition--;
              if(_isShiftPressed && _selectionStart != null){
                _selectionEnd = _cursorPosition;
              }else{
                _selectionStart = null;
                _selectionEnd = null;
              }
              print("isShift:${_isShiftPressed}, _cursorPosition : ${_cursorPosition}, _selectionStart: ${_selectionStart}, _selectionEnd: ${_selectionEnd}");
            });
          }

          if(event.logicalKey == LogicalKeyboardKey.arrowRight){
            setState(() {
              if(_isShiftPressed && _selectionStart == null) {
                _selectionStart = _cursorPosition;
              }
              _cursorPosition++;
              if(_isShiftPressed && _selectionStart != null){
                _selectionEnd = _cursorPosition;
              }else{
                _selectionStart = null;
                _selectionEnd = null;
              }
              print("isShift:${_isShiftPressed}, _cursorPosition : ${_cursorPosition}, _selectionStart: ${_selectionStart}, _selectionEnd: ${_selectionEnd}");
            });
          }

        }
      },
      child: Focus(
        focusNode: _focusNode,
        child: GestureDetector(
          onTapDown: _handleTapDown,
          child: CustomPaint(
            key: _canvasKey,
            painter: LineStyleTextPainter(
              text: widget.controller.text,
              lineStyles: widget.lineStyles,
              hintText: widget.hintText,
              hasFocus: _focusNode.hasFocus,
              showCursor: _showCursor && _focusNode.hasFocus,
              cursorPosition: _cursorPosition,
              padding: widget.padding,
              selectionStart: _selectionStart, // 선택 시작 위치 전달
              selectionEnd: _selectionEnd,   // 선택 끝 위치 전달
            ),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.transparent,
            ),
          ),
        ),
      ),
    );
  }
}

class LineStyleTextPainter extends CustomPainter {
  final String text;
  final List<LineStyle> lineStyles;
  final String? hintText;
  final bool hasFocus;
  final bool showCursor;
  final int cursorPosition;
  final EdgeInsets padding;
  final int? selectionStart;
  final int? selectionEnd;

  LineStyleTextPainter({
    required this.text,
    required this.lineStyles,
    this.hintText,
    this.hasFocus = false,
    this.showCursor = false,
    this.cursorPosition = 0,
    this.padding = const EdgeInsets.all(8.0),
    this.selectionStart,
    this.selectionEnd,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (text.isEmpty && hintText != null) {
      // 힌트 텍스트 그리기
      final textSpan = TextSpan(
        text: hintText,
        style: TextStyle(
          color: Colors.grey.withOpacity(0.7),
          fontSize: lineStyles.isNotEmpty ? lineStyles[0].fontSize : 16,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout(maxWidth: size.width - padding.horizontal);
      textPainter.paint(canvas, Offset(padding.left, padding.top));

      // 텍스트가 비어있고 포커스가 있을 때 커서 그리기
      if (hasFocus && showCursor) {
        final paint = Paint()
          ..color = Colors.black
          ..strokeWidth = 2.0;

        canvas.drawLine(
            Offset(padding.left, padding.top),
            Offset(padding.left, padding.top + (lineStyles.isNotEmpty ? lineStyles[0].fontSize : 16)),
            paint
        );
      }

      return;
    }

    // 텍스트를 줄별로 분리
    final lines = text.split('\n');

    // 현재 y 위치
    double y = padding.top;

    // 커서 위치 계산을 위한 변수들
    int runningLength = 0;
    Offset? cursorOffset;
    double cursorHeight = 0;

    // 각 줄을 적절한 스타일로 그리기
    for (int i = 0; i < lines.length; i++) {
      // 이 줄의 스타일 가져오기 (스타일이 줄 수보다 적을 경우 순환)
      final lineStyle = lineStyles[i % lineStyles.length];
      final line = lines[i];
      final lineLength = line.length;
      final lineStartIndex = runningLength;
      final lineEndIndex = runningLength + lineLength;

      TextSpan currentLineSpan = TextSpan(
        text: lines[i],
        style: TextStyle(
          color: lineStyle.color,
          fontSize: lineStyle.fontSize,
          fontWeight: lineStyle.fontWeight,
          fontFamily: lineStyle.fontFamily,
          fontStyle: lineStyle.fontStyle,
          decoration: lineStyle.decoration,
        ),
      );

      if (selectionStart != null && selectionEnd != null) {
        final selectionStartInLineRaw = selectionStart! - lineStartIndex;
        final selectionEndInLineRaw = selectionEnd! - lineStartIndex;

        final selectionStartInLine = max(0, min(lineLength, min(selectionStartInLineRaw, selectionEndInLineRaw)));
        final selectionEndInLine = max(0, min(lineLength, max(selectionStartInLineRaw, selectionEndInLineRaw)));

        if (selectionStartInLine < selectionEndInLine) {
          final beforeSelection = line.substring(0, selectionStartInLine);
          final selectedText = line.substring(selectionStartInLine, selectionEndInLine);
          final afterSelection = line.substring(selectionEndInLine);

          currentLineSpan = TextSpan(
            style: TextStyle(fontSize: lineStyle.fontSize),
            children: <TextSpan>[
              TextSpan(
                text: beforeSelection,
                style: TextStyle(
                  color: lineStyle.color,
                  fontWeight: lineStyle.fontWeight,
                  fontFamily: lineStyle.fontFamily,
                  fontStyle: lineStyle.fontStyle,
                  decoration: lineStyle.decoration,
                ),
              ),
              TextSpan(
                text: selectedText,
                style: TextStyle(
                  color: lineStyle.color,
                  fontWeight: lineStyle.fontWeight,
                  fontFamily: lineStyle.fontFamily,
                  fontStyle: lineStyle.fontStyle,
                  decoration: lineStyle.decoration,
                  background: (Paint()..color = Colors.blue.withOpacity(0.3)),
                ),
              ),
              TextSpan(
                text: afterSelection,
                style: TextStyle(
                  color: lineStyle.color,
                  fontWeight: lineStyle.fontWeight,
                  fontFamily: lineStyle.fontFamily,
                  fontStyle: lineStyle.fontStyle,
                  decoration: lineStyle.decoration,
                ),
              ),
            ],
          );
        }
      }

      final textPainter = TextPainter(
        text: currentLineSpan,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout(maxWidth: size.width - padding.horizontal);
      textPainter.paint(canvas, Offset(padding.left, y));

      // 커서 위치가 이 줄에 있는지 확인
      // final lineLength = lines[i].length;
      // final lineEndIndex = runningLength + lineLength;

      if (cursorPosition >= runningLength && cursorPosition <= lineEndIndex) {
        // 이 줄 내에서의 커서 위치
        final cursorPositionInLine = cursorPosition - runningLength;

        // 커서 위치까지의 텍스트 측정
        final beforeCursorSpan = TextSpan(
          text: cursorPositionInLine > 0 ? lines[i].substring(0, cursorPositionInLine) : "",
          style: TextStyle(
            fontSize: lineStyle.fontSize,
            fontWeight: lineStyle.fontWeight,
            fontFamily: lineStyle.fontFamily,
          ),
        );

        final cursorPainter = TextPainter(
          text: beforeCursorSpan,
          textDirection: TextDirection.ltr,
        );

        cursorPainter.layout();

        cursorOffset = Offset(
            padding.left + cursorPainter.width,
            y
        );

        cursorHeight = lineStyle.fontSize;
      }

      // 다음 줄 위치로 이동
      y += textPainter.height;

      // 이 줄 길이 추가
      runningLength += lineLength + 1; // +1 for newline character
    }

    // 텍스트 끝에 커서가 있는 경우 (마지막 줄 이후)
    if (cursorPosition >= runningLength && lines.isNotEmpty) {
      final lastLineIndex = lines.length - 1;
      final lineStyle = lineStyles[lastLineIndex % lineStyles.length];

      final lastLineSpan = TextSpan(
        text: lines[lastLineIndex],
        style: TextStyle(
          fontSize: lineStyle.fontSize,
          fontWeight: lineStyle.fontWeight,
          fontFamily: lineStyle.fontFamily,
        ),
      );

      final textPainter = TextPainter(
        text: lastLineSpan,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      cursorOffset = Offset(
          padding.left + textPainter.width,
          y - textPainter.height
      );

      cursorHeight = lineStyle.fontSize;
    }

    // 커서 그리기
    if (hasFocus && showCursor && cursorOffset != null) {
      final paint = Paint()
        ..color = Colors.black
        ..strokeWidth = 2.0;

      canvas.drawLine(
          cursorOffset,
          Offset(cursorOffset.dx, cursorOffset.dy + cursorHeight),
          paint
      );
    }
  }

  @override
  bool shouldRepaint(covariant LineStyleTextPainter oldDelegate) {
    return text != oldDelegate.text ||
        hintText != oldDelegate.hintText ||
        hasFocus != oldDelegate.hasFocus ||
        showCursor != oldDelegate.showCursor ||
        cursorPosition != oldDelegate.cursorPosition;
  }
}
