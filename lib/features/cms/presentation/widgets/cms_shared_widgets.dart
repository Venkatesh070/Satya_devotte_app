import 'package:flutter/material.dart';
import 'package:satya_devotte_app/features/cms/presentation/pages/cms_shell_page.dart';

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
class CmsFormField extends StatelessWidget {
  const CmsFormField({
    super.key,
    required this.label,
    required this.hint,
    this.initialValue,
    this.maxLines = 1,
    this.controller,
    this.onChanged,
  });
  final String label;
  final String hint;
  final String? initialValue;
  final int maxLines;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
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
        TextFormField(
          initialValue: controller == null ? initialValue : null,
          controller: controller,
          maxLines: maxLines,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 13),
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
        ),
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
          items: widget.items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e, style: const TextStyle(fontSize: 13)),
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
  } // ← missing closing brace was here
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
    final btn = GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: color, size: 16),
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
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 13),
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
    return GestureDetector(
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
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
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
            foregroundColor: Colors.white,
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
