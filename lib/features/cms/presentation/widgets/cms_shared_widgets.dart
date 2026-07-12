import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/core/presentation/get_snackbar_insets.dart';
import 'package:satya_devotte_app/features/cms/presentation/pages/cms_shell_page.dart';

/// Input text colors only. Backgrounds stay on original [CmsColors].
class CmsThemeColors {
  CmsThemeColors._();

  static const Color inputText = Colors.black;
  static const Color inputHint = Color(0xFFAAAAAA);
}

// ════════════════════════════════════════════════════════════════
// All shared CMS widgets — used across Dashboard, Rituals,
// Festivals, Notifications, Users, etc.
// ════════════════════════════════════════════════════════════════

// ── Form Card container ───────────────────────────────────────────
class CmsFormCard extends StatelessWidget {
  const CmsFormCard({super.key, required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CmsColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: CmsColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

// ── Text input field ──────────────────────────────────────────────
class CmsFormField extends StatefulWidget {
  const CmsFormField({
    super.key,
    required this.label,
    required this.hint,
    this.initialValue,
    this.maxLines = 1,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onFieldSubmitted,
    this.textInputAction,
    this.inputFormatters,
  });
  final String label;
  final String hint;
  final String? initialValue;
  final int maxLines;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<CmsFormField> createState() => _CmsFormFieldState();
}

class _CmsFormFieldState extends State<CmsFormField> {
  ScrollController? _scrollController;

  bool get _isScrollable => widget.maxLines > 1;

  @override
  void initState() {
    super.initState();
    if (_isScrollable) {
      _scrollController = ScrollController();
    }
  }

  @override
  void dispose() {
    _scrollController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMultiline = widget.maxLines > 1;
    final field = TextFormField(
      initialValue: widget.controller == null ? widget.initialValue : null,
      controller: widget.controller,
      focusNode: widget.focusNode,
      maxLines: widget.maxLines,
      scrollController: _scrollController,
      onChanged: widget.onChanged,
      onFieldSubmitted: isMultiline ? null : widget.onFieldSubmitted,
      textInputAction: widget.textInputAction ??
          (isMultiline ? TextInputAction.newline : TextInputAction.done),
      keyboardType:
          isMultiline ? TextInputType.multiline : TextInputType.text,
      inputFormatters: widget.inputFormatters,
      style: const TextStyle(fontSize: 13, color: CmsThemeColors.inputText),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: const TextStyle(
          color: CmsThemeColors.inputHint,
          fontSize: 13,
        ),
        filled: true,
        fillColor: CmsColors.bg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: CmsColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: CmsColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: CmsColors.orange),
        ),
      ),
    );

    final input = _isScrollable && _scrollController != null
        ? Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            trackVisibility: true,
            thickness: 6,
            radius: const Radius.circular(4),
            child: field,
          )
        : field;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: CmsColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        input,
      ],
    );
  }
}

// ── Dropdown field ────────────────────────────────────────────────
class CmsDropdownField extends StatefulWidget {
  const CmsDropdownField({
    super.key,
    required this.label,
    required this.items,
    this.initialValue,
    this.onChanged,
  });
  final String label;
  final List<String> items;
  final String? initialValue;
  final ValueChanged<String?>? onChanged;

  @override
  State<CmsDropdownField> createState() => _CmsDropdownFieldState();
}

class _CmsDropdownFieldState extends State<CmsDropdownField> {
  late String? _value;

  @override
  void initState() {
    super.initState();
    // Guard: only use initialValue if it actually exists in items list
    // Otherwise fall back to first item — prevents DropdownButton assertion error
    _value = _safeValue(widget.initialValue);
  }

  @override
  void didUpdateWidget(CmsDropdownField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If items list changed (e.g. switching between pooja/festival forms)
    // reset value to something valid
    if (!widget.items.contains(_value)) {
      _value = _safeValue(widget.initialValue);
    }
  }

