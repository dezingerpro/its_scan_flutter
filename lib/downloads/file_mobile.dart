import 'package:open_file/open_file.dart';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<void> openFile(String filePath) async {
  final result = await OpenFile.open(filePath);
  if (result.type != ResultType.done) {
    throw Exception('Error opening the file');
  }
}

Future<String> getLocalPath(String filename) async {
  final directory = await getApplicationDocumentsDirectory();
  return "${directory.path}/$filename";
}
