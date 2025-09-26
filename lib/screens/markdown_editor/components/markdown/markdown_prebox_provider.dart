import 'package:flutter/material.dart';
import 'package:mdbuddy/utils/markdown_line_style_provider.dart';

class MarkdownPreboxProvider {
  static const double boxWidth = 16;
  static const double boxHeight = 16;
  static const double boxPaddingRight = 25;
  static const double boxMarginLeft = 5.0;
  static const double boxMarginTop = 5.0;

  static double drawHeaderBox(
      Canvas canvas, LineStyle lineStyle, double currentX, double y) {
    if (!_isHeaderStyle(lineStyle)) {
      return currentX;
    }

    double boxX = currentX + boxMarginLeft;
    double boxY = y + boxMarginTop;

    final boxRect = Rect.fromLTWH(boxX, boxY, boxWidth, boxHeight);
    final roundedRect = RRect.fromRectAndRadius(boxRect, Radius.circular(4.0));

    // 1. 박스 배경 그리기
    final boxPaint = Paint()
      ..color = Colors.grey.shade100
      ..style = PaintingStyle.fill;

    canvas.drawRRect(roundedRect, boxPaint);

    // 2. 박스 테두리 그리기
    final borderPaint = Paint()
      ..color = Colors.grey.shade500
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawRRect(roundedRect, borderPaint);

    // 3. 박스 안에 헤더 텍스트 그리기
    final headerText = _getHeaderText(lineStyle);
    final headerSpan = TextSpan(
      text: headerText,
      style: TextStyle(
        fontSize: 10,
        color: Colors.grey.shade500,
        fontWeight: FontWeight.normal,
      ),
    );

    final headerPainter = TextPainter(
      text: headerSpan,
      textDirection: TextDirection.ltr,
    );

    headerPainter.layout();

    // 박스 중앙에 텍스트 배치
    final textX = boxX + (boxWidth - headerPainter.width) / 2;
    final textY = boxY + (boxHeight - headerPainter.height) / 2;
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
