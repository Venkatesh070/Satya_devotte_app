import 'package:flutter/material.dart';
import 'package:satya_devotte_app/core/config/order_return_replace_config.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/features/cms/data/models/admin_order_models.dart';
import 'package:satya_devotte_app/features/cms/data/models/admin_order_request_models.dart';
import 'package:satya_devotte_app/features/poojakit/presentation/widgets/user_refund_status.dart';

Color userOrderStatusColor(OrderStatus status) {
  switch (status) {
    case OrderStatus.cancelled:
      return const Color(0xFFD14343);
    case OrderStatus.delivered:
    case OrderStatus.fulfilled:
      return const Color(0xFF088B56);
    case OrderStatus.shipped:
    case OrderStatus.outForDelivery:
      return const Color(0xFF1D4ED8);
    case OrderStatus.readyForPickup:
    case OrderStatus.packed:
    case OrderStatus.collected:
      return const Color(0xFF0F766E);
    case OrderStatus.processing:
      return const Color(0xFFC06A2D);
    case OrderStatus.placed:
      return const Color(0xFF78716C);
    case OrderStatus.unknown:
      return const Color(0xFF78716C);
  }
}

Color replacementStatusToneColor(String tone) {
  switch (tone) {
    case 'requested':
      return const Color(0xFFC2410C);
    case 'awaiting_return':
    case 'return_transit':
    case 'in_progress':
      return const Color(0xFFB45309);
    case 'returned':
      return const Color(0xFF0369A1);
    case 'completed':
      return const Color(0xFF047857);
    case 'rejected':
      return const Color(0xFFB91C1C);
    case 'replacement_order':
      return const Color(0xFF1D4ED8);
    default:
      return const Color(0xFFB45309);
  }
}

String primaryOrderStatusLabel(AdminOrder order) {
  if (order.orderStatus == OrderStatus.cancelled &&
      order.paymentStatus == PaymentStatus.refundInitiated) {
    return 'Cancelled - refund initiated';
  }
  if (order.orderStatus == OrderStatus.cancelled &&
      order.paymentStatus == PaymentStatus.refunded) {
    return 'Cancelled - refunded';
  }
  return order.orderStatus.label;
}

/// Prefer live replacement-request status when available (detail screen).
String? resolvedReplacementStatusLabel({
  required AdminOrder order,
  OrderRequest? request,
}) {
  if (!kOrderReturnReplaceEnabled) return null;
  if (request != null) {
    final rs = request.returnInfo.status.toUpperCase().trim();
    if (rs == 'RETURN_RECEIVED' ||
        request.status == OrderRequestStatus.returnReceived) {
      return 'Returned';
    }
    if (rs == 'RETURN_BOOKED' || rs == 'RETURN_IN_TRANSIT') {
      return 'Return in transit';
    }
    switch (request.status) {
      case OrderRequestStatus.requested:
        return 'Replacement requested';
      case OrderRequestStatus.approved:
      case OrderRequestStatus.awaitingReturn:
        return 'Awaiting return';
      case OrderRequestStatus.processing:
        return 'Replacement processing';
      case OrderRequestStatus.shipped:
        return 'Replacement shipped';
      case OrderRequestStatus.delivered:
        return 'Replacement completed';
      case OrderRequestStatus.rejected:
        return 'Replacement rejected';
      case OrderRequestStatus.cancelled:
        return 'Replacement cancelled';
      case OrderRequestStatus.returnReceived:
        return 'Returned';
      case OrderRequestStatus.unknown:
        break;
    }
  }
  return order.replacementStatusLabel;
}

String resolvedReplacementStatusTone({
  required AdminOrder order,
  OrderRequest? request,
}) {
  if (request != null) {
    final rs = request.returnInfo.status.toUpperCase().trim();
    if (rs == 'RETURN_RECEIVED' ||
        request.status == OrderRequestStatus.returnReceived) {
      return 'returned';
    }
    if (rs == 'RETURN_BOOKED' || rs == 'RETURN_IN_TRANSIT') {
      return 'return_transit';
    }
    switch (request.status) {
      case OrderRequestStatus.requested:
        return 'requested';
      case OrderRequestStatus.approved:
      case OrderRequestStatus.awaitingReturn:
        return 'awaiting_return';
      case OrderRequestStatus.processing:
      case OrderRequestStatus.shipped:
        return 'in_progress';
      case OrderRequestStatus.delivered:
        return 'completed';
      case OrderRequestStatus.rejected:
      case OrderRequestStatus.cancelled:
        return 'rejected';
      case OrderRequestStatus.returnReceived:
        return 'returned';
      case OrderRequestStatus.unknown:
        break;
    }
  }
  return order.replacementStatusTone;
}

/// Whether [productId] is part of the request's selected items.
/// Empty list means no explicit selection (do not match every line).
bool productInAffectedList(String productId, List<OrderAffectedItem> items) {
  final id = productId.trim();
  if (id.isEmpty || items.isEmpty) return false;
  return items.any((item) => item.productId.trim() == id);
}

