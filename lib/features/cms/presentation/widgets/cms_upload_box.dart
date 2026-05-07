// lib/features/cms/presentation/widgets/cms_upload_box.dart
//
// Stateful upload widget. Picks file and holds bytes in memory.
// Bytes are passed to the parent via onPicked and sent with the
// create/update multipart API call — no separate upload needed.
//
// Usage:
//   CmsUploadBox(
//     label:     'Festival Image',
//     icon:      Icons.image_outlined,
//     accept:    'JPG, PNG up to 5MB',
//     mediaType: PickMediaType.image,
//     initialUrl: festival.imageUrl,   // show existing image when editing
//     onPicked:  (file) => setState(() => _pickedImage = file),
//     onRemoved: () => setState(() => _pickedImage = null),
//   )

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/core/services/media_upload_service.dart';
import 'package:satya_devotte_app/features/cms/presentation/pages/cms_shell_page.dart';

class CmsUploadBox extends StatefulWidget {
  const CmsUploadBox({
    super.key,
    required this.label,
    required this.icon,
    required this.accept,
    required this.mediaType,
    this.initialUrl,
    required this.onPicked, // called with PickedFile when user picks
    this.onRemoved, // called when user removes the file
  });

  final String label;
  final IconData icon;
  final String accept;
  final PickMediaType mediaType;
  final String? initialUrl; // existing S3 URL (when editing)
  final ValueChanged<PickedFile> onPicked;
  final VoidCallback? onRemoved;

  @override
  State<CmsUploadBox> createState() => _CmsUploadBoxState();
}

class _CmsUploadBoxState extends State<CmsUploadBox> {
  bool _picking = false;
  PickedFile? _picked; // newly picked file (bytes in memory)
  String? _existingUrl; // pre-existing URL (editing mode)

  static String? _trimUrl(String? url) {
    final t = url?.trim();
    if (t == null || t.isEmpty) return null;
    return t;
  }

  @override
  void initState() {
    super.initState();
    _existingUrl = _trimUrl(widget.initialUrl);
  }

  @override
  void didUpdateWidget(CmsUploadBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialUrl != oldWidget.initialUrl && _picked == null) {
      _existingUrl = _trimUrl(widget.initialUrl);
    }
  }

  Future<void> _pick() async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final service = Get.find<MediaUploadService>();
      final file = await service.pickFile(type: widget.mediaType);
      if (file != null) {
        // Client-side file size check (e.g., 20MB limit)
        const maxBytes = 20 * 1024 * 1024; // 20MB
        if (file.bytes.length > maxBytes) {
          if (mounted) {
            Get.snackbar(
              'File Too Large',
              'The selected ${widget.mediaType.name} is too large (${(file.bytes.length / (1024 * 1024)).toStringAsFixed(1)}MB). Please select a file smaller than 20MB.',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.redAccent,
              colorText: Colors.white,
            );
          }
          // IMPORTANT: Reset picking state and return WITHOUT calling onPicked
          setState(() => _picking = false);
          return;
        }

        setState(() {
          _picked = file;
          _existingUrl = null;
        });
        widget.onPicked(file);
      }
    } catch (e) {
      debugPrint('CmsUploadBox._pick error: $e');
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _remove() {
    if (_picked != null) {
      setState(() {
        _picked = null;
        _existingUrl = _trimUrl(widget.initialUrl);
      });
      widget.onRemoved?.call();
      return;
    }
    setState(() => _existingUrl = null);
    widget.onRemoved?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (_picking) return _PickingBox(label: widget.label);

    // Show newly picked file preview
    if (_picked != null) {
      return _PickedBox(
        icon: widget.icon,
        label: widget.label,
        filename: _picked!.filename,
        bytes: widget.mediaType == PickMediaType.image
            ? Uint8List.fromList(_picked!.bytes)
            : null,
        onReplace: _pick,
        onRemove: _remove,
      );
    }

    // Show existing URL (editing mode)
    if (_existingUrl != null && _existingUrl!.isNotEmpty) {
      return _ExistingBox(
        icon: widget.icon,
        label: widget.label,
        url: _existingUrl!,
        mediaType: widget.mediaType,
        onReplace: _pick,
        onRemove: _remove,
      );
    }

    // Empty — tap to pick
    return _EmptyBox(
      label: widget.label,
      icon: widget.icon,
      accept: widget.accept,
      onTap: _pick,
    );
  }
}

