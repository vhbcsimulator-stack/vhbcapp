import 'dart:typed_data';
import 'dart:html' as html;

String _saveBytes(Uint8List bytes, String fileName) {
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..download = fileName
    ..style.display = 'none';

  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);

  return 'Downloads/$fileName';
}

Future<String?> saveBytesToDownloads(Uint8List bytes, String fileName) async {
  return _saveBytes(bytes, fileName);
}

Future<String?> saveUrlToDownloads(String url, String fileName) async {
  final response = await html.HttpRequest.request(
    url,
    method: 'GET',
    responseType: 'arraybuffer',
    withCredentials: false,
  );
  if (response.status != 200) {
    throw Exception('Failed to download file: ${response.status}');
  }
  final data = response.response;
  if (data is ByteBuffer) {
    return _saveBytes(data.asUint8List(), fileName);
  }
  if (data is Uint8List) {
    return _saveBytes(data, fileName);
  }
  throw Exception('Unexpected response type for download');
}
