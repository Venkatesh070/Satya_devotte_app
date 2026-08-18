import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/core/utils/toast_util.dart';
import 'package:satya_devotte_app/features/cms/data/models/admin_order_models.dart';
import 'package:satya_devotte_app/features/poojakit/presentation/widgets/order_line_item_picker.dart';
import 'package:satya_devotte_app/features/poojakit/presentation/widgets/pickup_warehouse_return_card.dart';
import 'package:satya_devotte_app/features/poojakit/state/user_orders_controller.dart';

/// Submit a post-delivery **Return** (refund) request.
class ReturnRequestSheet extends StatefulWidget {
  const ReturnRequestSheet({
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
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: ReturnRequestSheet(
          order: order,
          onSubmitted: onSubmitted,
        ),
      ),
    );
  }

  @override
  State<ReturnRequestSheet> createState() => _ReturnRequestSheetState();
}

class _ReturnRequestSheetState extends State<ReturnRequestSheet> {
  final _reasonCtrl = TextEditingController();
  OrderLineSelectionMap _selection = {};
  bool _submitting = false;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _reasonCtrl.text.trim();
    if (_selection.isEmpty) {
      ToastUtil.showInfo('Please select at least one item to return.');
      return;
    }
    if (reason.length < 5) {
      ToastUtil.showInfo('Please explain why you want to return the item(s).');
      return;
    }
    setState(() => _submitting = true);
    final c = Get.find<UserOrdersController>();
    final ok = await c.requestReturn(
      orderId: widget.order.id,
      reason: reason,
      affectedItems: orderLineSelectionToPayload(_selection),
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (!ok) return;
    Navigator.of(context).pop();
    widget.onSubmitted?.call();
    ToastUtil.showSuccess(
      'Your return request has been sent. We will review it shortly.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final multiItem = widget.order.items.length > 1;
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFCF7EF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD6C4A8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Request a return',
                style: AppTypography.lora(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1C1917),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Order #${widget.order.orderNumber}',
                style: AppTypography.inter(
                  fontSize: 13,
                  color: const Color(0xFF78716C),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.order.isPickup
                    ? 'Select the item(s) to return. After approval, bring them to '
                        'the warehouse below for your refund.'
                    : multiItem
                    ? 'Select the item(s) you want to return. After approval we will '
                        'process a refund for the selected lines.'
                    : 'Tell us why you want to return this order. After approval, '
                        'we will process your refund.',
                style: AppTypography.inter(
                  fontSize: 13,
                  height: 1.4,
                  color: const Color(0xFF6C5B46),
                ),
              ),
              const SizedBox(height: 16),
              OrderLineItemPicker(
                order: widget.order,
                selection: _selection,
                title: 'Items to return',
                subtitle: multiItem
                    ? 'Select one or more products from this order.'
                    : null,
                onChanged: (next) => setState(() => _selection = next),
              ),
              if (widget.order.isPickup) ...[
                const SizedBox(height: 12),
                PickupWarehouseReturnCard(order: widget.order),
              ],
              const SizedBox(height: 16),
              Text(
                'Reason for return',
                style: AppTypography.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF44403C),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _reasonCtrl,
                maxLines: 4,
                maxLength: 2000,
                decoration: InputDecoration(
                  hintText:
                      'e.g. Wrong item received, product damaged, no longer needed',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE7D5BC)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB45309),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Submit return request',
                          style: AppTypography.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
