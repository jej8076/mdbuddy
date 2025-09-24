import 'package:flutter/material.dart';
import 'package:mdbuddy/utils/markdown_line_style_provider.dart';

class MarkdownPreboxProvider {
  static const double boxWidth = 16;
  static const double boxHeight = 16;
  static const double boxPaddingRight = 25;

  static double drawHeaderBox(
      Canvas canvas, LineStyle lineStyle, double currentX, double y) {
    if (!_isHeaderStyle(lineStyle)) {
      return currentX;
    }

    // 1. 박스 배경 그리기
    final boxPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final boxRect = Rect.fromLTWH(currentX, y, boxWidth, boxHeight);
    canvas.drawRect(boxRect, boxPaint);

    // 2. 박스 테두리 그리기
    final borderPaint = Paint()
      ..color = Colors.grey
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawRect(boxRect, borderPaint);

    // 3. 박스 안에 헤더 텍스트 그리기
    final headerText = _getHeaderText(lineStyle);
    final headerSpan = TextSpan(
      text: headerText,
      style: TextStyle(
        fontSize: 10,
        color: Colors.black,
        fontWeight: FontWeight.bold,
      ),
    );

    final headerPainter = TextPainter(
      text: headerSpan,
      textDirection: TextDirection.ltr,
    );

    headerPainter.layout();

    // 박스 중앙에 텍스트 배치
    final textX = currentX + (boxWidth - headerPainter.width) / 2;
    final textY = y + (boxHeight - headerPainter.height) / 2;
    headerPainter.paint(canvas, Offset(textX, textY));

    return currentX + boxPaddingRight; // 박스 너비 + 여백
  }

  static bool _isHeaderStyle(LineStyle style) {
    return style.fontSize > 16 && style.fontWeight == FontWeight.bold;
  }

  static String _getHeaderText(LineStyle style) {
    if (style.fontSize >= 32) return "H1";
    if (style.fontSize >= 28) return "H2";
    if (style.fontSize >= 24) return "H3";
    if (style.fontSize >= 20) return "H4";
    return "H5";
  }
}
