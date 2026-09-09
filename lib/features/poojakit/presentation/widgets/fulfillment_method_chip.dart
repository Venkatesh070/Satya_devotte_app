import 'package:flutter/material.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/features/cms/data/models/admin_order_models.dart';

/// Compact pickup / delivery label for user-facing order screens.
class FulfillmentMethodChip extends StatelessWidget {
  const FulfillmentMethodChip({super.key, required this.method});

  final FulfillmentMethod method;

  @override
  Widget build(BuildContext context) {
    final isPickup = method.isPickup;
    final color = isPickup ? const Color(0xFF0E7490) : const Color(0xFFC2410C);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.22), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPickup ? Icons.warehouse_outlined : Icons.local_shipping_outlined,
            size: 11.5,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            method.label,
            style: AppTypography.inter(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
