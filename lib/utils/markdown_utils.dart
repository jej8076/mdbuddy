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

  // startIndex부터 시작해서 다음 \n이 나올 때까지(또는 텍스트 끝까지)의 문자 개수를 반환
  static int getLineLengthFromIndex(String text, int startIndex) {
    int nextNewlineIndex = text.indexOf('\n', startIndex);

    if (nextNewlineIndex == -1) {
      // 다음 \n이 없으면 텍스트 끝까지
      return text.length - startIndex;
    } else {
      // 다음 \n까지의 길이
      return nextNewlineIndex - startIndex;
    }
  }
}
