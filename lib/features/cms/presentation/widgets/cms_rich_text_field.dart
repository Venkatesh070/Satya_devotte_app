import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import 'package:satya_devotte_app/core/utils/rich_text_util.dart';
import 'package:satya_devotte_app/features/cms/presentation/pages/cms_shell_page.dart';

class CmsRichTextField extends StatefulWidget {
  const CmsRichTextField({
    super.key,
    required this.label,
    this.initialValue,
    this.onChanged,
    this.showReciteButton = false,
  });

  final String label;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final bool showReciteButton;

  @override
  State<CmsRichTextField> createState() => _CmsRichTextFieldState();
}

class _CmsRichTextFieldState extends State<CmsRichTextField> {
  late final QuillController _controller;
  late final FocusNode _focusNode;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (mounted) {
        setState(() => _focused = _focusNode.hasFocus);
      }
    });
    _controller = QuillController(
      document: documentFromValue(widget.initialValue),
      selection: const TextSelection.collapsed(offset: 0),
    );
    _controller.addListener(_onControllerChange);
  }

  bool _areValuesEqual(String? val1, String? val2) {
    if (val1 == val2) return true;
    final doc1 = documentFromValue(val1);
    final doc2 = documentFromValue(val2);
    return serializeDocument(doc1) == serializeDocument(doc2);
  }

  @override
  void didUpdateWidget(CmsRichTextField oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Only reload when the parent intentionally changes the seed value
    // (e.g. switching which step is being edited). Do NOT sync against the
    // live controller on every parent rebuild — that resets the cursor and
    // makes typing / formatting appear not to stick.
    if (!_areValuesEqual(widget.initialValue, oldWidget.initialValue)) {
      _controller.document = documentFromValue(widget.initialValue);
      _controller.updateSelection(
        const TextSelection.collapsed(offset: 0),
        ChangeSource.local,
      );
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChange);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onControllerChange() {
    final value = serializeDocument(_controller.document);
    widget.onChanged?.call(value);
    if (mounted) setState(() {});
  }

  void _toggleRecite() {
    // Avoid applying recite to the caret position (which can make newly typed
    // text inherit "recite" formatting unexpectedly). Recite should only
    // be applied when the user has an active selection.
    final sel = _controller.selection;
    if (sel.start == sel.end) {
      return;
    }

    final hasRecite =
        _controller.getSelectionStyle().attributes[ReciteAttributes.recite.key]
            ?.value ==
        true;
    _controller.formatSelection(
      hasRecite
          ? Attribute.clone(ReciteAttributes.recite, null)
          : ReciteAttributes.reciteOn,
    );
  }

  bool get _selectionIsRecite =>
      _controller.getSelectionStyle().attributes[ReciteAttributes.recite.key]
          ?.value ==
      true;

  @override
  Widget build(BuildContext context) {
    final toolbarConfig = QuillSimpleToolbarConfig(
      showBoldButton: true,
      showItalicButton: true,
      showUnderLineButton: true,
      showListBullets: true,
      showListNumbers: true,
      showListCheck: false,
      showStrikeThrough: false,
      showInlineCode: false,
      showColorButton: false,
      showBackgroundColorButton: false,
      showClearFormat: true,
      showAlignmentButtons: false,
      showHeaderStyle: false,
      showFontFamily: false,
      showFontSize: false,
      showQuote: false,
      showCodeBlock: false,
      showIndent: false,
      showLink: false,
      showUndo: false,
      showRedo: false,
      showDirection: false,
      showSearchButton: false,
      showSubscript: false,
      showSuperscript: false,
      multiRowsDisplay: true,
      showDividers: false,
    );

    // Get default styles and customize placeholder font size
    final defaultStyles = DefaultStyles.getInstance(context);
    final customStyles = defaultStyles.merge(
      DefaultStyles(
        placeHolder: DefaultTextBlockStyle(
          defaultStyles.placeHolder!.style.copyWith(fontSize: 14),
          defaultStyles.placeHolder!.horizontalSpacing,
          defaultStyles.placeHolder!.verticalSpacing,
          defaultStyles.placeHolder!.lineSpacing,
          defaultStyles.placeHolder!.decoration,
        ),
      ),
    );

    final editorConfig = QuillEditorConfig(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      minHeight: 100,
      autoFocus: false,
      scrollable: true,
      expands: false,
      placeholder: 'Enter ${widget.label}...',
      customStyles: customStyles,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w200,
            color: CmsColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: CmsColors.bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _focused ? CmsColors.orange : CmsColors.border,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: QuillSimpleToolbar(
                      controller: _controller,
                      config: toolbarConfig,
                    ),
                  ),
                  if (widget.showReciteButton) _buildReciteToolbarButton(),
                ],
              ),
              const Divider(height: 1, color: CmsColors.border),
              DefaultTextStyle.merge(
                style: TextStyle(color: CmsColors.textPrimary),
                child: QuillEditor.basic(
                  controller: _controller,
                  focusNode: _focusNode,
                  config: editorConfig,
                ),
              ),
            ],
          ),
        ),
        if (widget.showReciteButton) ...[
          const SizedBox(height: 6),
          Text(
            'Select text, then tap Recite to mark mantra lines.',
            style: TextStyle(
              fontSize: 11,
              color: CmsColors.textSecond.withValues(alpha: 0.9),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildReciteToolbarButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 6, right: 8, left: 4),
      child: Tooltip(
        message: 'Mark selected text as Recite / mantra',
        child: Material(
          color: _selectionIsRecite
              ? CmsColors.orange.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            onTap: _toggleRecite,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              height: kDefaultToolbarSize,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _selectionIsRecite
                      ? CmsColors.orange.withValues(alpha: 0.55)
                      : CmsColors.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.record_voice_over_outlined,
                    size: 16,
                    color: _selectionIsRecite
                        ? CmsColors.orange
                        : CmsColors.textSecond,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Recite',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _selectionIsRecite
                          ? CmsColors.orange
                          : CmsColors.textSecond,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
