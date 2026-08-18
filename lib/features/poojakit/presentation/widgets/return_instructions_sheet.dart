import 'package:flutter/material.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/features/cms/data/models/admin_order_models.dart';
import 'package:satya_devotte_app/features/cms/data/models/admin_order_request_models.dart';
import 'package:satya_devotte_app/features/poojakit/presentation/widgets/user_order_status_chips.dart';
import 'package:url_launcher/url_launcher.dart';

/// Bottom sheet with return instructions after a replacement is approved.
class ReturnInstructionsSheet extends StatelessWidget {
  const ReturnInstructionsSheet({
    super.key,
    required this.order,
    this.request,
  });

  final AdminOrder order;
  final OrderRequest? request;

  static Future<void> show(
    BuildContext context, {
    required AdminOrder order,
    OrderRequest? request,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReturnInstructionsSheet(order: order, request: request),
    );
  }

  String get _title {
    final label = resolvedReplacementStatusLabel(order: order, request: request);
    if (label != null && label.isNotEmpty) return label;
    return order.isPickup ? 'Return to warehouse' : 'Return damaged item';
  }

  String get _body {
    final info = request?.returnInfo;
    final instructions = info?.instructions.trim() ?? '';
    if (instructions.isNotEmpty) return instructions;

    final summary = order.latestReplacementRequest;
    final summaryInstructions = summary?.returnInstructions.trim() ?? '';
    if (summaryInstructions.isNotEmpty) return summaryInstructions;

    if (order.isPickup) {
      final loc = order.pickupLocation;
      final name = loc?.company.trim().isNotEmpty == true
          ? loc!.company
          : 'the warehouse';
      final addr = loc?.singleLine ?? '';
      return [
        'Bring the damaged item to $name.',
        if (addr.isNotEmpty) 'Address: $addr',
        if (loc?.hours.trim().isNotEmpty == true) 'Hours: ${loc!.hours}',
        'Bring order ${order.orderNumber} and a valid ID.',
      ].join('\n');
    }

    final waybill =
        info?.waybill.trim() ?? summary?.returnWaybill.trim() ?? '';
    if (waybill.isNotEmpty) {
      return 'A courier will collect the damaged item from your delivery address. '
          'Please keep the parcel ready.\n\nReturn waybill: $waybill';
    }
    return 'Please return the damaged item so we can send your replacement. '
        'For delivery orders a courier collection will be arranged; '
        'for pickup orders return the item to the warehouse.';
  }

  String? get _trackingUrl {
    final fromRequest = request?.returnInfo.trackingUrl.trim();
    if (fromRequest != null && fromRequest.isNotEmpty) return fromRequest;
    final fromSummary = order.latestReplacementRequest?.returnTrackingUrl.trim();
    if (fromSummary != null && fromSummary.isNotEmpty) return fromSummary;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final trackingUrl = _trackingUrl;
    final requestNumber = request?.requestNumber.trim().isNotEmpty == true
        ? request!.requestNumber
        : order.latestReplacementRequest?.requestNumber ?? '';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFCF7EF),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
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
            Row(
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                  color: Color(0xFFB45309),
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _title,
                    style: AppTypography.lora(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF9A3412),
                    ),
                  ),
                ),
              ],
            ),
            if (requestNumber.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Request $requestNumber · Order ${order.orderNumber}',
                style: AppTypography.inter(
                  fontSize: 12,
                  color: const Color(0xFF78716C),
                ),
              ),
            ],
            const SizedBox(height: 14),
            Text(
              _body,
              style: AppTypography.inter(
                fontSize: 13,
                height: 1.5,
                color: const Color(0xFF44403C),
              ),
            ),
            if (trackingUrl != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final uri = Uri.tryParse(trackingUrl);
                    if (uri == null) return;
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                  icon: const Icon(Icons.local_shipping_outlined, size: 18),
                  label: const Text('Track return collection'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFB45309),
                    side: const BorderSide(color: Color(0xFFFDBA74)),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC5B0A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Got it',
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
