import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart' show Markdown;

// 마크다운 도움말 다이얼로그를 표시하는 함수
void showMarkdownHelpDialog(BuildContext context) {
  final markdownHelp = '''
# 마크다운 사용법 가이드

## 텍스트 서식

**굵게**: `**텍스트**` 또는 `__텍스트__`

*기울임체*: `*텍스트*` 또는 `_텍스트_`

~~취소선~~: `~~텍스트~~`

## 제목

# 제목 1: `# 제목 1`
## 제목 2: `## 제목 2`
### 제목 3: `### 제목 3`
#### 제목 4: `#### 제목 4`

## 목록

순서 없는 목록:
```
* 항목 1
* 항목 2
  * 중첩 항목
```

순서 있는 목록:
```
1. 첫 번째 항목
2. 두 번째 항목
```

## 링크 및 이미지

링크: `[링크 텍스트](URL)`

이미지: `![대체 텍스트](이미지URL)`

## 인용문

> 인용문: `> 인용문 텍스트`

## 코드

인라인 코드: `` `코드` ``

코드 블록:
````
```언어
코드 내용
```
````

## 표

```
| 제목 1 | 제목 2 |
|--------|--------|
| 셀 1   | 셀 2   |
| 셀 3   | 셀 4   |
```

## 수평선

`---` 또는 `***` 또는 `___`

## 체크박스

- [ ] 미완료 항목: `- [ ] 항목`
- [x] 완료 항목: `- [x] 항목`
''';

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '마크다운 사용법',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Divider(),
              Expanded(
                child: Markdown(
                  data: markdownHelp,
                  selectable: true,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
