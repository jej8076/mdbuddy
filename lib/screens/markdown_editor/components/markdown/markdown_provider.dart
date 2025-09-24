import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mdbuddy/bloc/markdown_line_style_bloc.dart';
import 'package:mdbuddy/screens/markdown_editor/components/markdown/dto/process_h_response.dart';
import 'package:mdbuddy/utils/markdown_line_style_provider.dart';

class MarkdownProvider {
  static const Map<String, MarkdownLineStyles> _markdownPatterns = {
    "# ": MarkdownLineStyles.h1,
    "## ": MarkdownLineStyles.h2,
    "### ": MarkdownLineStyles.h3,
    "#### ": MarkdownLineStyles.h4,
    "##### ": MarkdownLineStyles.h5,
  };

  /**
   * TODO processHnew 가 제대로 동작하면 지워질 메서드
   */
  static ProcessHResponse processH(
      BuildContext context, TextEditingController controller) {
    List<String> lines = controller.text.split('\n');
    int removedChars = 0;

    for (var (int idx, String line) in lines.indexed) {
      for (String pattern in _markdownPatterns.keys) {
        if (!line.startsWith(pattern)) {
          continue;
        }

        lines[idx] = line.replaceFirst(pattern, '');
        removedChars += pattern.length;

        BlocProvider.of<MarkdownLineStyleBloc>(context).add(
          AddLineStyleEvent(
              style:
                  LineStyleProvider.getLineStyle(_markdownPatterns[pattern]!),
              index: idx),
        );

        break;
      }
    }

    String newText = controller.text;

    if (removedChars > 0) {
      newText = lines.join('\n');
      // controller.text = newText;
    }

    // return removedChars;
    return ProcessHResponse(text: newText, removedChars: removedChars);
  }

  static ProcessHResponse processHnew(BuildContext context, String text) {
    List<String> lines = text.split('\n');
    int removedChars = 0;

    for (var (int idx, String line) in lines.indexed) {
      for (String pattern in _markdownPatterns.keys) {
        if (!line.startsWith(pattern)) {
          continue;
        }

        lines[idx] = line.replaceFirst(pattern, '');
        removedChars += pattern.length;

        BlocProvider.of<MarkdownLineStyleBloc>(context).add(
          AddLineStyleEvent(
              style:
                  LineStyleProvider.getLineStyle(_markdownPatterns[pattern]!),
              index: idx),
        );

        break;
      }
    }

    String newText = text;

    if (removedChars > 0) {
      newText = lines.join('\n');
    }

    return ProcessHResponse(text: newText, removedChars: removedChars);
  }
}
