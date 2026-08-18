import 'package:flutter/material.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/features/cms/data/models/admin_order_models.dart';

String pickupWarehouseReturnInstructions(AdminOrder order) {
  final loc = order.pickupLocation;
  final name = loc?.company.trim().isNotEmpty == true
      ? loc!.company
      : 'the warehouse';
  final addr = loc?.singleLine.trim() ?? '';
  return [
    'After approval, bring the selected item(s) to $name.',
    if (addr.isNotEmpty) 'Address: $addr',
    if (loc?.hours.trim().isNotEmpty == true) 'Hours: ${loc!.hours}',
    'Bring order ${order.orderNumber} and a valid ID.',
  ].join('\n');
}

class PickupWarehouseReturnCard extends StatelessWidget {
  const PickupWarehouseReturnCard({
    super.key,
    required this.order,
    this.compact = false,
  });

  final AdminOrder order;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (!order.isPickup) return const SizedBox.shrink();

    final loc = order.pickupLocation;
    final name = loc?.company.trim().isNotEmpty == true
        ? loc!.company
        : 'Warehouse';
    final addr = loc?.singleLine.trim() ?? '';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 10 : 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF99F6E4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.storefront_outlined,
                size: 18,
                color: Color(0xFF0F766E),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Return to warehouse',
                  style: AppTypography.inter(
                    fontSize: compact ? 12 : 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF115E59),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: AppTypography.inter(
              fontSize: compact ? 12 : 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF134E4A),
            ),
          ),
          if (addr.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              addr,
              style: AppTypography.inter(
                fontSize: compact ? 11 : 12,
                height: 1.4,
                color: const Color(0xFF0F766E),
              ),
            ),
          ],
          if (loc?.hours.trim().isNotEmpty == true) ...[
            const SizedBox(height: 4),
            Text(
              'Hours: ${loc!.hours}',
              style: AppTypography.inter(
                fontSize: compact ? 11 : 12,
                color: const Color(0xFF0F766E),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
