// lib/features/poojakit/presentation/widgets/order_fulfillment_feedback_sheet.dart

import 'package:flutter/material.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';

/// User confirms receipt / pickup with satisfaction level and optional comments.
class OrderFulfillmentFeedbackResult {
  const OrderFulfillmentFeedbackResult({
    required this.satisfied,
    this.feedback,
  });

  final bool satisfied;
  final String? feedback;
}

class OrderFulfillmentFeedbackSheet extends StatefulWidget {
  const OrderFulfillmentFeedbackSheet({
    super.key,
    required this.isPickup,
  });

  final bool isPickup;

  static Future<OrderFulfillmentFeedbackResult?> show(
    BuildContext context, {
    required bool isPickup,
  }) {
    return showModalBottomSheet<OrderFulfillmentFeedbackResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OrderFulfillmentFeedbackSheet(isPickup: isPickup),
    );
  }

  @override
  State<OrderFulfillmentFeedbackSheet> createState() =>
      _OrderFulfillmentFeedbackSheetState();
}

class _OrderFulfillmentFeedbackSheetState
    extends State<OrderFulfillmentFeedbackSheet> {
  bool? _satisfied;
  final _feedbackCtrl = TextEditingController();

  @override
  void dispose() {
    _feedbackCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_satisfied == null) return;
    final feedback = _feedbackCtrl.text.trim();
    Navigator.of(context).pop(
      OrderFulfillmentFeedbackResult(
        satisfied: _satisfied!,
        feedback: feedback.isEmpty ? null : feedback,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const title = 'Share your feedback';
    final subtitle = widget.isPickup
        ? 'Your order was picked up at the warehouse. How was your experience?'
        : 'Your order was delivered. How was your experience?';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFCF7EF),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
              title,
              style: AppTypography.lora(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1C1917),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: AppTypography.inter(
                fontSize: 13,
                height: 1.45,
                color: const Color(0xFF6C5B46),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Satisfied with your order?',
              style: AppTypography.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF44403C),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _SatisfactionChip(
                    label: 'Yes, satisfied',
                    selected: _satisfied == true,
                    onTap: () => setState(() => _satisfied = true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SatisfactionChip(
                    label: 'No, issue',
                    selected: _satisfied == false,
                    onTap: () => setState(() => _satisfied = false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _feedbackCtrl,
              maxLines: 3,
              maxLength: 2000,
              decoration: InputDecoration(
                labelText: 'Comments (optional)',
                alignLabelWithHint: true,
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
                onPressed: _satisfied == null ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC5B0A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Submit feedback',
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
    );
  }
}

class _SatisfactionChip extends StatelessWidget {
  const _SatisfactionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFFFF7ED) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? const Color(0xFFEA580C)
                  : const Color(0xFFE7D5BC),
              width: selected ? 1.5 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected
                  ? const Color(0xFF9A3412)
                  : const Color(0xFF78716C),
            ),
          ),
        ),
      ),
    );
  }
}
