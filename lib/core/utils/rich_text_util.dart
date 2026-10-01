import 'dart:convert';

import 'package:flutter_quill/flutter_quill.dart';

/// Parses and returns the list of Quill Delta operations from a string, if valid.
/// Handles double-encoded JSON, unescaped control characters, auto-repair of broken JSON,
/// and Delta object formats (e.g. `{"ops": [...]}`).
List<dynamic>? parseDeltaOps(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  var s = value.trim();

  // If outer-quoted string like `"[{\"insert\":...}]"`, unwrap outer string layer
  if ((s.startsWith('"') && s.endsWith('"')) ||
      (s.startsWith("'") && s.endsWith("'"))) {
    try {
      final decodedString = jsonDecode(s);
      if (decodedString is String) {
        s = decodedString.trim();
      }
    } catch (_) {
      if (s.length > 2) {
        s = s.substring(1, s.length - 1).trim();
      }
    }
  }

  if (!s.startsWith('[') && !s.startsWith('{')) return null;

  // Sanitize unescaped newlines/tabs inside string literals for jsonDecode
  final sanitized = _sanitizeUnescapedJsonControlChars(s);

  try {
    final decoded = jsonDecode(sanitized);
    if (decoded is List) return decoded;
    if (decoded is Map && decoded['ops'] is List) return decoded['ops'] as List;
  } catch (_) {
    // Try auto-fixing unclosed brackets/quotes
    final repaired = _tryRepairJson(sanitized);
    if (repaired != null) {
      try {
        final decoded = jsonDecode(repaired);
        if (decoded is List) return decoded;
        if (decoded is Map && decoded['ops'] is List) {
          return decoded['ops'] as List;
        }
      } catch (_) {}
    }
  }
  return null;
}

String _sanitizeUnescapedJsonControlChars(String jsonStr) {
  final sb = StringBuffer();
  bool inString = false;
  bool isEscaped = false;

  for (int i = 0; i < jsonStr.length; i++) {
    final char = jsonStr[i];
    final code = jsonStr.codeUnitAt(i);

    if (char == '"' && !isEscaped) {
      inString = !inString;
      sb.write(char);
    } else if (inString) {
      if (char == '\\' && !isEscaped) {
        isEscaped = true;
        sb.write(char);
      } else {
        if (isEscaped) {
          isEscaped = false;
          sb.write(char);
        } else {
          if (code == 10) {
            sb.write(r'\n');
          } else if (code == 13) {
            sb.write(r'\r');
          } else if (code == 9) {
            sb.write(r'\t');
          } else {
            sb.write(char);
          }
        }
      }
    } else {
      isEscaped = false;
      sb.write(char);
    }
  }
  return sb.toString();
}

String? _tryRepairJson(String s) {
  var trimmed = s.trim();
  if (trimmed.isEmpty) return null;
  int quoteCount = 0;
  for (int i = 0; i < trimmed.length; i++) {
    if (trimmed[i] == '"' && (i == 0 || trimmed[i - 1] != '\\')) {
      quoteCount++;
    }
  }
  if (quoteCount % 2 != 0) {
    trimmed += '"';
  }
  int openBrackets = 0;
  int openBraces = 0;
  bool inStr = false;
  for (int i = 0; i < trimmed.length; i++) {
    if (trimmed[i] == '"' && (i == 0 || trimmed[i - 1] != '\\')) {
      inStr = !inStr;
    } else if (!inStr) {
      if (trimmed[i] == '[') {
        openBrackets++;
      } else if (trimmed[i] == ']') {
        openBrackets--;
      } else if (trimmed[i] == '{') {
        openBraces++;
      } else if (trimmed[i] == '}') {
        openBraces--;
      }
    }
  }
  while (openBraces > 0) {
    trimmed += '}';
    openBraces--;
  }
  while (openBrackets > 0) {
    trimmed += ']';
    openBrackets--;
  }
  return trimmed;
}

