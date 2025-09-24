import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mdbuddy/screens/markdown_editor/components/line_style_text_painter.dart';
import 'package:mdbuddy/utils/markdown_line_style_provider.dart';

// class LineStyle {
//   final Color color;
//   final FontWeight fontWeight;
//   final double fontSize;
//   final String? fontFamily;
//   final FontStyle fontStyle;
//   final TextDecoration decoration;
//
//   LineStyle({
//     required this.color,
//     required this.fontWeight,
//     required this.fontSize,
//     this.fontFamily,
//     this.fontStyle = FontStyle.normal,
//     this.decoration = TextDecoration.none,
//   });
// }

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

class _LineStyledTextFieldState extends State<LineStyledTextField> {
  late FocusNode _focusNode;
  bool _showCursor = false;
  Timer? _cursorTimer;
  int _cursorPosition = 0;
  Size _textFieldSize = Size.zero;
  GlobalKey _canvasKey = GlobalKey();

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
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {});
    if (_focusNode.hasFocus) {
      _startCursorBlink();
    } else {
      _cursorTimer?.cancel();
    }
  }

  void _onTextChange() {
    if (widget.onChanged != null) {
      widget.onChanged!(widget.controller.text);
    }
    setState(() {
      // 텍스트가 변경되면 커서 위치도 업데이트
      _cursorPosition = widget.controller.text.length;
    });
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

  // 커서 위치를 픽셀 좌표로 계산
  Offset _getCursorOffset() {
    final text = widget.controller.text;
    if (text.isEmpty) {
      return Offset(widget.padding.left, widget.padding.top);
    }

    final textBeforeCursor = text.substring(0, _cursorPosition);
    final lines = textBeforeCursor.split('\n');
    final currentLineIndex = lines.length - 1;
    final currentLine = lines[currentLineIndex];

    // 현재 줄의 스타일 가져오기
    final lineStyle =
        widget.lineStyles[currentLineIndex % widget.lineStyles.length];

    // 이전 줄들의 높이 계산
    double yOffset = widget.padding.top;
    for (int i = 0; i < currentLineIndex; i++) {
      final style = widget.lineStyles[i % widget.lineStyles.length];
      final painter = TextPainter(
        text: TextSpan(
          text: lines[i],
          style: TextStyle(
            fontSize: style.fontSize,
            fontWeight: style.fontWeight,
            fontFamily: style.fontFamily,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      painter.layout();
      yOffset += painter.height;
    }

    // 현재 줄에서 커서까지의 너비 계산
    final textPainter = TextPainter(
      text: TextSpan(
        text: currentLine,
        style: TextStyle(
          fontSize: lineStyle.fontSize,
          fontWeight: lineStyle.fontWeight,
          fontFamily: lineStyle.fontFamily,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    return Offset(widget.padding.left + textPainter.width, yOffset);
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.backspace) {
        _handleBackspace();
      } else if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.numpadEnter) {
        _handleEnter();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _moveCursorLeft();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _moveCursorRight();
      } else if (event.character != null) {
        _handleCharacterInput(event.character!);
      }
    }
  }

  void _moveCursorLeft() {
    if (_cursorPosition > 0) {
      setState(() {
        _cursorPosition--;
      });
    }
  }

  void _moveCursorRight() {
    if (_cursorPosition < widget.controller.text.length) {
      setState(() {
        _cursorPosition++;
      });
    }
  }

  void _handleBackspace() {
    final text = widget.controller.text;
    if (text.isNotEmpty && _cursorPosition > 0) {
      final newText = text.substring(0, _cursorPosition - 1) +
          text.substring(_cursorPosition);
      widget.controller.text = newText;
      setState(() {
        _cursorPosition--;
      });
    }
  }

  void _handleEnter() {
    final text = widget.controller.text;
    final newText = text.substring(0, _cursorPosition) +
        '\n' +
        text.substring(_cursorPosition);
    widget.controller.text = newText;
    setState(() {
      _cursorPosition++;
    });
  }

  void _handleCharacterInput(String character) {
    final text = widget.controller.text;
    final newText = text.substring(0, _cursorPosition) +
        character +
        text.substring(_cursorPosition);
    widget.controller.text = newText;
    setState(() {
      _cursorPosition++;
    });
  }

  void _handleTapDown(TapDownDetails details) {
    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
    }

    // 탭 위치에 따른 커서 위치 계산 로직을 여기에 구현
    // (간단한 구현으로 텍스트 끝으로 이동)
    setState(() {
      _cursorPosition = widget.controller.text.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: (FocusNode node, KeyEvent event) {
        _handleKeyEvent(event);
        return KeyEventResult.handled;
      },
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
          ),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.transparent,
          ),
        ),
      ),
    );
  }
}

