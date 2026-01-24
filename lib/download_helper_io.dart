import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

Future<String?> saveBytesToDownloads(Uint8List bytes, String fileName) async {
  String downloadsPath;
  if (Platform.isAndroid) {
    downloadsPath = '/storage/emulated/0/Download';
  } else if (Platform.isWindows) {
    downloadsPath = '${Platform.environment['USERPROFILE']}\\Downloads';
  } else if (Platform.isMacOS) {
    downloadsPath = '${Platform.environment['HOME']}/Downloads';
  } else if (Platform.isIOS) {
    downloadsPath = '${Directory.systemTemp.path}/Downloads';
  } else {
    downloadsPath = Directory.systemTemp.path;
  }

  final downloadsDir = Directory(downloadsPath);
  if (!await downloadsDir.exists()) {
    await downloadsDir.create(recursive: true);
  }

  final file = File('${downloadsDir.path}${Platform.pathSeparator}$fileName');
  await file.writeAsBytes(bytes);
  return file.path;
}

Future<String?> saveUrlToDownloads(String url, String fileName) async {
  final response = await http.get(Uri.parse(url));
  if (response.statusCode != 200) {
    throw HttpException('Failed to download file: ${response.statusCode}');
  }
  return saveBytesToDownloads(response.bodyBytes, fileName);
}
