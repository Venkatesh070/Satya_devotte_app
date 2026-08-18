import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';

import 'open_pdf_bytes_stub.dart'
    if (dart.library.html) 'open_pdf_bytes_web.dart' as impl;

/// Opens PDF [bytes] in a new tab (web) or via data URI / external app (mobile).
Future<bool> openPdfBytes(
  List<int> bytes, {
  String filename = 'shipping-label.pdf',
}) {
  final data = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
  if (kIsWeb) {
    return impl.openPdfBytesWeb(data, filename: filename);
  }
  final uri = Uri.dataFromBytes(data, mimeType: 'application/pdf');
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
