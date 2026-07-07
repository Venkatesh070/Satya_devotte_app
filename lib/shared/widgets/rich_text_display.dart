import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import 'package:satya_devotte_app/core/utils/rich_text_util.dart';

class RichTextDisplay extends StatelessWidget {
  const RichTextDisplay(
    this.value, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  final String? value;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final v = value;
    if (v == null || v.trim().isEmpty) return const SizedBox.shrink();
    if (isDeltaJson(v)) {
      return _RichQuillDisplay(
        value: v,
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      );
    }
    return Text(
      v,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

class _RichQuillDisplay extends StatefulWidget {
  const _RichQuillDisplay({
    required this.value,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  final String value;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  State<_RichQuillDisplay> createState() => _RichQuillDisplayState();
}

class _RichQuillDisplayState extends State<_RichQuillDisplay> {
  late final QuillController _controller;

  @override
  void initState() {
    super.initState();
    _controller = QuillController(
      document: documentFromValue(widget.value),
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: true,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = QuillEditorConfig(
      padding: EdgeInsets.zero,
      scrollable: false,
      autoFocus: false,
      expands: false,
      enableInteractiveSelection: false,
      showCursor: false,
    );
    Widget child = QuillEditor.basic(
      controller: _controller,
      config: config,
      scrollController: ScrollController(),
    );

    // If maxLines is provided, constrain the height
    if (widget.maxLines != null) {
      // Approximate max height based on line height
      final lineHeight = widget.style?.height ?? 1.2;
      final fontSize = widget.style?.fontSize ?? 14.0;
      final maxHeight = fontSize * lineHeight * widget.maxLines!;
      child = ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: widget.overflow == TextOverflow.ellipsis
            ? ClipRect(child: child)
            : child,
      );
    }

    return child;
  }
}
