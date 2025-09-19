import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mdbuddy/screens/markdown_editor/components/markdown/markdown_prebox_provider.dart';
import 'package:mdbuddy/screens/markdown_editor/components/markdown/markdown_provider.dart';
import 'package:mdbuddy/utils/HangulUtils.dart';
import 'package:mdbuddy/utils/markdown_line_style_provider.dart';
import 'package:mdbuddy/utils/markdown_utils.dart';

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

class _LineStyledTextFieldState extends State<LineStyledTextField>
    implements TextInputClient {
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
    if (widget.onChanged == null) {
      return;
    }
    widget.onChanged!(widget.controller.text);

    print("${widget.controller.text}");

    int removedChar = MarkdownProvider.processH(context, widget.controller);
    if (removedChar > 0) {
      int position = _cursorPosition - removedChar;
      setState(() {
        _cursorPosition = position;
      });
      _updateTextInputConnection(widget.controller.text, position);
    }
  }

  void _startCursorBlink() {
    _cursorTimer?.cancel();
    _cursorTimer = Timer.periodic(Duration(milliseconds: 400), (timer) {
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
          this, TextInputConfiguration(inputType: TextInputType.multiline));
      _textInputConnection!.show();
    }
  }

  void _closeKeyboard() {
    if (_textInputConnection != null && _textInputConnection!.attached) {
      _textInputConnection!.close();
      _textInputConnection = null;
    }
  }

  void _updateTextInputConnection(String text, int cursorPosition) {
    if (_textInputConnection != null && _textInputConnection!.attached) {
      _textInputConnection!.setEditingState(
        TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: cursorPosition),
        ),
      );
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
  void didChangeInputControl(
      TextInputControl? oldControl, TextInputControl? newControl) {}

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
  int getCursorRowIndex() {
    if (_cursorPosition < 0 ||
        _cursorPosition > widget.controller.text.length) {
      return -1; // 유효하지 않은 커서 위치
    }

    int rowNumber = 0;
    for (int i = 0; i < _cursorPosition; i++) {
      if (widget.controller.text[i] == '\n') {
        rowNumber++;
      }
    }
    return rowNumber;
  }

  void _handleBackspace() {
    if (widget.controller.text.isEmpty) return;

    if (_selectionStart != null && _selectionEnd != null) {
      _deleteSelectField();
      return;
    }

    // 조합 중일 때는 Flutter 기본 동작 사용
    if (_isComposing()) return;

    final text = widget.controller.text;

    // 한글 자모 단위 삭제 시도
    if (_cursorPosition > 0) {
      final char = text[_cursorPosition - 1];
      final reducedChar = HangulUtils.removeLastJamo(char);

      if (reducedChar != null) {
        final newText = text.substring(0, _cursorPosition - 1) +
            reducedChar +
            text.substring(_cursorPosition);
        _updateText(newText, _cursorPosition);
        return;
      }
    }

    // 일반 문자 삭제
    final newText = text.substring(0, _cursorPosition - 1) +
        text.substring(_cursorPosition);
    _updateText(newText, _cursorPosition - 1);
  }

  bool _isComposing() {
    return _textInputConnection != null &&
        _textInputConnection!.attached &&
        widget.controller.value.composing.isValid;
  }

  void _updateText(String newText, int newCursorPosition) {
    widget.controller.text = newText;
    setState(() {
      _cursorPosition = newCursorPosition;
    });
    _updateTextInputConnection(newText, newCursorPosition);
  }

  void _handleShiftKeyState(LogicalKeyboardKey key, bool isPressed) {
    if (key == LogicalKeyboardKey.shiftLeft ||
        key == LogicalKeyboardKey.shiftRight) {
      setState(() {
        _isShiftPressed = isPressed;
      });
    }
  }

  /// 선택 영역이 있을 경우 해당 영역을 삭제함
  void _deleteSelectField() {
    if (_selectionStart == null || _selectionEnd == null) {
      return;
    }

    final startIndex =
        _selectionStart! < _selectionEnd! ? _selectionStart! : _selectionEnd!;
    final endIndex =
        _selectionStart! > _selectionEnd! ? _selectionStart! : _selectionEnd!;

    final text = widget.controller.text;
    final newText = text.substring(0, startIndex) + text.substring(endIndex);
    final newCursorPosition = startIndex;

    widget.controller.text = newText;
    setState(() {
      _cursorPosition = newCursorPosition;
      _selectionStart = null;
      _selectionEnd = null;
    });

    // 텍스트 입력 연결 업데이트
    if (_textInputConnection != null && _textInputConnection!.attached) {
      _textInputConnection!.setEditingState(
        TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: newCursorPosition),
        ),
      );
    }
  }

  // 방향키 좌우
  void _handleLeftOrRightKey(LogicalKeyboardKey key) {
    final isMovingLeft = key == LogicalKeyboardKey.arrowLeft;
    final moveOffset = isMovingLeft ? -1 : 1;

    // 커서를 더이상 움질일 곳이 없을 때(왼쪽으로)
    if ((_cursorPosition + moveOffset) < 0) {
      return;
    }

    // 커서를 더이상 움질일 곳이 없을 때(오른쪽으로)
    if (widget.controller.text.length < _cursorPosition + moveOffset) {
      return;
    }

    if (_isShiftPressed) {
      setState(() {
        if (_selectionStart == null) {
          _selectionStart = _cursorPosition;
        }
        _cursorPosition += moveOffset;
        _selectionEnd = _cursorPosition;
      });
    } else {
      setState(() {
        _cursorPosition += moveOffset;
        _selectionStart = null;
        _selectionEnd = null;
      });
    }

    // print("_cursorPosition: $_cursorPosition, _selectionStart: $_selectionStart, _selectionEnd: $_selectionEnd");

    if (_textInputConnection != null && _textInputConnection!.attached) {
      _textInputConnection!.setEditingState(
        TextEditingValue(
          text: widget.controller.text,
          selection: TextSelection.collapsed(offset: _cursorPosition),
        ),
      );
    }
  }

  // 방향키 상하
  void _handleUpOrDownKey(LogicalKeyboardKey key) {
    final isMovingUp = LogicalKeyboardKey.arrowUp == key;

    int newlineIndex = -1;
    if (isMovingUp) {
      newlineIndex =
          widget.controller.text.lastIndexOf('\n', _cursorPosition - 1);
    } else {
      newlineIndex = widget.controller.text.indexOf('\n', _cursorPosition);
    }

    if (newlineIndex == -1) {
      setState(() {
        _cursorPosition = isMovingUp ? 0 : widget.controller.text.length;
        _selectionStart = null;
        _selectionEnd = null;
      });
      return;
    }

    int? newLineStartIndex;

    if (isMovingUp) {
      newLineStartIndex =
          widget.controller.text.lastIndexOf('\n', newlineIndex - 1);
    } else {
      newLineStartIndex =
          widget.controller.text.indexOf('\n', newlineIndex - 1);
    }

    if (newLineStartIndex == -1) {
      newLineStartIndex = 0; // 첫 번째 줄인 경우
    } else {
      newLineStartIndex++; // 줄바꿈 문자 다음부터 시작
    }

    // 이동될 라인의 텍스트 길이
    int newLineTextLength = MarkdownUtils.getLineLengthFromIndex(
        widget.controller.text, newLineStartIndex);

    // 이동하기 전 커서의 위치의 라인안에서의 index
    int indexInLine = findCursorIndexInLine();

    int resultCursor = 0;

    if (newLineTextLength < indexInLine) {
      // 이동돼야할 라인의 커서 위치가 현재 커서 위치에서 벗어나면 이동될 문자열의 길이(맨 끝) 위치에 커서가 위치하도록 한다
      resultCursor = newLineStartIndex + newLineTextLength;
    } else {
      resultCursor = newLineStartIndex + indexInLine;
    }

    if (_isShiftPressed) {
      setState(() {
        if (_selectionStart == null) {
          _selectionStart = _cursorPosition;
        }
        _cursorPosition = resultCursor;
        _selectionEnd = _cursorPosition;
      });
    } else {
      setState(() {
        _cursorPosition = resultCursor;
        _selectionStart = null;
        _selectionEnd = null;
      });
    }

    // print("_cursorPosition: $_cursorPosition, _selectionStart: $_selectionStart, _selectionEnd: $_selectionEnd");

    if (_textInputConnection != null && _textInputConnection!.attached) {
      _textInputConnection!.setEditingState(
        TextEditingValue(
          text: widget.controller.text,
          selection: TextSelection.collapsed(offset: _cursorPosition),
        ),
      );
    }
  }

  bool isFunctionKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.shiftLeft ||
        key == LogicalKeyboardKey.shiftRight ||
        key == LogicalKeyboardKey.altLeft ||
        key == LogicalKeyboardKey.altRight ||
        key ==
            LogicalKeyboardKey.metaLeft || // Cmd (macOS), Windows key (Windows)
        key ==
            LogicalKeyboardKey
                .metaRight || // Cmd (macOS), Windows key (Windows)
        key == LogicalKeyboardKey.controlLeft ||
        key == LogicalKeyboardKey.controlRight;
  }

  // 커서 위치가 현재 줄에서 몇번 째 index에 있는 지 확인
  int findCursorIndexInLine() {
    if (_cursorPosition == 0) {
      return 0;
    }
    int previousNewlineIndex =
        widget.controller.text.lastIndexOf('\n', _cursorPosition - 1);
    if (previousNewlineIndex == -1) {
      return _cursorPosition; // 이전 줄바꿈이 없으면 처음부터 커서까지의 인덱스가 현재 줄에서의 인덱스
    } else {
      return _cursorPosition -
          previousNewlineIndex -
          1; // 이전 줄바꿈 이후부터 커서까지의 인덱스
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(skipTraversal: true),
      onKeyEvent: (KeyEvent event) {
        // shift down
        if (event is KeyDownEvent) {
          _handleShiftKeyState(event.logicalKey, true);
        }

        // shift up
        if (event is KeyUpEvent) {
          _handleShiftKeyState(event.logicalKey, false);
        }

        // keydown 이벤트만 인식되도록 함
        if (event is KeyUpEvent) {
          return;
        }

        // backspace
        if (event.logicalKey == LogicalKeyboardKey.backspace) {
          _handleBackspace();
          return;
        }

        // left or right
        if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
            event.logicalKey == LogicalKeyboardKey.arrowRight) {
          _handleLeftOrRightKey(event.logicalKey);
          return;
        }

        // up or down
        if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
            event.logicalKey == LogicalKeyboardKey.arrowDown) {
          _handleUpOrDownKey(event.logicalKey);
          return;
        }

        if (isFunctionKey(event.logicalKey)) {
          return;
        }

        // 이 밑은 일반 텍스트 입력되는 영역
        _deleteSelectField();
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
              selectionStart: _selectionStart,
              // 선택 시작 위치 전달
              selectionEnd: _selectionEnd, // 선택 끝 위치 전달
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
            Offset(
                padding.left,
                padding.top +
                    (lineStyles.isNotEmpty ? lineStyles[0].fontSize : 16)),
            paint);
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
    double originX = padding.left;

    // 각 줄을 적절한 스타일로 그리기
    for (int i = 0; i < lines.length; i++) {
      // 이 줄의 스타일 가져오기 (스타일이 줄 수보다 적을 경우 순환)
      LineStyle lineStyle;
      if ((lineStyles.length - 1) < i) {
        lineStyle = lineStyles[0];
      } else {
        lineStyle = lineStyles[i];
      }

      final line = lines[i];
      final lineLength = line.length;
      final lineStartIndex = runningLength;
      final lineEndIndex = runningLength + lineLength;

      // 헤더 스타일인 경우 박스 위젯 추가
      double lineX =
          MarkdownPreboxProvider.drawHeaderBox(canvas, lineStyle, originX, y);

      TextSpan currentLineSpan = TextSpan(
        text: line,
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

        final selectionStartInLine = max(
            0,
            min(lineLength,
                min(selectionStartInLineRaw, selectionEndInLineRaw)));
        final selectionEndInLine = max(
            0,
            min(lineLength,
                max(selectionStartInLineRaw, selectionEndInLineRaw)));

        if (selectionStartInLine < selectionEndInLine) {
          final beforeSelection = line.substring(0, selectionStartInLine);
          final selectedText =
              line.substring(selectionStartInLine, selectionEndInLine);
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
      textPainter.paint(canvas, Offset(lineX, y));

      if (cursorPosition >= runningLength && cursorPosition <= lineEndIndex) {
        // 이 줄 내에서의 커서 위치
        final cursorPositionInLine = cursorPosition - runningLength;

        // 커서 위치까지의 텍스트 측정
        final beforeCursorSpan = TextSpan(
          text: cursorPositionInLine > 0
              ? lines[i].substring(0, cursorPositionInLine)
              : "",
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

        // lineX = markdown 표시 상자의 존재까지 고려한 위치 값
        cursorOffset = Offset(lineX + cursorPainter.width, y);

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

      cursorOffset =
          Offset(originX + textPainter.width, y - textPainter.height);

      cursorHeight = lineStyle.fontSize;
    }

    // 커서 그리기
    if (hasFocus && showCursor && cursorOffset != null) {
      final paint = Paint()
        ..color = Colors.black
        ..strokeWidth = 2.0;

      canvas.drawLine(cursorOffset,
          Offset(cursorOffset.dx, cursorOffset.dy + cursorHeight), paint);
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

  bool _isHeaderStyle(LineStyle style) {
    return style.fontSize > 16 && style.fontWeight == FontWeight.bold;
  }

  String _getHeaderText(LineStyle style) {
    if (style.fontSize >= 32) return "H1";
    if (style.fontSize >= 28) return "H2";
    if (style.fontSize >= 24) return "H3";
    if (style.fontSize >= 20) return "H4";
    return "H5";
  }
}