bool productInAffectedIds(String productId, List<String> ids) {
  final id = productId.trim();
  if (id.isEmpty || ids.isEmpty) return false;
  return ids.any((entry) => entry.trim() == id);
}

/// Per-line status for a product in a group order (return / replace).
({String label, Color color})? resolvedItemLineStatus({
  required AdminOrder order,
  required String productId,
  OrderRequest? replacementRequest,
  OrderRequest? refundRequest,
}) {
  final id = productId.trim();
  if (id.isEmpty) return null;

  // Prefer live replacement request, then order summary.
  if (replacementRequest != null &&
      replacementRequest.type == OrderRequestType.replacement &&
      replacementRequest.affectedItems.isNotEmpty &&
      productInAffectedList(id, replacementRequest.affectedItems)) {
    final label = resolvedReplacementStatusLabel(
      order: order,
      request: replacementRequest,
    );
    if (label != null && label.isNotEmpty) {
      final tone = resolvedReplacementStatusTone(
        order: order,
        request: replacementRequest,
      );
      return (label: label, color: replacementStatusToneColor(tone));
    }
  }

  final summary = order.latestReplacementRequest;
  if (summary != null &&
      summary.affectedProductIds.isNotEmpty &&
      productInAffectedIds(id, summary.affectedProductIds)) {
    final label = summary.userFacingStatusLabel;
    if (label != null && label.isNotEmpty) {
      return (
        label: label,
        color: replacementStatusToneColor(summary.userFacingStatusTone),
      );
    }
  }

  if (refundRequest != null &&
      refundRequest.type == OrderRequestType.refund &&
      refundRequest.affectedItems.isNotEmpty &&
      productInAffectedList(id, refundRequest.affectedItems)) {
    final label = resolvedRefundStatusLabel(
      order: order,
      request: refundRequest,
    );
    if (label != null && label.isNotEmpty) {
      final tone = resolvedRefundStatusTone(
        order: order,
        request: refundRequest,
      );
      return (label: label, color: refundStatusToneColor(tone));
    }
  }

  return null;
}

/// True when return/replace status should be shown on line items instead of
/// the order header (multi-item orders with an explicit item selection).
bool shouldShowItemLevelReturnReplaceTags(
  AdminOrder order, {
  OrderRequest? request,
  OrderRequest? refundRequest,
}) {
  if (!kOrderReturnReplaceEnabled) return false;
  if (order.items.length <= 1) return false;
  final summaryIds =
      order.latestReplacementRequest?.affectedProductIds ?? const <String>[];
  final hasReplacementSelection =
      (request?.type == OrderRequestType.replacement &&
          (request?.affectedItems.isNotEmpty ?? false)) ||
      summaryIds.isNotEmpty;
  final hasRefundSelection =
      refundRequest?.type == OrderRequestType.refund &&
      (refundRequest?.affectedItems.isNotEmpty ?? false);
  return hasReplacementSelection || hasRefundSelection;
}

class UserOrderStatusChips extends StatelessWidget {
  const UserOrderStatusChips({
    super.key,
    required this.order,
    this.request,
    this.refundRequest,
    this.compact = false,
  });

  final AdminOrder order;
  final OrderRequest? request;
  final OrderRequest? refundRequest;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final primary = primaryOrderStatusLabel(order);
    final primaryColor = userOrderStatusColor(order.orderStatus);
    final itemLevel = shouldShowItemLevelReturnReplaceTags(
      order,
      request: request,
      refundRequest: refundRequest,
    );
    final replacementLabel = itemLevel
        ? null
        : resolvedReplacementStatusLabel(
            order: order,
            request: request,
          );
    final replacementTone = resolvedReplacementStatusTone(
      order: order,
      request: request,
    );
    final refundLabel = itemLevel
        ? null
        : resolvedRefundStatusLabel(
            order: order,
            request: refundRequest,
          );
    final refundTone = resolvedRefundStatusTone(
      order: order,
      request: refundRequest,
    );

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _StatusChip(
          label: primary,
          color: primaryColor,
          compact: compact,
        ),
        if (refundLabel != null && refundLabel.isNotEmpty)
          _StatusChip(
            label: refundLabel,
            color: refundStatusToneColor(refundTone),
            compact: compact,
          ),
        if (replacementLabel != null && replacementLabel.isNotEmpty)
          _StatusChip(
            label: replacementLabel,
            color: replacementStatusToneColor(replacementTone),
            compact: compact,
          ),
      ],
    );
  }
}

class ItemLineStatusChip extends StatelessWidget {
  const ItemLineStatusChip({
    super.key,
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: .28)),
      ),
      child: Text(
        label,
        style: AppTypography.inter(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.color,
    required this.compact,
  });

  final String label;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 9 : 10,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: .28)),
      ),
      child: Text(
        label,
        style: AppTypography.inter(
          fontSize: compact ? 9 : 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}
