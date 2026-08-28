import 'package:flutter/material.dart';

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
      return _buildBlock(
        blocks.first,
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < blocks.length; i++) ...[
          if (i > 0) const SizedBox(height: 6),
          _buildBlock(
            blocks[i],
            style: blocks[i].isDelta
                ? style
                : (style?.copyWith(fontWeight: FontWeight.w600) ??
                    const TextStyle(fontWeight: FontWeight.w600)),
            textAlign: textAlign,
            maxLines: maxLines,
            overflow: overflow,
          ),
        ],
      ],
    );
  }

  Widget _buildBlock(
    RichTextBlock block, {
    TextStyle? style,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
  }) {
    // Always render via Text.rich so Enter / `\n` paragraph breaks are visible
    // in CMS preview and mobile (QuillEditor read-only often collapses them).
    final span = richTextToTextSpan(block.content, style: style);
    return Text.rich(
      span,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
      softWrap: true,
    );
  }
}
