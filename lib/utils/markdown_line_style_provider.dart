import 'package:flutter/material.dart';

enum MarkdownLineStyles {
  normal,
  h1,
  h2,
  code,
}

class LineStyle {
  final Color color;
  final FontWeight fontWeight;
  final double fontSize;
  final String? fontFamily;
  final FontStyle fontStyle;
  final TextDecoration decoration;

  const LineStyle({ // const 생성자를 추가하여 상수 인스턴스를 만들 수 있도록 함
    required this.color,
    required this.fontWeight,
    required this.fontSize,
    this.fontFamily,
    this.fontStyle = FontStyle.normal,
    this.decoration = TextDecoration.none,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is LineStyle &&
              runtimeType == other.runtimeType &&
              color == other.color &&
              fontWeight == other.fontWeight &&
              fontSize == other.fontSize &&
              fontFamily == other.fontFamily &&
              fontStyle == other.fontStyle &&
              decoration == other.decoration;

  @override
  int get hashCode =>
      color.hashCode ^
      fontWeight.hashCode ^
      fontSize.hashCode ^
      fontFamily.hashCode ^
      fontStyle.hashCode ^
      decoration.hashCode;
}

class LineStyleProvider {
  static const LineStyle normal = LineStyle(color: Colors.black, fontWeight: FontWeight.normal, fontSize: 16);
  static const LineStyle h1 = LineStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 24);
  static const LineStyle h2 = LineStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20);
  static const LineStyle code = LineStyle(color: Colors.grey, fontWeight: FontWeight.w400, fontSize: 15, fontFamily: 'monospace');

  static LineStyle getLineStyle(MarkdownLineStyles lineStyle) {
    switch (lineStyle) {
      case MarkdownLineStyles.normal:
        return normal;
      case MarkdownLineStyles.h1:
        return h1;
      case MarkdownLineStyles.h2:
        return h2;
      case MarkdownLineStyles.code:
        return code;
      default:
        return normal;
    }
  }

  // 필요하다면 인덱스로 스타일을 불러오는 메서드 추가 가능
  static LineStyle? getLineStyleByIndex(int index) {
    switch (index) {
      case 0:
        return normal;
      case 1:
        return h1;
      case 2:
        return h2;
      case 3:
        return code;
      default:
        return null;
    }
  }

  // 모든 LineStyle 데이터를 List 형태로 반환하는 메서드 (선택 사항)
  static List<LineStyle> getAllLineStyles() {
    return [normal, h1, h2, code];
  }
}
