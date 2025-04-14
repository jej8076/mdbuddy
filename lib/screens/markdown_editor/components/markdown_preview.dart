import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class MarkdownPreview extends StatelessWidget {
  final String markdownData;

  const MarkdownPreview({
    Key? key,
    required this.markdownData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Markdown(
      data: markdownData,
    );
  }
}