  String _safeValue(String? candidate) {
    if (candidate != null && widget.items.contains(candidate)) {
      return candidate;
    }
    return widget.items.first;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: CmsColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _value,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: CmsColors.textSecond,
            size: 20,
          ),
          dropdownColor: CmsColors.bg,
          style: const TextStyle(fontSize: 13, color: CmsThemeColors.inputText),
          items: widget.items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(
                    e,
                    style: const TextStyle(
                      fontSize: 13,
                      color: CmsThemeColors.inputText,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (v) {
            setState(() => _value = v);
            widget.onChanged?.call(v);
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: CmsColors.bg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: CmsColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: CmsColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: CmsColors.orange),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Status badge ──────────────────────────────────────────────────
class CmsStatusBadge extends StatelessWidget {
  const CmsStatusBadge({super.key, required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final normalised = status.toLowerCase().trim();
    Color c;
    String label;
    switch (normalised) {
      case 'published':
      case 'approved':
        c = const Color(0xFF4CAF50);
        label = 'Published';
        break;
      case 'pending':
      case 'pending_approval':
        c = CmsColors.orange;
        label = 'Pending';
        break;
      case 'queued':
        c = CmsColors.orangeDark;
        label = 'Queued';
        break;
      case 'rejected':
        c = const Color(0xFFE53935);
        label = 'Rejected';
        break;
      case 'draft':
      default:
        c = Colors.grey;
        label = status.isEmpty ? 'Draft' : status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: c, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ── Multi-select dropdown (deities, tags, etc.) ───────────────────
class CmsSelectOption {
  const CmsSelectOption({required this.value, required this.label});
  final String value;
  final String label;
}

class CmsMultiSelectField extends StatelessWidget {
  const CmsMultiSelectField({
    super.key,
    required this.label,
    required this.hintText,
    required this.options,
    required this.selectedValues,
    required this.onChanged,
    this.isLoading = false,
    this.loadingText = 'Loading...',
    this.emptyText = 'No options found',
  });

  final String label;
  final String hintText;
  final List<CmsSelectOption> options;
  final List<String> selectedValues;
  final ValueChanged<List<String>> onChanged;
  final bool isLoading;
  final String loadingText;
  final String emptyText;

  String _summaryText() {
    if (selectedValues.isEmpty) return hintText;
    final labels = <String>[];
    for (final id in selectedValues) {
      for (final o in options) {
        if (o.value == id) {
          labels.add(o.label);
          break;
        }
      }
    }
    if (labels.isEmpty) {
      return '${selectedValues.length} selected';
    }
    if (labels.length <= 2) return labels.join(', ');
    return '${labels.length} selected';
  }

  @override
  Widget build(BuildContext context) {
    final canPick = !isLoading && options.isNotEmpty;
    final sheetOptions = isLoading
        ? <CmsSelectOption>[
            CmsSelectOption(value: '__loading__', label: loadingText),
          ]
        : options.isEmpty
        ? [CmsSelectOption(value: '__empty__', label: emptyText)]
        : options;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: CmsColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final current = List<String>.from(selectedValues);
            final picked = await showDialog<List<String>>(
              context: context,
              barrierDismissible: true,
              builder: (ctx) => _CmsMultiSelectDialog(
                title: label,
                options: sheetOptions,
                initialValues: current,
                canPick: canPick,
                emptyText: emptyText,
              ),
            );
            if (picked != null && canPick) onChanged(picked);
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: CmsColors.bg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: CmsColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    isLoading ? loadingText : _summaryText(),
                    style: TextStyle(
                      fontSize: 13,
                      color: selectedValues.isEmpty || isLoading
                          ? CmsThemeColors.inputHint
                          : CmsThemeColors.inputText,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: CmsColors.textSecond,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CmsMultiSelectDialog extends StatefulWidget {
  const _CmsMultiSelectDialog({
    required this.title,
    required this.options,
    required this.initialValues,
    required this.canPick,
    required this.emptyText,
  });

  final String title;
  final List<CmsSelectOption> options;
  final List<String> initialValues;
  final bool canPick;
  final String emptyText;

  @override
  State<_CmsMultiSelectDialog> createState() => _CmsMultiSelectDialogState();
}

class _CmsMultiSelectDialogState extends State<_CmsMultiSelectDialog> {
  late List<String> _temp;

  @override
  void initState() {
    super.initState();
    _temp = List<String>.from(widget.initialValues);
  }

  @override
  Widget build(BuildContext context) {
    final hasRealOptions = widget.options.any(
      (o) => o.value != '__loading__' && o.value != '__empty__',
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: CmsColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 20),
                    color: CmsColors.textSecond,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: CmsColors.border),
            Flexible(
              child: hasRealOptions
                  ? ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: widget.options.length,
                      itemBuilder: (context, index) {
                        final o = widget.options[index];
                        final isPlaceholder =
                            o.value == '__loading__' || o.value == '__empty__';
                        final checked = _temp.contains(o.value);
                        return CheckboxListTile(
                          dense: true,
                          enabled: !isPlaceholder && widget.canPick,
                          value: isPlaceholder ? false : checked,
                          title: Text(
                            o.label,
                            style: TextStyle(
                              fontSize: 13,
                              color: isPlaceholder
                                  ? CmsThemeColors.inputHint
                                  : CmsThemeColors.inputText,
                            ),
                          ),
                          onChanged: isPlaceholder || !widget.canPick
                              ? null
                              : (v) {
                                  setState(() {
                                    if (v == true) {
                                      if (!_temp.contains(o.value)) {
                                        _temp.add(o.value);
                                      }
                                    } else {
                                      _temp.remove(o.value);
                                    }
                                  });
                                },
                        );
                      },
                    )
                  : Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        widget.emptyText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: CmsThemeColors.inputHint,
                        ),
                      ),
                    ),
            ),
            const Divider(height: 1, color: CmsColors.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: widget.canPick
                        ? () => Navigator.of(context).pop(_temp)
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: CmsColors.orange,
                      foregroundColor: Color(0xFFFCF7EF),
                    ),
                    child: const Text('Apply'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Standardized Snackbar ───────────────────────────────────────────
void showCmsSnackbar({
  required String title,
  required String message,
  bool isError = false,
}) {
  final inset = GetSnackbarInsets.platformDefault();

  Get.snackbar(
    title,
    message,
    snackPosition: SnackPosition.TOP,
    maxWidth: inset.maxWidth,
    backgroundColor: isError
        ? const Color(0xFFF44336)
        : const Color(0xFF4CAF50),
    colorText: Color(0xFFFCF7EF),
    margin: inset.margin,
    borderRadius: 10,
    icon: Icon(
      isError ? Icons.error_outline : Icons.check_circle_outline,
      color: Color(0xFFFCF7EF),
    ),
    duration: const Duration(seconds: 3),
    boxShadows: [
      BoxShadow(
        color: Colors.black.withOpacity(0.2),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );
}

// ── Icon action button ────────────────────────────────────────────
class CmsActionIcon extends StatelessWidget {
  const CmsActionIcon({
    super.key,
    required this.icon,
    required this.color,
    required this.onTap,
    this.tooltip,
  });
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final btn = MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
      ),
    );
    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: btn);
    }
    return btn;
  }
}

// ── Media upload box ──────────────────────────────────────────────
class CmsMediaUploadBox extends StatelessWidget {
  const CmsMediaUploadBox({
    super.key,
    required this.label,
    required this.icon,
    required this.accept,
    this.onTap,
    this.uploadedUrl,
  });
  final String label;
  final IconData icon;
  final String accept;
  final VoidCallback? onTap;
  final String? uploadedUrl;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: uploadedUrl != null ? const Color(0xFFE8F5E9) : CmsColors.bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: uploadedUrl != null
                ? const Color(0xFF4CAF50).withOpacity(0.4)
                : CmsColors.border,
          ),
        ),
        child: uploadedUrl != null
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF4CAF50),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Uploaded successfully',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF4CAF50),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: onTap,
                    child: const Text(
                      'Replace',
                      style: TextStyle(
                        fontSize: 11,
                        color: CmsColors.textSecond,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: CmsColors.orange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: CmsColors.orange, size: 24),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: CmsColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    accept,
                    style: const TextStyle(
                      fontSize: 11,
                      color: CmsColors.textSecond,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ── Search bar ────────────────────────────────────────────────────
class CmsSearchBar extends StatelessWidget {
  const CmsSearchBar({super.key, required this.hint, this.onChanged});
  final String hint;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: CmsColors.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CmsColors.border),
      ),
      child: TextField(
        onChanged: onChanged,
        style: const TextStyle(fontSize: 13, color: CmsThemeColors.inputText),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: CmsThemeColors.inputHint,
            fontSize: 13,
          ),
          prefixIcon: const Icon(
            Icons.search,
            size: 16,
            color: Color(0xFFAAAAAA),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }
}

// ── Primary CTA button ────────────────────────────────────────────
class CmsPrimaryButton extends StatelessWidget {
  const CmsPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.isLoading = false,
  });
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: isLoading ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: isLoading ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isLoading
                ? CmsColors.orange.withOpacity(0.6)
                : CmsColors.orange,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: CmsColors.orange.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Color(0xFFFCF7EF)),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: Color(0xFFFCF7EF), size: 16),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      label,
                      style: const TextStyle(
                        color: Color(0xFFFCF7EF),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────
class CmsEmptyState extends StatelessWidget {
  const CmsEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: CmsColors.orange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: CmsColors.orange, size: 40),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: CmsColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 13, color: CmsColors.textSecond),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 20),
            CmsPrimaryButton(
              label: actionLabel!,
              onTap: onAction!,
              icon: Icons.add,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Pooja Kit / module section header ─────────────────────────────
class CmsPoojaKitSectionHeader extends StatelessWidget {
  const CmsPoojaKitSectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width >= 768;
    final headerCol = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: CmsColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: CmsColors.textSecond),
        ),
      ],
    );
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isWeb ? 24 : 16, vertical: 14),
      color: CmsColors.white,
      child: trailing == null
          ? headerCol
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: headerCol),
                trailing!,
              ],
            ),
    );
  }
}

