class HangulUtils {
  static const int _hangulStart = 0xAC00;
  static const int _hangulEnd = 0xD7A3;
  static const int _choBase = 0x1100;
  static const int _jungBase = 0x1161;
  static const int _jongBase = 0x11A7;

  static bool isCompleteHangul(int charCode) {
    return charCode >= _hangulStart && charCode <= _hangulEnd;
  }

  static Map<String, int?> decompose(int charCode) {
    final base = charCode - _hangulStart;
    final cho = base ~/ (21 * 28);
    final jung = (base % (21 * 28)) ~/ 28;
    final jong = base % 28;

    return {
      'cho': _choBase + cho,
      'jung': _jungBase + jung,
      'jong': jong == 0 ? null : _jongBase + jong,
    };
  }

  static int compose(int cho, int jung, int? jong) {
    return _hangulStart +
        (cho - _choBase) * 21 * 28 +
        (jung - _jungBase) * 28 +
        (jong != null ? jong - _jongBase : 0);
  }

  static String? removeLastJamo(String char) {
    if (char.isEmpty) return null;

    final charCode = char.codeUnitAt(0);
    if (!isCompleteHangul(charCode)) return null;

    final decomposed = decompose(charCode);

    // 종성 있으면 종성만 제거
    if (decomposed['jong'] != null) {
      final newChar = compose(decomposed['cho']!, decomposed['jung']!, null);
      return String.fromCharCode(newChar);
    }
    // 종성 없으면 초성만 남김
    else {
      return String.fromCharCode(decomposed['cho']!);
    }
  }
}
