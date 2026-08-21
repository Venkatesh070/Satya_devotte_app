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

/// Inline Quill attribute for puja step mantra / recite text.
class ReciteAttributes {
  ReciteAttributes._();

  /// Default editor / caret value for the `recite` attribute is `false`.
  ///
  /// This avoids accidentally marking newly typed text as "recite" unless
  /// the user explicitly toggles it on.
  static const Attribute<bool> recite =
      Attribute<bool>('recite', AttributeScope.inline, false);

  /// Explicit "recite on" attribute.
  static const Attribute<bool> reciteOn =
      Attribute<bool>('recite', AttributeScope.inline, true);
}

class RichTextSegment {
  const RichTextSegment({required this.deltaJson, required this.isRecite});

  final String deltaJson;
  final bool isRecite;

  bool get isEmpty => documentFromValue(deltaJson).toPlainText().trim().isEmpty;
}

bool _isReciteAttrValue(dynamic v) {
  if (v == null) return false;
  if (v is bool) return v;
  final s = v.toString().trim().toLowerCase();
  return s == 'true' || s == '1' || s == 'yes';
}

bool deltaHasRecite(String? value) {
  if (!isDeltaJson(value)) return false;
  try {
    final ops = jsonDecode(value!.trim()) as List<dynamic>;
    for (final op in ops) {
      if (op is! Map) continue;
      final insert = op['insert'];
      // Ignore attribute-only / empty newline ops for "has recite" checks —
      // Quill can leave a leftover recite attr on a trailing `\n`.
      if (insert is String && insert.trim().isEmpty) continue;
      final attrs = op['attributes'];
      if (attrs is Map && _isReciteAttrValue(attrs['recite'])) return true;
    }
  } catch (_) {}
  return false;
}

List<RichTextSegment> parseDeltaSegments(String deltaJson) {
  final ops = jsonDecode(deltaJson.trim()) as List<dynamic>;
  final segments = <RichTextSegment>[];
  var buffer = <Map<String, dynamic>>[];
  bool? currentRecite;

  void flush() {
    if (buffer.isEmpty) return;
    final serialized = jsonEncode(buffer);
    if (documentFromValue(serialized).toPlainText().trim().isEmpty) {
      buffer = [];
      return;
    }
    segments.add(
      RichTextSegment(
        deltaJson: serialized,
        isRecite: currentRecite ?? false,
      ),
    );
    buffer = [];
  }

  bool opIsRecite(Map<String, dynamic> op) {
    final insert = op['insert'];
    // A recite mark on a blank newline alone should not create a Recite card.
    if (insert is String && insert.trim().isEmpty) return false;
    final attrs = op['attributes'];
    return attrs is Map && _isReciteAttrValue(attrs['recite']);
  }

  for (final raw in ops) {
    if (raw is! Map) continue;
    final op = Map<String, dynamic>.from(raw);
    final insert = op['insert'];
    if (insert is! String) {
      flush();
      buffer.add(op);
      currentRecite = false;
      continue;
    }

    final attrs = op['attributes'] as Map<String, dynamic>?;
    final isRecite = opIsRecite(op);
    final parts = insert.split('\n');

    for (var i = 0; i < parts.length; i++) {
      final part = parts[i];
      if (part.isNotEmpty) {
        if (currentRecite != null && isRecite != currentRecite) flush();
        currentRecite = isRecite;
        buffer.add({
          'insert': part,
          if (attrs != null) 'attributes': Map<String, dynamic>.from(attrs),
        });
      }

      if (i < parts.length - 1) {
        if (buffer.isNotEmpty) {
          buffer.add({
            'insert': '\n',
            if (attrs != null) 'attributes': Map<String, dynamic>.from(attrs),
          });
          flush();
          currentRecite = null;
        }
      }
    }
  }
  flush();
  return _mergeAdjacentSegments(segments);
}

List<RichTextSegment> _mergeAdjacentSegments(List<RichTextSegment> segments) {
  if (segments.length <= 1) return segments;
  final merged = <RichTextSegment>[segments.first];
  for (var i = 1; i < segments.length; i++) {
    final prev = merged.last;
    final cur = segments[i];
    if (prev.isRecite == cur.isRecite) {
      final prevOps = jsonDecode(prev.deltaJson) as List<dynamic>;
      final curOps = jsonDecode(cur.deltaJson) as List<dynamic>;
      merged[merged.length - 1] = RichTextSegment(
        deltaJson: jsonEncode([...prevOps, ...curOps]),
        isRecite: prev.isRecite,
      );
    } else {
      merged.add(cur);
    }
  }
  return merged;
}
