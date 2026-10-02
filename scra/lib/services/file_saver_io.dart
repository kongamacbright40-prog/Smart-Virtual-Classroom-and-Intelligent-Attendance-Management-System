import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Writes the file to the app's downloads folder (Android:
/// `Android/data/<package>/files/Download`) and returns its path.
Future<String> saveFile(
  List<int> bytes, {
  required String fileName,
  String? contentType,
}) async {
  final dir =
      await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
  await dir.create(recursive: true);
  final file = File('${dir.path}${Platform.pathSeparator}$fileName');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}
