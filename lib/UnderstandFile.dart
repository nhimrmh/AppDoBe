import 'package:path_provider/path_provider.dart';
import 'dart:io';

class UnderstandFile{
  static Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  static Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/understand.txt');
  }

  static Future<File> writeContent(String content) async {
    final file = await _localFile;
    return file.writeAsString(content);
  }


  static Future<String> readContent() async {
    try {
      final file = await _localFile;
      String contents = await file.readAsString();
      return contents;
    }
    catch (e){
      return '';
    }
  }
}