// ── Picking state ─────────────────────────────────────────────────
class _PickingBox extends StatelessWidget {
  const _PickingBox({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 24),
    decoration: BoxDecoration(
      color: CmsColors.bg,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: CmsColors.orange.withOpacity(0.4)),
    ),
    child: Column(
      children: [
        const SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: CmsColors.orange,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Selecting $label...',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: CmsColors.textPrimary,
          ),
        ),
      ],
    ),
  );
}

// ── Newly picked file ─────────────────────────────────────────────
class _PickedBox extends StatelessWidget {
  const _PickedBox({
    required this.icon,
    required this.label,
    required this.filename,
    required this.onReplace,
    required this.onRemove,
    this.bytes,
  });
  final IconData icon;
  final String label, filename;
  final Uint8List? bytes;
  final VoidCallback onReplace, onRemove;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFE8F5E9),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.4)),
    ),
    child: Row(
      children: [
        // Image preview from bytes
        bytes != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  bytes!,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                ),
              )
            : _IconTile(icon: icon, color: const Color(0xFF4CAF50)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 14),
                  SizedBox(width: 5),
                  Text(
                    'Ready to upload',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                filename,
                style: const TextStyle(fontSize: 11, color: Color(0xFF388E3C)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        _Actions(onReplace: onReplace, onRemove: onRemove),
      ],
    ),
  );
}

// ── Existing URL (editing mode) ───────────────────────────────────
class _ExistingBox extends StatelessWidget {
  const _ExistingBox({
    required this.icon,
    required this.label,
    required this.url,
    required this.mediaType,
    required this.onReplace,
    required this.onRemove,
  });
  final IconData icon;
  final String label, url;
  final PickMediaType mediaType;
  final VoidCallback onReplace, onRemove;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: CmsColors.orange.withOpacity(0.05),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: CmsColors.orange.withOpacity(0.3)),
    ),
    child: Row(
      children: [
        mediaType == PickMediaType.image
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  url,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      _IconTile(icon: icon, color: CmsColors.orange),
                ),
              )
            : _IconTile(icon: icon, color: CmsColors.orange),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: CmsColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Existing file — tap Replace to change',
                style: TextStyle(fontSize: 11, color: CmsColors.textSecond),
              ),
            ],
          ),
        ),
        _Actions(onReplace: onReplace, onRemove: onRemove),
      ],
    ),
  );
}

// ── Empty state ───────────────────────────────────────────────────
class _EmptyBox extends StatelessWidget {
  const _EmptyBox({
    required this.label,
    required this.icon,
    required this.accept,
    required this.onTap,
  });
  final String label, accept;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22),
      decoration: BoxDecoration(
        color: CmsColors.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CmsColors.border),
      ),
      child: Column(
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
            style: const TextStyle(fontSize: 11, color: CmsColors.textSecond),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: CmsColors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: CmsColors.orange.withOpacity(0.3)),
            ),
            child: const Text(
              'Tap to select file',
              style: TextStyle(
                fontSize: 11,
                color: CmsColors.orange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// ── Shared widgets ────────────────────────────────────────────────
class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 52,
    height: 52,
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Icon(icon, color: color, size: 26),
  );
}

class _Actions extends StatelessWidget {
  const _Actions({required this.onReplace, required this.onRemove});
  final VoidCallback onReplace, onRemove;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      GestureDetector(
        onTap: onReplace,
        child: const Text(
          'Replace',
          style: TextStyle(
            fontSize: 11,
            color: CmsColors.orange,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      const SizedBox(height: 4),
      GestureDetector(
        onTap: onRemove,
        child: const Text(
          'Remove',
          style: TextStyle(
            fontSize: 11,
            color: Colors.red,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}
