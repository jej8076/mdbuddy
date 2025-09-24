import 'package:flutter/material.dart';

enum MarkdownLineStyles {
  normal,
  h1,
  h2,
  h3,
  h4,
  h5,
  code,
}

class LineStyle {
  final Color color;
  final FontWeight fontWeight;
  final double fontSize;
  final String? fontFamily;
  final FontStyle fontStyle;
  final TextDecoration decoration;
  final Widget? prefixWidget; // 추가
  final double leftPadding; // 추가

  const LineStyle({
    required this.color,
    required this.fontWeight,
    required this.fontSize,
    this.fontFamily,
    this.fontStyle = FontStyle.normal,
    this.decoration = TextDecoration.none,
    this.prefixWidget, // 추가
    this.leftPadding = 0.0, // 기본값
  });

  LineStyle copyWith({
    Color? color,
    FontWeight? fontWeight,
    double? fontSize,
    String? fontFamily,
    FontStyle? fontStyle,
    TextDecoration? decoration,
    Widget? prefixWidget,
    double? leftPadding = 0.0,
  }) {
    return LineStyle(
        color: color ?? this.color,
        fontWeight: fontWeight ?? this.fontWeight,
        fontSize: fontSize ?? this.fontSize,
        fontFamily: fontFamily ?? this.fontFamily,
        fontStyle: fontStyle ?? this.fontStyle,
        decoration: decoration ?? this.decoration,
        prefixWidget: prefixWidget ?? this.prefixWidget,
        leftPadding: leftPadding ?? this.leftPadding);
  }

  MarkdownLineStyles getStyleType() {
    if (this == LineStyleProvider.normal) return MarkdownLineStyles.normal;
    if (this == LineStyleProvider.h1) return MarkdownLineStyles.h1;
    if (this == LineStyleProvider.h2) return MarkdownLineStyles.h2;
    if (this == LineStyleProvider.h3) return MarkdownLineStyles.h3;
    if (this == LineStyleProvider.h4) return MarkdownLineStyles.h4;
    if (this == LineStyleProvider.h5) return MarkdownLineStyles.h5;
    if (this == LineStyleProvider.code) return MarkdownLineStyles.code;
    return MarkdownLineStyles.normal; // 기본값
  }

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
  static const LineStyle normal = LineStyle(
      color: Colors.black, fontWeight: FontWeight.normal, fontSize: 16);
  static const LineStyle h1 =
      LineStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 32);
  static const LineStyle h2 =
      LineStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 28);
  static const LineStyle h3 =
      LineStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 24);
  static const LineStyle h4 =
      LineStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20);
  static const LineStyle h5 =
      LineStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16);
  static const LineStyle code = LineStyle(
      color: Colors.grey,
      fontWeight: FontWeight.w400,
      fontSize: 15,
      fontFamily: 'monospace');

  static LineStyle getLineStyle(MarkdownLineStyles lineStyle) {
    switch (lineStyle) {
      case MarkdownLineStyles.normal:
        return normal;
      case MarkdownLineStyles.h1:
        return h1;
      case MarkdownLineStyles.h2:
        return h2;
      case MarkdownLineStyles.h3:
        return h3;
      case MarkdownLineStyles.h4:
        return h4;
      case MarkdownLineStyles.h5:
        return h5;
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

  // LineStyle을 MarkdownLineStyles enum으로 변환
  static MarkdownLineStyles getMarkdownLineStyleType(LineStyle style) {
    if (style == normal) return MarkdownLineStyles.normal;
    if (style == h1) return MarkdownLineStyles.h1;
    if (style == h2) return MarkdownLineStyles.h2;
    if (style == h3) return MarkdownLineStyles.h3;
    if (style == h4) return MarkdownLineStyles.h4;
    if (style == h5) return MarkdownLineStyles.h5;
    if (style == code) return MarkdownLineStyles.code;
    return MarkdownLineStyles.normal; // 기본값
  }

  // 모든 LineStyle 데이터를 List 형태로 반환하는 메서드 (선택 사항)
  static List<LineStyle> getAllLineStyles() {
    return [normal, h1, h2, code];
  }
}
