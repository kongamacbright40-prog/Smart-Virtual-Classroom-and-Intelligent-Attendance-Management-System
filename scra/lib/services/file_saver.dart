import 'file_saver_stub.dart'
    if (dart.library.js_interop) 'file_saver_web.dart'
    if (dart.library.io) 'file_saver_io.dart'
    as impl;

/// Saves a downloaded file for the user: a browser download on the web, the
/// app's downloads folder on Android. Returns the file name or saved path.
Future<String> saveDownloadedFile(
  List<int> bytes, {
  required String fileName,
  String? contentType,
}) => impl.saveFile(bytes, fileName: fileName, contentType: contentType);
