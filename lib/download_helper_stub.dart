import 'dart:typed_data';

Future<String?> saveBytesToDownloads(Uint8List bytes, String fileName) async {
  // Not supported on web; return null so caller can handle.
  return null;
}

Future<String?> saveUrlToDownloads(String url, String fileName) async {
  // Not supported on web; return null so caller can handle.
  return null;
}
