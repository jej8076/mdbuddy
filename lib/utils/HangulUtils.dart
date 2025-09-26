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
    // 종성 없으면 호환 자모로 변환된 초성만 남김
    else {
      final compatibleCho = _toCompatibleJamo(decomposed['cho']!);
      return String.fromCharCode(compatibleCho);
    }
  }

  // 초성을 호환 자모로 변환
  static int _toCompatibleJamo(int cho) {
    const choToCompatible = {
      0x1100: 0x3131, // ㄱ
      0x1101: 0x3132, // ㄲ
      0x1102: 0x3134, // ㄴ
      0x1103: 0x3137, // ㄷ
      0x1104: 0x3138, // ㄸ
      0x1105: 0x3139, // ㄹ
      0x1106: 0x3141, // ㅁ
      0x1107: 0x3142, // ㅂ
      0x1108: 0x3143, // ㅃ
      0x1109: 0x3145, // ㅅ
      0x110A: 0x3146, // ㅆ
      0x110B: 0x3147, // ㅇ
      0x110C: 0x3148, // ㅈ
      0x110D: 0x3149, // ㅉ
      0x110E: 0x314A, // ㅊ
      0x110F: 0x314B, // ㅋ
      0x1110: 0x314C, // ㅌ
      0x1111: 0x314D, // ㅍ
      0x1112: 0x314E, // ㅎ
    };
    return choToCompatible[cho] ?? cho;
  }
}
