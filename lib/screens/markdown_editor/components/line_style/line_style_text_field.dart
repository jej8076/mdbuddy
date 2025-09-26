import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mdbuddy/bloc/markdown_line_style_bloc.dart';
import 'package:mdbuddy/screens/markdown_editor/components/line_style/line_style_text_painter.dart';
import 'package:mdbuddy/screens/markdown_editor/components/markdown/dto/process_h_response.dart';
import 'package:mdbuddy/screens/markdown_editor/components/markdown/markdown_provider.dart';
import 'package:mdbuddy/utils/HangulUtils.dart';
import 'package:mdbuddy/utils/markdown_line_style_provider.dart';
import 'package:mdbuddy/utils/markdown_utils.dart';

class LineStyleTextField extends StatefulWidget {
  final TextEditingController controller;
  final List<LineStyle> lineStyles;
  final ValueChanged<String>? onChanged;
  final ValueChanged<int>? onNewLine;
  final Function(int lineIndex, LineStyle lineStyle)? onStyleChange;
  final ValueChanged<int>? onRemoveStyle;
  final int? maxLines;
  final String? hintText;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final EdgeInsets padding;

  const LineStyleTextField({
    Key? key,
    required this.controller,
    required this.lineStyles,
    this.onChanged,
    this.onNewLine,
    this.onStyleChange,
    this.onRemoveStyle,
    this.maxLines,
    this.hintText,
    this.textInputAction,
    this.focusNode,
    this.padding = const EdgeInsets.all(8.0),
  }) : super(key: key);

  @override
  _LineStyleTextFieldState createState() => _LineStyleTextFieldState();
}

class _LineStyleTextFieldState extends State<LineStyleTextField>
    implements TextInputClient {
  late FocusNode _focusNode;
  bool _showCursor = true;
  Timer? _cursorTimer;
  int _cursorPosition = 0;
  int? _selectionStart = 0;
  int? _selectionEnd = 0;
  bool _isShiftPressed = false;
  GlobalKey _canvasKey = GlobalKey();
  TextInputConnection? _textInputConnection;

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 앱 시작 시 자동 포커스
      _focusNode.requestFocus();
      // 첫 라인에 기본 라인스타일 추가
      BlocProvider.of<MarkdownLineStyleBloc>(context).add(
        AddLineStyleEvent(style: LineStyle.defaultLineStyle(), index: 0),
      );
    });
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

  // 현재 커서가 몇번째 줄에 있는 지 확인하는 함수
  int getCursorRowIndex([int? newCursor]) {
    int cursor = newCursor ?? _cursorPosition;
    if (cursor < 0 || cursor > widget.controller.text.length) {
      return -1; // 유효하지 않은 커서 위치
    }

    int rowNumber = 0;
    for (int i = 0; i < cursor; i++) {
      if (widget.controller.text[i] == '\n') {
        rowNumber++;
      }
    }
    return rowNumber;
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
    setState(() {
      _showCursor = true;
    });
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
    final oldText = widget.controller.text;
    String newText = value.text;

    ProcessHResponse processHResponse =
        MarkdownProvider.processHnew(context, newText);
    newText = processHResponse.text;

    if (oldText != newText) {
      widget.controller.text = newText;
      final newCursorPosition =
          (value.selection.baseOffset - processHResponse.removedChars)
              .clamp(0, newText.length);

      setState(() {
        _cursorPosition = newCursorPosition;
      });

      // Flutter 입력 시스템에 변경사항 알림
      // 조합 중이 아닐 때만 TextInputConnection 업데이트
      if (!value.composing.isValid) {
        _updateTextInputConnection(newText, _cursorPosition);
      }
    }
  }

  @override
  void performAction(TextInputAction action) {
    // 텍스트 입력 액션 처리 (예: done, next 등)
    if (action == TextInputAction.newline || action == TextInputAction.done) {
      final currentLineIndex = getCursorRowIndex();
      _insertText('\n');
      widget.onNewLine?.call(currentLineIndex + 1);
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

    final targetText = text[_cursorPosition - 1];
    if (targetText == "\n") {
      LineStyle lineStyle = _getCurrentLineStyle();
      // 스타일이 normal이 아니면 스타일만 지우고 끝낸다
      final currentLineIndex = getCursorRowIndex();
      if (lineStyle.getStyleType() != MarkdownLineStyles.normal) {
        widget.onStyleChange?.call(currentLineIndex, LineStyleProvider.normal);
        return;
      }

      widget.onRemoveStyle?.call(currentLineIndex);
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
        _showCursor = true;
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
      newlineIndex = _cursorPosition == 0
          ? -1
          : widget.controller.text.lastIndexOf('\n', _cursorPosition - 1);
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

    // 목표 라인의 텍스트 길이 계산
    int targetLineLength = MarkdownUtils.getLineLengthFromIndex(
        widget.controller.text, newLineStartIndex);

    // 현재 커서가 라인 내에서 몇 번째 위치에 있는지 계산
    int currentPositionInLine = findCursorIndexInLine();

    // 새로운 커서 위치 계산
    int newCursorPosition;

    if (targetLineLength < currentPositionInLine) {
      // 목표 라인이 현재 위치보다 짧으면 라인 끝으로 이동
      newCursorPosition = newLineStartIndex + targetLineLength;
    } else {
      // 목표 라인이 충분히 길면 같은 위치로 이동
      if (currentPositionInLine == 0) {
        if (targetLineLength == 0) {
          // 라인 시작 위치에서는 방향에 따라 조정
          int offset = isMovingUp ? 0 : 1;
          newCursorPosition = newLineStartIndex + offset;
        } else {
          newCursorPosition = newLineStartIndex + currentPositionInLine;
        }
      } else {
        // 일반적인 경우 같은 위치로 이동
        newCursorPosition = newLineStartIndex + currentPositionInLine;
      }
    }

    int resultCursor = newCursorPosition;

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
        _showCursor = true;
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

  LineStyle _getCurrentLineStyle() {
    final currentLineIndex = getCursorRowIndex();
    if (currentLineIndex >= 0 && currentLineIndex < widget.lineStyles.length) {
      return widget.lineStyles[currentLineIndex];
    }
    // 인덱스가 범위를 벗어나면 모듈로 연산으로 순환
    return widget.lineStyles[currentLineIndex % widget.lineStyles.length];
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
              selectionEnd: _selectionEnd,
              // 선택 끝 위치 전달
              cursorRowIndex: getCursorRowIndex(),
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
