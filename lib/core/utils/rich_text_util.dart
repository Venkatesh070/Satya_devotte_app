import 'dart:convert';

import 'package:flutter_quill/flutter_quill.dart';

bool isDeltaJson(String? value) {
  if (value == null || value.isEmpty) return false;
  final trimmed = value.trim();
  if (trimmed.isEmpty) return false;
  final first = trimmed.codeUnitAt(0);
  if (first != 0x5B && first != 0x7B) return false;
  try {
    final decoded = jsonDecode(trimmed);
    return decoded is List;
  } catch (_) {
    return false;
  }
}

Document documentFromValue(String? value) {
  if (isDeltaJson(value)) {
    try {
      return Document.fromJson(jsonDecode(value!.trim()) as List<dynamic>);
    } catch (_) {}
  }
  final doc = Document();
  if (value != null && value.trim().isNotEmpty) {
    doc.insert(0, value.trim());
  }
  return doc;
}

String serializeDocument(Document document) {
  final delta = document.toDelta().toJson();
  if (delta.isEmpty) return '';
  final first = delta.isNotEmpty ? delta.first : null;
  if (delta.length == 1 && first is Map) {
    final insert = (first as Map)['insert'];
    if (insert is String && insert.trim().isEmpty) return '';
  }
  return jsonEncode(delta);
}

String? plainTextOrDelta(String? value) {
  if (value == null || value.isEmpty) return value;
  if (isDeltaJson(value)) return null;
  return value;
}
