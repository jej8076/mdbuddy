import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class FileService {
  Future<String?> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      if (path.endsWith(".md")) {
        return path;
      }
    }
    return null;
  }

  Future<String> readFile(String filePath) async {
    final file = File(filePath);
    return await file.readAsString();
  }

  Future<bool> saveFile(String filePath, String content) async {
    try {
      final file = File(filePath);
      await file.writeAsString(content);
      return true;
    } catch (e) {
      print("파일 저장 오류: $e");
      return false;
    }
  }

  Future<String?> saveAsFile(String content) async {
    try {
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: '마크다운 파일 저장하기',
        fileName: 'my_markdown.md',
        allowedExtensions: ['md'],
        type: FileType.custom,
      );

      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsString(content);
        return outputFile;
      }
    } catch (e) {
      print("파일 저장 오류: $e");
    }
    return null;
  }
}
