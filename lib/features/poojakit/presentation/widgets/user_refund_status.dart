import 'package:flutter/material.dart';
import 'package:satya_devotte_app/core/config/order_return_replace_config.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/features/cms/data/models/admin_order_models.dart';
import 'package:satya_devotte_app/features/cms/data/models/admin_order_request_models.dart';
import 'package:satya_devotte_app/features/poojakit/presentation/widgets/order_line_item_picker.dart';
import 'package:satya_devotte_app/features/poojakit/presentation/widgets/pickup_warehouse_return_card.dart';

/// Whether this order has any refund / return activity to surface in UI.
bool orderHasRefundActivity(AdminOrder order, {OrderRequest? request}) {
  if (!kOrderReturnReplaceEnabled) return false;
  if (request != null && request.type == OrderRequestType.refund) return true;
  return order.paymentStatus == PaymentStatus.refundInitiated ||
      order.paymentStatus == PaymentStatus.refunded ||
      order.paymentStatus == PaymentStatus.refundFailed;
}

/// Open refund request still being reviewed, awaiting return, or refund in progress.
bool orderHasOpenRefundRequest(OrderRequest? request) {
  if (request == null || request.type != OrderRequestType.refund) return false;
  return request.status == OrderRequestStatus.requested ||
      request.status == OrderRequestStatus.awaitingReturn ||
      request.status == OrderRequestStatus.approved;
}

bool canUserRequestReturnOrReplace(
  AdminOrder order, {
  OrderRequest? refundRequest,
}) {
  if (!kOrderReturnReplaceEnabled) return false;
  if (!order.canUserRequestReturnOrReplace) return false;
  if (order.hasOpenReplacement) return false;
  if (orderHasOpenRefundRequest(refundRequest)) return false;
  return true;
}

Color refundStatusToneColor(String tone) {
  switch (tone) {
    case 'requested':
      return const Color(0xFFC2410C);
    case 'awaiting_return':
    case 'processing':
      return const Color(0xFFB45309);
    case 'completed':
      return const Color(0xFF047857);
    case 'failed':
    case 'rejected':
      return const Color(0xFFB91C1C);
    default:
      return const Color(0xFF6A1B9A);
  }
}

/// User-facing refund / return status chip label.
String? resolvedRefundStatusLabel({
  required AdminOrder order,
  OrderRequest? request,
}) {
  if (request != null && request.type == OrderRequestType.refund) {
    if (!kOrderReturnReplaceEnabled) return null;
    switch (request.status) {
      case OrderRequestStatus.requested:
        return 'Return requested';
      case OrderRequestStatus.awaitingReturn:
        final rs = request.returnInfo.status.toUpperCase().trim();
        if (rs == 'RETURN_BOOKED' || rs == 'RETURN_IN_TRANSIT') {
          return 'Return in transit';
        }
        return 'Return approved';
      case OrderRequestStatus.approved:
        if (order.paymentStatus == PaymentStatus.refunded) {
          return 'Refunded';
        }
        if (order.paymentStatus == PaymentStatus.refundFailed) {
          return 'Refund failed';
        }
        if (order.paymentStatus == PaymentStatus.refundInitiated) {
          return 'Refund processing';
        }
        return 'Refund processing';
      case OrderRequestStatus.delivered:
        if (order.paymentStatus == PaymentStatus.refunded) {
          return 'Refunded';
        }
        if (order.paymentStatus == PaymentStatus.refundInitiated) {
          return 'Refund processing';
        }
        return 'Return completed';
      case OrderRequestStatus.rejected:
        return 'Return rejected';
      case OrderRequestStatus.cancelled:
        return 'Return cancelled';
      default:
        break;
    }
  }

  switch (order.paymentStatus) {
    case PaymentStatus.refundInitiated:
      return 'Refund processing';
    case PaymentStatus.refunded:
      return 'Refunded';
    case PaymentStatus.refundFailed:
      return 'Refund failed';
    default:
      return null;
  }
}

String resolvedRefundStatusTone({
  required AdminOrder order,
  OrderRequest? request,
}) {
  final label = resolvedRefundStatusLabel(order: order, request: request);
  if (label == null) return 'none';

  if (request != null && request.type == OrderRequestType.refund) {
    switch (request.status) {
      case OrderRequestStatus.requested:
        return 'requested';
      case OrderRequestStatus.awaitingReturn:
        return 'awaiting_return';
      case OrderRequestStatus.rejected:
      case OrderRequestStatus.cancelled:
        return 'rejected';
      case OrderRequestStatus.approved:
      case OrderRequestStatus.delivered:
        if (order.paymentStatus == PaymentStatus.refundFailed) {
          return 'failed';
        }
        if (order.paymentStatus == PaymentStatus.refunded ||
            request.status == OrderRequestStatus.delivered) {
          return 'completed';
        }
        return 'processing';
      default:
        break;
    }
  }

  switch (order.paymentStatus) {
    case PaymentStatus.refundInitiated:
      return 'processing';
    case PaymentStatus.refunded:
      return 'completed';
    case PaymentStatus.refundFailed:
      return 'failed';
    default:
      return 'processing';
  }
}

