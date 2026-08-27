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

    final blocks = extractRichTextBlocks(v);
    if (blocks.isEmpty) return const SizedBox.shrink();

    if (blocks.length == 1) {
      final block = blocks.first;
      if (block.isDelta) {
        return _RichQuillDisplay(
          key: ValueKey(block.content),
          value: block.content,
          style: style,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
        );
      }
      return Text(
        block.content,
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    final crossAlign = textAlign == TextAlign.center
        ? CrossAxisAlignment.center
        : (textAlign == TextAlign.right
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start);

    return Column(
      crossAxisAlignment: crossAlign,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < blocks.length; i++) ...[
          if (i > 0) const SizedBox(height: 6),
          if (blocks[i].isDelta)
            _RichQuillDisplay(
              key: ValueKey('${blocks[i].content}_$i'),
              value: blocks[i].content,
              style: style,
              textAlign: textAlign,
              maxLines: maxLines,
              overflow: overflow,
            )
          else
            Text(
              blocks[i].content,
              style:
                  style?.copyWith(fontWeight: FontWeight.w600) ??
                  const TextStyle(fontWeight: FontWeight.w600),
              textAlign: textAlign,
              maxLines: maxLines,
              overflow: overflow,
            ),
        ],
      ],
    );
  }
}

class _RichQuillDisplay extends StatefulWidget {
  const _RichQuillDisplay({
    super.key,
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
  late QuillController _controller;

  @override
  void initState() {
    super.initState();
    _controller = _buildController(widget.value);
  }

  QuillController _buildController(String value) {
    return QuillController(
      document: documentFromValue(value),
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: true,
    );
  }

  @override
  void didUpdateWidget(_RichQuillDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      final old = _controller;
      _controller = _buildController(widget.value);
      WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
    }
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
    Widget child = DefaultTextStyle(
      style: TextStyle(color: widget.style?.color ?? const Color(0xFFFCF7EF)),
      child: QuillEditor.basic(
        controller: _controller,
        config: config,
        scrollController: ScrollController(),
      ),
    );

    if (widget.maxLines != null) {
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

    if (widget.textAlign == TextAlign.center) {
      child = Center(child: child);
    }

    return child;
  }
}