// class LineStyleTextPainter extends CustomPainter {
//   final String text;
//   final List<LineStyle> lineStyles;
//   final String? hintText;
//   final bool hasFocus;
//   final bool showCursor;
//   final int cursorPosition;
//   final EdgeInsets padding;
//
//   LineStyleTextPainter({
//     required this.text,
//     required this.lineStyles,
//     this.hintText,
//     this.hasFocus = false,
//     this.showCursor = false,
//     this.cursorPosition = 0,
//     this.padding = const EdgeInsets.all(8.0),
//   });
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     if (text.isEmpty && hintText != null) {
//       // 힌트 텍스트 그리기
//       final textSpan = TextSpan(
//         text: hintText,
//         style: TextStyle(
//           color: Colors.grey.withOpacity(0.7),
//           fontSize: lineStyles.isNotEmpty ? lineStyles[0].fontSize : 16,
//         ),
//       );
//
//       final textPainter = TextPainter(
//         text: textSpan,
//         textDirection: TextDirection.ltr,
//       );
//
//       textPainter.layout(maxWidth: size.width - padding.horizontal);
//       textPainter.paint(canvas, Offset(padding.left, padding.top));
//
//       // 텍스트가 비어있고 포커스가 있을 때 커서 그리기
//       if (hasFocus && showCursor) {
//         final paint = Paint()
//           ..color = Colors.black
//           ..strokeWidth = 2.0;
//
//         canvas.drawLine(
//             Offset(padding.left, padding.top),
//             Offset(padding.left, padding.top + (lineStyles.isNotEmpty ? lineStyles[0].fontSize : 16)),
//             paint
//         );
//       }
//
//       return;
//     }
//
//     // 텍스트를 줄별로 분리
//     final lines = text.split('\n');
//
//     // 현재 y 위치
//     double y = padding.top;
//
//     // 커서 위치 계산을 위한 변수들
//     int runningLength = 0;
//     Offset? cursorOffset;
//     double cursorHeight = 0;
//
//     // 각 줄을 적절한 스타일로 그리기
//     for (int i = 0; i < lines.length; i++) {
//       // 이 줄의 스타일 가져오기 (스타일이 줄 수보다 적을 경우 순환)
//       final lineStyle = lineStyles[i % lineStyles.length];
//
//       final textSpan = TextSpan(
//         text: lines[i],
//         style: TextStyle(
//           color: lineStyle.color,
//           fontSize: lineStyle.fontSize,
//           fontWeight: lineStyle.fontWeight,
//           fontFamily: lineStyle.fontFamily,
//           fontStyle: lineStyle.fontStyle,
//           decoration: lineStyle.decoration,
//         ),
//       );
//
//       final textPainter = TextPainter(
//         text: textSpan,
//         textDirection: TextDirection.ltr,
//       );
//
//       textPainter.layout(maxWidth: size.width - padding.horizontal);
//       textPainter.paint(canvas, Offset(padding.left, y));
//
//       // 커서 위치가 이 줄에 있는지 확인
//       final lineEndIndex = runningLength + lines[i].length;
//       if (cursorPosition > runningLength && cursorPosition <= lineEndIndex) {
//         // 이 줄 내에서의 커서 위치
//         final cursorPositionInLine = cursorPosition - runningLength - 1;
//
//         // 커서 위치까지의 텍스트 측정
//         final beforeCursorSpan = TextSpan(
//           text: cursorPositionInLine >= 0 ? lines[i].substring(0, cursorPositionInLine + 1) : "",
//           style: TextStyle(
//             fontSize: lineStyle.fontSize,
//             fontWeight: lineStyle.fontWeight,
//             fontFamily: lineStyle.fontFamily,
//           ),
//         );
//
//         final cursorPainter = TextPainter(
//           text: beforeCursorSpan,
//           textDirection: TextDirection.ltr,
//         );
//
//         cursorPainter.layout();
//
//         cursorOffset = Offset(
//             padding.left + cursorPainter.width,
//             y
//         );
//
//         cursorHeight = lineStyle.fontSize;
//       }
//       // 이 줄이 마지막이고 커서가 텍스트 끝에 있는 경우
//       else if (i == lines.length - 1 && cursorPosition >= lineEndIndex) {
//         cursorOffset = Offset(
//             padding.left + textPainter.width,
//             y
//         );
//
//         cursorHeight = lineStyle.fontSize;
//       }
//
//       // 다음 줄 위치로 이동
//       y += textPainter.height;
//
//       // 이 줄 길이 추가 (줄바꿈 문자 포함)
//       runningLength += lines[i].length + 1; // +1 for newline character
//     }
//
//     // 커서 그리기
//     if (hasFocus && showCursor && cursorOffset != null) {
//       final paint = Paint()
//         ..color = Colors.black
//         ..strokeWidth = 2.0;
//
//       canvas.drawLine(
//           cursorOffset,
//           Offset(cursorOffset.dx, cursorOffset.dy + cursorHeight),
//           paint
//       );
//     }
//   }
//
//   @override
//   bool shouldRepaint(covariant LineStyleTextPainter oldDelegate) {
//     return text != oldDelegate.text ||
//         hintText != oldDelegate.hintText ||
//         hasFocus != oldDelegate.hasFocus ||
//         showCursor != oldDelegate.showCursor ||
//         cursorPosition != oldDelegate.cursorPosition;
//   }
// }
