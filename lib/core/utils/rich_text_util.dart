import 'dart:convert';

import 'package:flutter/painting.dart';
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
  if (value == null) return doc;
  // Preserve internal line breaks from plain text (Enter / \n).
  final normalized = value.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  if (normalized.trim().isEmpty) return doc;
  doc.insert(0, normalized);
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

/// Build a [TextSpan] tree from Quill delta JSON / plain text so Enter/newlines
/// always render in preview and mobile (more reliable than read-only QuillEditor).
TextSpan richTextToTextSpan(
  String? value, {
  TextStyle? style,
}) {
  final base = style ??
      const TextStyle(
        fontSize: 14,
        height: 1.45,
        color: Color(0xFF1A1A1A),
      );

  if (value == null || value.trim().isEmpty) {
    return TextSpan(text: '', style: base);
  }

  if (!isDeltaJson(value)) {
    return TextSpan(
      text: value.replaceAll('\r\n', '\n').replaceAll('\r', '\n'),
      style: base,
    );
  }

  try {
    final ops = jsonDecode(value.trim()) as List<dynamic>;
    final children = <InlineSpan>[];
    var orderedIndex = 1;

    for (final raw in ops) {
      if (raw is! Map) continue;
      final insert = raw['insert'];
      if (insert is! String) continue;

      final attrs = raw['attributes'];
      final attrMap = attrs is Map ? Map<String, dynamic>.from(attrs) : null;
      final parts = insert.split('\n');

      for (var i = 0; i < parts.length; i++) {
        final part = parts[i];
        if (part.isNotEmpty) {
          children.add(
            TextSpan(
              text: part,
              style: _inlineStyleFromAttrs(base, attrMap),
            ),
          );
        }

        if (i < parts.length - 1) {
          // Quill stores block attrs (list/align) on the trailing newline.
          // Prefix the line we just finished, then emit the break.
          final listType = attrMap?['list']?.toString();
          if (listType == 'bullet' ||
              listType == 'checked' ||
              listType == 'unchecked') {
            _prefixLastLineWithMarker(children, '•  ');
            orderedIndex = 1;
          } else if (listType == 'ordered') {
            _prefixLastLineWithMarker(children, '${orderedIndex}.  ');
            orderedIndex += 1;
          } else {
            orderedIndex = 1;
          }
          children.add(const TextSpan(text: '\n'));
        }
      }
    }

    // Drop a single trailing newline so the widget doesn't add extra blank space,
    // but keep intentional blank lines (multiple \n).
    _trimSingleTrailingNewline(children);

    if (children.isEmpty) {
      return TextSpan(text: '', style: base);
    }
    return TextSpan(style: base, children: children);
  } catch (_) {
    return TextSpan(text: value, style: base);
  }
}

TextStyle _inlineStyleFromAttrs(TextStyle base, Map<String, dynamic>? attrs) {
  if (attrs == null || attrs.isEmpty) return base;
  var style = base;
  if (attrs['bold'] == true) {
    style = style.copyWith(fontWeight: FontWeight.w700);
  }
  if (attrs['italic'] == true) {
    style = style.copyWith(fontStyle: FontStyle.italic);
  }
  if (attrs['underline'] == true) {
    style = style.copyWith(decoration: TextDecoration.underline);
  }
  if (attrs['strike'] == true) {
    style = style.copyWith(decoration: TextDecoration.lineThrough);
  }
  return style;
}

void _prefixLastLineWithMarker(List<InlineSpan> children, String marker) {
  // Find start of the last line (after the previous '\n', or start of list).
  var lineStart = 0;
  for (var i = children.length - 1; i >= 0; i--) {
    final span = children[i];
    if (span is TextSpan && span.text == '\n') {
      lineStart = i + 1;
      break;
    }
    if (i == 0) lineStart = 0;
  }
  // Don't double-prefix.
  if (lineStart < children.length) {
    final first = children[lineStart];
    if (first is TextSpan && (first.text?.startsWith('•') == true ||
        RegExp(r'^\d+\.\s').hasMatch(first.text ?? ''))) {
      return;
    }
  }
  children.insert(lineStart, TextSpan(text: marker));
}

void _trimSingleTrailingNewline(List<InlineSpan> children) {
  if (children.isEmpty) return;
  final last = children.last;
  if (last is TextSpan && last.text == '\n') {
    // Keep blank lines: only trim if there aren't two trailing newlines.
    if (children.length >= 2) {
      final prev = children[children.length - 2];
      if (prev is TextSpan && prev.text == '\n') {
        return;
      }
    }
    children.removeLast();
  }
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
        // Always keep the newline so blank lines (Enter Enter) are preserved.
        if (buffer.isNotEmpty) {
          buffer.add({
            'insert': '\n',
            if (attrs != null) 'attributes': Map<String, dynamic>.from(attrs),
          });
          flush();
          currentRecite = null;
        } else {
          // Empty paragraph / blank line between blocks.
          segments.add(
            RichTextSegment(
              deltaJson: jsonEncode([
                {
                  'insert': '\n',
                  if (attrs != null)
                    'attributes': Map<String, dynamic>.from(attrs),
                },
              ]),
              isRecite: false,
            ),
          );
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
