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
  });

  final String label;
  final String? initialValue;
  final ValueChanged<String>? onChanged;

  @override
  State<CmsRichTextField> createState() => _CmsRichTextFieldState();
}

class _CmsRichTextFieldState extends State<CmsRichTextField> {
  late final QuillController _controller;
  late final FocusNode _focusNode;
  bool _focused = false;
  String? _externalInitialValue;
  String? _lastSentValue;

  @override
  void initState() {
    super.initState();
    _externalInitialValue = widget.initialValue;
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

  @override
  void didUpdateWidget(CmsRichTextField oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If the parent didn't change the initialValue prop, do nothing to preserve the undo/redo stack
    if (widget.initialValue == oldWidget.initialValue) return;

    // If initialValue is null, reset to empty
    if (widget.initialValue == null) {
      _externalInitialValue = null;
      _lastSentValue = null;
      final currentSerialized = serializeDocument(_controller.document);
      if (currentSerialized.isNotEmpty) {
        _controller.document = documentFromValue(null);
      }
      return;
    }

    // If widget.initialValue is the last value we sent, skip (prevents loop)
    if (widget.initialValue == _lastSentValue) return;

    // Only update the document if the parent is passing a new initialValue that's not what we already have
    if (widget.initialValue != _externalInitialValue) {
      _externalInitialValue = widget.initialValue;
      final currentSerialized = serializeDocument(_controller.document);
      if (widget.initialValue != currentSerialized) {
        final newDoc = documentFromValue(widget.initialValue);
        _controller.document = newDoc;
      }
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
    _lastSentValue = value;
    widget.onChanged?.call(value);
  }

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
      showUndo: true,
      showRedo: true,
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
              QuillSimpleToolbar(
                controller: _controller,
                config: toolbarConfig,
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
      ],
    );
  }
}