// ── Confirm delete dialog ─────────────────────────────────────────
Future<bool?> showCmsDeleteDialog(
  BuildContext context, {
  required String itemName,
}) {
  return showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: const Text(
        'Confirm Delete',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: CmsColors.textPrimary,
        ),
      ),
      content: Text(
        'Are you sure you want to delete "$itemName"? This cannot be undone.',
        style: const TextStyle(color: CmsColors.textSecond, fontSize: 13),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text(
            'Cancel',
            style: TextStyle(color: CmsColors.textSecond),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Color(0xFFFCF7EF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}

// ── Pagination bar (shared across CMS list screens) ───────────────
class CmsPaginationBar extends StatelessWidget {
  const CmsPaginationBar({
    super.key,
    required this.page,
    required this.pageSize,
    required this.totalPages,
    required this.totalRows,
    required this.isLoading,
    required this.onPageSelected,
    required this.onPageSizeChanged,
    this.pageSizes = const [10, 20, 50, 100],
  });

  final int page;
  final int pageSize;
  final int totalPages;
  final int totalRows;
  final bool isLoading;
  final ValueChanged<int> onPageSelected;
  final ValueChanged<int> onPageSizeChanged;
  final List<int> pageSizes;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 768;
    final start = totalRows == 0 ? 0 : (page - 1) * pageSize + 1;
    final end = (page * pageSize).clamp(0, totalRows);

    final left = <Widget>[
      Text(
        'Showing $start–$end of $totalRows',
        style: const TextStyle(fontSize: 12, color: CmsColors.textSecond),
      ),
      const SizedBox(width: 18),
      const Text(
        'Rows per page:',
        style: TextStyle(fontSize: 12, color: CmsColors.textSecond),
      ),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: CmsColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: CmsColors.border),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: pageSizes.contains(pageSize) ? pageSize : pageSizes.first,
            isDense: true,
            style: const TextStyle(
              fontSize: 12,
              color: CmsColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            items: pageSizes
                .map((s) => DropdownMenuItem(value: s, child: Text('$s')))
                .toList(),
            onChanged: isLoading
                ? null
                : (v) {
                    if (v != null) onPageSizeChanged(v);
                  },
          ),
        ),
      ),
    ];

    final pager = <Widget>[
      _CmsPagerBtn(
        icon: Icons.chevron_left,
        enabled: page > 1 && !isLoading,
        onTap: () => onPageSelected(page - 1),
      ),
      for (final n in _pageRange(page, totalPages))
        n == -1
            ? const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Text('...', style: TextStyle(color: CmsColors.textSecond)),
              )
            : _CmsPageNumberBtn(
                number: n,
                isActive: n == page,
                onTap: () => onPageSelected(n),
              ),
      _CmsPagerBtn(
        icon: Icons.chevron_right,
        enabled: page < totalPages && !isLoading,
        onTap: () => onPageSelected(page + 1),
      ),
    ];

    final decoration = BoxDecoration(
      color: CmsColors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: CmsColors.border),
    );

    if (isWide) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: decoration,
        child: Row(
          children: [
            ...left,
            const Spacer(),
            ...pager.map(
              (w) => Padding(padding: const EdgeInsets.only(left: 4), child: w),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: decoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(spacing: 8, runSpacing: 8, children: left),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: pager),
        ],
      ),
    );
  }

  static List<int> _pageRange(int current, int total) {
    if (total <= 1) return [1];
    if (total <= 7) return List.generate(total, (i) => i + 1);
    final pages = <int>{1, total, current, current - 1, current + 1};
    final sorted = pages.where((p) => p >= 1 && p <= total).toList()..sort();
    final out = <int>[];
    for (var i = 0; i < sorted.length; i++) {
      if (i > 0 && sorted[i] - sorted[i - 1] > 1) out.add(-1);
      out.add(sorted[i]);
    }
    return out;
  }
}

class _CmsPagerBtn extends StatelessWidget {
  const _CmsPagerBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled ? CmsColors.bg : CmsColors.bg.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: CmsColors.border),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? CmsColors.textPrimary : CmsColors.textSecond,
        ),
      ),
    );
  }
}

class _CmsPageNumberBtn extends StatelessWidget {
  const _CmsPageNumberBtn({
    required this.number,
    required this.isActive,
    required this.onTap,
  });

  final int number;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        margin: const EdgeInsets.only(left: 4),
        decoration: BoxDecoration(
          color: isActive ? CmsColors.orange : CmsColors.bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? CmsColors.orange : CmsColors.border,
          ),
        ),
        child: Text(
          '$number',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isActive ? Color(0xFFFCF7EF) : CmsColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
