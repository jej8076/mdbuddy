import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mdbuddy/screens/markdown_editor/components/markdown/markdown_prebox_provider.dart';
import 'package:mdbuddy/utils/markdown_line_style_provider.dart';

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
  final int? cursorRowIndex;

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
    this.cursorRowIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 텍스트를 줄별로 분리
    final lines = text.split('\n');

    // 현재 y 위치
    double y = padding.top;

    // 커서 위치 계산을 위한 변수들
    int runningLength = 0;
    Offset? cursorOffset;
    double cursorHeight = 0;
    double originX = padding.left;
    double changedX = originX;

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

      double lineX = originX;

      // 헤더 스타일인 경우 박스 위젯 추가하고 이동된 만큼의 위치를 반환
      if (cursorRowIndex == i) {
        lineX =
            MarkdownPreboxProvider.drawHeaderBox(canvas, lineStyle, originX, y);
      }

      changedX = lineX;

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
          Offset(changedX + textPainter.width, y - textPainter.height);

      cursorHeight = lineStyle.fontSize;
    }

    // 커서 그리기
    if (hasFocus && showCursor && cursorOffset != null) {
      // print("cursorOffset: $cursorOffset");
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
}
