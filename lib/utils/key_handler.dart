import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class KeyHandler {
  TextEditingController? _controller;

  void initKeyboardListener(TextEditingController controller) {
    _controller = controller;
    HardwareKeyboard.instance.addHandler(_handleKeyPress);
  }

  void disposeKeyboardListener() {
    HardwareKeyboard.instance.removeHandler(_handleKeyPress);
  }

  bool _handleKeyPress(KeyEvent event) {
    if (_controller == null) return false;

    if ((event is KeyDownEvent || event is KeyRepeatEvent) &&
        event.logicalKey == LogicalKeyboardKey.tab) {
      final currentText = _controller!.text;
      final selection = _controller!.selection;

      // 텍스트에 탭 문자 삽입
      final newText = currentText.replaceRange(
          selection.start,
          selection.end,
          '\t'
      );

      _controller!.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
            offset: selection.baseOffset + 1
        ),
      );

      return true; // 이벤트 처리됨
    }
    return false; // 이벤트 처리되지 않음
  }
}