/// Fallback helper to extract plain text from insert fields when JSON is malformed
String extractPlainTextFromDeltaString(String raw) {
  final regExp = RegExp(r'"insert"\s*:\s*"((?:[^"\\]|\\.)*)"');
  final matches = regExp.allMatches(raw);
  if (matches.isEmpty) return raw;

  final sb = StringBuffer();
  for (final m in matches) {
    final captured = m.group(1);
    if (captured != null && captured.isNotEmpty) {
      final text = captured
          .replaceAll(r'\n', '\n')
          .replaceAll(r'\r', '\r')
          .replaceAll(r'\t', '\t')
          .replaceAll(r'\"', '"')
          .replaceAll(r'\\', '\\');
      sb.write(text);
    }
  }
  return sb.toString();
}

bool isDeltaJson(String? value) {
  if (value == null || value.isEmpty) return false;
  return parseDeltaOps(value) != null || value.trim().contains('"insert"');
}

Document documentFromValue(String? value) {
  if (value == null || value.trim().isEmpty) return Document();
  final ops = parseDeltaOps(value);
  if (ops != null) {
    try {
      return Document.fromJson(ops);
    } catch (_) {}
  }

  final trimmed = value.trim();
  if (trimmed.contains('"insert"')) {
    final extracted = extractPlainTextFromDeltaString(trimmed);
    if (extracted.isNotEmpty) {
      final doc = Document();
      doc.insert(0, extracted);
      return doc;
    }
  }

  final doc = Document();
  if (trimmed.isNotEmpty) {
    doc.insert(0, trimmed);
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

class RichTextBlock {
  const RichTextBlock({required this.content, required this.isDelta});

  final String content;
  final bool isDelta;
}

List<RichTextBlock> extractRichTextBlocks(String? value) {
  if (value == null || value.trim().isEmpty) return const [];
  final trimmed = value.trim();
  if (isDeltaJson(trimmed)) {
    return [RichTextBlock(content: trimmed, isDelta: true)];
  }

  final blocks = <RichTextBlock>[];
  var current = trimmed;

  while (current.isNotEmpty) {
    final startIdx = current.indexOf('[');
    if (startIdx == -1) {
      if (current.trim().isNotEmpty) {
        blocks.add(RichTextBlock(content: current.trim(), isDelta: false));
      }
      break;
    }

    final textBefore = current.substring(0, startIdx).trim();

    int endIdx = current.lastIndexOf(']');
    bool foundJson = false;

    while (endIdx > startIdx) {
      final candidate = current.substring(startIdx, endIdx + 1).trim();
      if (isDeltaJson(candidate)) {
        if (textBefore.isNotEmpty) {
          blocks.add(RichTextBlock(content: textBefore, isDelta: false));
        }
        blocks.add(RichTextBlock(content: candidate, isDelta: true));
        current = current.substring(endIdx + 1).trim();
        foundJson = true;
        break;
      }
      endIdx = current.lastIndexOf(']', endIdx - 1);
    }

    if (!foundJson) {
      final nextBracket = current.indexOf('[', startIdx + 1);
      if (nextBracket != -1) {
        final textPart = current.substring(0, nextBracket).trim();
        if (textPart.isNotEmpty) {
          blocks.add(RichTextBlock(content: textPart, isDelta: false));
        }
        current = current.substring(nextBracket).trim();
      } else {
        if (current.trim().isNotEmpty) {
          blocks.add(RichTextBlock(content: current.trim(), isDelta: false));
        }
        break;
      }
    }
  }

  return blocks;
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
  final ops = parseDeltaOps(value);
  if (ops == null) return false;
  for (final op in ops) {
    if (op is! Map) continue;
    final insert = op['insert'];
    // Ignore attribute-only / empty newline ops for "has recite" checks —
    // Quill can leave a leftover recite attr on a trailing `\n`.
    if (insert is String && insert.trim().isEmpty) continue;
    final attrs = op['attributes'];
    if (attrs is Map && _isReciteAttrValue(attrs['recite'])) return true;
  }
  return false;
}

List<RichTextSegment> parseDeltaSegments(String deltaJson) {
  final ops = parseDeltaOps(deltaJson);
  if (ops == null) return const [];
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
      final prevOps = parseDeltaOps(prev.deltaJson) ?? [];
      final curOps = parseDeltaOps(cur.deltaJson) ?? [];
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
