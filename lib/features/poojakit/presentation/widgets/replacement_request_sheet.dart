// Bottom sheet to submit a replacement request for a delivered order.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/core/services/media_upload_service.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/core/utils/toast_util.dart';
import 'package:satya_devotte_app/features/cms/data/models/admin_order_models.dart';
import 'package:satya_devotte_app/features/poojakit/presentation/widgets/order_line_item_picker.dart';
import 'package:satya_devotte_app/features/poojakit/presentation/widgets/pickup_warehouse_return_card.dart';
import 'package:satya_devotte_app/features/poojakit/state/user_orders_controller.dart';

class ReplacementRequestSheet extends StatefulWidget {
  const ReplacementRequestSheet({
    super.key,
    required this.order,
    this.onSubmitted,
  });

  final AdminOrder order;
  final VoidCallback? onSubmitted;

  static Future<void> show(
    BuildContext context, {
    required AdminOrder order,
    VoidCallback? onSubmitted,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: ReplacementRequestSheet(
          order: order,
          onSubmitted: onSubmitted,
        ),
      ),
    );
  }

  @override
  State<ReplacementRequestSheet> createState() =>
      _ReplacementRequestSheetState();
}

class _ReplacementRequestSheetState extends State<ReplacementRequestSheet> {
  final _reasonCtrl = TextEditingController();
  final _images = <PickedFile>[];
  OrderLineSelectionMap _selection = {};
  bool _submitting = false;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    final service = Get.find<MediaUploadService>();
    final picked = await service.pickImages();
    if (picked.isEmpty) return;
    setState(() => _images.addAll(picked));
  }

  Future<void> _takeFromCamera() async {
    final service = Get.find<MediaUploadService>();
    final picked = await service.captureImage();
    if (picked == null) return;
    setState(() => _images.add(picked));
  }

  Future<void> _showImageOptions() async {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Material(
        color: const Color(0xFF1A1A1A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Color(0xFFFCF7EF)),
                  title: const Text(
                    'Choose from Gallery',
                    style: TextStyle(color: Color(0xFFFCF7EF)),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickFromGallery();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Color(0xFFFCF7EF)),
                  title: const Text(
                    'Take Photo',
                    style: TextStyle(color: Color(0xFFFCF7EF)),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _takeFromCamera();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  Future<void> _submit() async {
    final reason = _reasonCtrl.text.trim();
    if (_selection.isEmpty) {
      ToastUtil.showInfo('Please select at least one item to replace.');
      return;
    }
    if (reason.length < 10) {
      ToastUtil.showInfo('Please describe the issue (at least 10 characters).');
      return;
    }
    if (_images.isEmpty) {
      ToastUtil.showInfo('Please attach at least one photo of the damage.');
      return;
    }

    setState(() => _submitting = true);
    final c = Get.find<UserOrdersController>();
    final ok = await c.requestReplacement(
      orderId: widget.order.id,
      reason: reason,
      images: _images,
      affectedItems: orderLineSelectionToPayload(_selection),
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (ok) {
      Navigator.of(context).pop();
      widget.onSubmitted?.call();
      ToastUtil.showSuccess(
        'Your replacement request has been sent. We will review it shortly.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Request a replacement',
              style: AppTypography.lora(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFCF7EF),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Order #${widget.order.orderNumber}',
              style: AppTypography.inter(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 20),
            OrderLineItemPicker(
              order: widget.order,
              selection: _selection,
              title: 'Items to replace',
              forDarkBackground: true,
              subtitle: widget.order.isPickup
                  ? 'Select damaged product(s). After approval, return them to the warehouse.'
                  : widget.order.items.length > 1
                  ? 'Select the damaged product(s) you need replaced.'
                  : null,
              onChanged: (next) => setState(() => _selection = next),
            ),
            if (widget.order.isPickup) ...[
              const SizedBox(height: 12),
              PickupWarehouseReturnCard(order: widget.order),
            ],
            const SizedBox(height: 20),
            Text(
              'What went wrong?',
              style: AppTypography.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFFFCF7EF),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonCtrl,
              maxLines: 4,
              maxLength: 500,
              style: AppTypography.inter(color: Color(0xFFFCF7EF)),
              decoration: InputDecoration(
                hintText:
                    'e.g. Package arrived crushed, items damaged — need replacement',
                hintStyle: AppTypography.inter(color: Colors.white38),
                filled: true,
                fillColor: Color(0xFFFCF7EF).withValues(alpha: 0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Color(0xFFFCF7EF).withValues(alpha: 0.15),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Color(0xFFFCF7EF).withValues(alpha: 0.15),
                  ),
                ),
                counterStyle: AppTypography.inter(
                  color: Colors.white38,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Damage photos',
                  style: AppTypography.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFCF7EF),
                  ),
                ),
                TextButton.icon(
                  onPressed: _submitting ? null : _showImageOptions,
                  icon: const Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 18,
                  ),
                  label: const Text('Add photos'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFFFD180),
                  ),
                ),
              ],
            ),
            if (_images.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFFFCF7EF).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Text(
                  'Attach clear photos of the damaged package or items.',
                  style: AppTypography.inter(
                    fontSize: 13,
                    color: Colors.white54,
                  ),
                ),
              )
            else
              SizedBox(
                height: 88,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _images.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final img = _images[index];
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(
                            Uint8List.fromList(img.bytes),
                            width: 88,
                            height: 88,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: -6,
                          right: -6,
                          child: IconButton(
                            onPressed: _submitting
                                ? null
                                : () => _removeImage(index),
                            icon: const Icon(Icons.cancel, color: Color(0xFFFCF7EF)),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black54,
                              padding: const EdgeInsets.all(4),
                              minimumSize: const Size(24, 24),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD180),
                  foregroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Color(0xFFFCF7EF),
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Submit replacement request',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
