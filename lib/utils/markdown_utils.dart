class MarkdownUtils {
  static List<int>? getTargetStringRowIndex(String text, String? s) {
    if (s == null || text == "") {
      return null;
    }

    List<String> lines = text.split("\n");

    List<int> result = [];
    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];
      if (line.contains(s)) {
        result.add(i);
      }
    }
    return result;
  }
}
