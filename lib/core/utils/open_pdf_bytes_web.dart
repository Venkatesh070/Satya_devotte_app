import 'dart:html' as html;
import 'dart:typed_data';

Future<bool> openPdfBytesWeb(
  Uint8List bytes, {
  String filename = 'shipping-label.pdf',
}) async {
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.window.open(url, '_blank');
  // Revoke after the new tab has a chance to load.
  Future<void>.delayed(const Duration(minutes: 2), () {
    html.Url.revokeObjectUrl(url);
  });
  return true;
}
