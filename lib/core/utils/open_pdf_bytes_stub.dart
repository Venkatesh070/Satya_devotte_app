import 'dart:typed_data';

Future<bool> openPdfBytesWeb(
  Uint8List bytes, {
  String filename = 'shipping-label.pdf',
}) async {
  throw UnsupportedError('openPdfBytesWeb is only available on web');
}
