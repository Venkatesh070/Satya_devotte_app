import 'package:flutter/material.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/features/cms/data/models/admin_order_models.dart';
import 'package:satya_devotte_app/features/poojakit/presentation/widgets/replacement_request_sheet.dart';
import 'package:satya_devotte_app/features/poojakit/presentation/widgets/return_request_sheet.dart';

/// Lets the devotee choose **Return** (refund) or **Replace** after pickup or delivery.
class ReturnOrReplaceSheet extends StatelessWidget {
  const ReturnOrReplaceSheet({
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
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ReturnOrReplaceSheet(
        order: order,
        onSubmitted: onSubmitted,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFCF7EF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: SafeArea(
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
              'Return or replace',
              style: AppTypography.lora(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1C1917),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Order #${order.orderNumber}',
              style: AppTypography.inter(
                fontSize: 13,
                color: const Color(0xFF78716C),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              order.isPickup
                  ? 'Choose whether to return or replace, then pick which item(s) apply. '
                      'Approved pickup returns are dropped off at the warehouse.'
                  : order.items.length > 1
                  ? 'Choose whether to return or replace, then pick which item(s) apply.'
                  : 'Choose how you want us to help with this order.',
              style: AppTypography.inter(
                fontSize: 13,
                height: 1.4,
                color: const Color(0xFF6C5B46),
              ),
            ),
            const SizedBox(height: 18),
            _ChoiceTile(
              icon: Icons.undo_rounded,
              title: 'Return',
              subtitle: order.isPickup
                  ? 'Bring item(s) back to the warehouse for a refund.'
                  : 'Send the item(s) back and request a refund.',
              color: const Color(0xFFB45309),
              onTap: () {
                Navigator.of(context).pop();
                ReturnRequestSheet.show(
                  context,
                  order: order,
                  onSubmitted: onSubmitted,
                );
              },
            ),
            const SizedBox(height: 10),
            _ChoiceTile(
              icon: Icons.sync_problem_outlined,
              title: 'Replace',
              subtitle: order.isPickup
                  ? 'Return damaged item(s) to the warehouse for replacement.'
                  : 'Return damaged item(s) and get new ones shipped.',
              color: const Color(0xFFDC5B0A),
              onTap: () {
                Navigator.of(context).pop();
                ReplacementRequestSheet.show(
                  context,
                  order: order,
                  onSubmitted: onSubmitted,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1C1917),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: AppTypography.inter(
                        fontSize: 12,
                        height: 1.35,
                        color: const Color(0xFF78716C),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