String refundStatusBannerTitle({
  required AdminOrder order,
  OrderRequest? request,
}) {
  return resolvedRefundStatusLabel(order: order, request: request) ??
      'Return update';
}

String refundStatusBannerBody({
  required AdminOrder order,
  OrderRequest? request,
}) {
  if (request != null && request.type == OrderRequestType.refund) {
    switch (request.status) {
      case OrderRequestStatus.requested:
        return 'We are reviewing your return request. You will be notified once '
            'it is approved.';
      case OrderRequestStatus.awaitingReturn:
        final instructions = request.returnInfo.instructions.trim();
        final tracking = request.returnInfo.trackingUrl.trim();
        if (request.isPickup || order.isPickup) {
          final base = instructions.isNotEmpty
              ? instructions
              : pickupWarehouseReturnInstructions(order);
          return '$base\n\nYour refund will start after we confirm the item(s) '
              'at the warehouse.';
        }
        if (tracking.isNotEmpty) {
          return 'A courier will collect your return. Track the collection '
              'with the link below. Your refund starts after the warehouse '
              'receives the parcel.';
        }
        if (instructions.isNotEmpty) {
          return '$instructions\n\nYour refund starts after the warehouse '
              'receives the item(s).';
        }
        return 'Your return was approved. A courier will collect the item(s), '
            'or our team will confirm receipt at the warehouse. Your refund '
            'starts after we receive the return.';
      case OrderRequestStatus.approved:
        if (order.paymentStatus == PaymentStatus.refunded) {
          return 'Your refund has been processed. It may take a few business days '
              'to appear in your account.';
        }
        if (order.paymentStatus == PaymentStatus.refundFailed) {
          return 'We could not complete the refund automatically. Our team will '
              'follow up with you shortly.';
        }
        return 'We received your return and submitted the refund to PayFast. '
            'Funds usually return in 5–10 business days.';
      case OrderRequestStatus.delivered:
        if (order.paymentStatus == PaymentStatus.refunded) {
          return 'Your refund has been processed. It may take a few business days '
              'to appear in your account.';
        }
        return 'Your return request is complete. If you do not see the refund yet, '
            'allow up to 10 business days.';
      case OrderRequestStatus.rejected:
        final note = request.adminNote.trim();
        if (note.isNotEmpty) {
          return 'Your return request was not approved. Note from our team: $note';
        }
        return 'Your return request was not approved. Contact support if you need '
            'more help.';
      case OrderRequestStatus.cancelled:
        return 'This return request was cancelled.';
      default:
        break;
    }
  }

  switch (order.paymentStatus) {
    case PaymentStatus.refundInitiated:
      return 'Your refund is being processed. Funds usually return in 5–10 '
          'business days.';
    case PaymentStatus.refunded:
      return 'Your refund has been processed. It may take a few business days '
          'to appear in your account.';
    case PaymentStatus.refundFailed:
      return 'We could not complete the refund automatically. Our team will follow '
          'up with you shortly.';
    default:
      return 'Your return request is being processed.';
  }
}

/// Banner for post-delivery return / refund status on order detail.
class UserRefundStatusBanner extends StatelessWidget {
  const UserRefundStatusBanner({
    super.key,
    required this.order,
    this.request,
  });

  final AdminOrder order;
  final OrderRequest? request;

  @override
  Widget build(BuildContext context) {
    if (!orderHasRefundActivity(order, request: request)) {
      return const SizedBox.shrink();
    }

    final tone = resolvedRefundStatusTone(order: order, request: request);
    final toneColor = refundStatusToneColor(tone);
    final title = refundStatusBannerTitle(order: order, request: request);
    final body = refundStatusBannerBody(order: order, request: request);
    final trackingUrl = request?.returnInfo.trackingUrl.trim() ?? '';
    final showWarehouseCard = request != null &&
        request!.type == OrderRequestType.refund &&
        request!.status == OrderRequestStatus.awaitingReturn &&
        (request!.isPickup || order.isPickup);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: toneColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: toneColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.payments_outlined,
                size: 18,
                color: toneColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: toneColor,
                  ),
                ),
              ),
            ],
          ),
          if (request?.requestNumber.isNotEmpty == true) ...[
            const SizedBox(height: 4),
            Text(
              'Request ${request!.requestNumber}',
              style: AppTypography.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: toneColor.withValues(alpha: 0.85),
              ),
            ),
          ],
          if (request?.affectedItems.isNotEmpty == true) ...[
            const SizedBox(height: 6),
            Text(
              'Items: ${formatAffectedItemsSummary(request!.affectedItems, currency: order.currency)}',
              style: AppTypography.inter(
                fontSize: 11,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: toneColor.withValues(alpha: 0.9),
              ),
            ),
          ],
          if (showWarehouseCard) ...[
            const SizedBox(height: 10),
            PickupWarehouseReturnCard(order: order, compact: true),
          ],
          const SizedBox(height: 8),
          Text(
            body,
            style: AppTypography.inter(
              fontSize: 12,
              height: 1.45,
              color: const Color(0xFF7C2D12),
            ),
          ),
          if (trackingUrl.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Tracking: $trackingUrl',
              style: AppTypography.inter(
                fontSize: 11,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: toneColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
