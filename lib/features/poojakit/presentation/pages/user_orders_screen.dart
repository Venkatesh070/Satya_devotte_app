// lib/features/poojakit/presentation/pages/user_orders_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/features/cms/data/models/admin_order_models.dart';
import 'package:satya_devotte_app/features/poojakit/presentation/widgets/fulfillment_method_chip.dart';
import 'package:satya_devotte_app/features/poojakit/presentation/widgets/order_fulfillment_feedback_sheet.dart';
import 'package:satya_devotte_app/core/config/order_return_replace_config.dart';
import 'package:satya_devotte_app/features/poojakit/presentation/widgets/return_instructions_sheet.dart';
import 'package:satya_devotte_app/features/poojakit/presentation/widgets/return_or_replace_sheet.dart';
import 'package:satya_devotte_app/features/poojakit/presentation/widgets/user_order_status_chips.dart';
import 'package:satya_devotte_app/features/poojakit/presentation/widgets/user_refund_status.dart';
import 'package:satya_devotte_app/features/poojakit/state/user_orders_controller.dart';
import 'package:satya_devotte_app/shared/widgets/chakra_loading_indicator.dart';

class UserOrdersScreen extends StatelessWidget {
  const UserOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<UserOrdersController>();

    return Scaffold(
      backgroundColor: AppColors.appBgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TopBar(onBack: () => Get.back()),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
              child: Text(
                'My Orders',
                style: AppTypography.lora(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF4A1C00),
                ),
              ),
            ),
            Expanded(
              child: Obx(() {
                if (c.isLoading && c.orders.isEmpty) {
                  return const SizedBox.shrink();
                }

                if (c.error != null && c.orders.isEmpty) {
                  return _EmptyState(
                    icon: Icons.error_outline,
                    title: 'Could not load orders',
                    message: c.error!,
                    actionLabel: 'Retry',
                    onAction: c.fetchOrders,
                  );
                }

                if (c.orders.isEmpty) {
                  return _EmptyState(
                    icon: Icons.shopping_bag_outlined,
                    title: 'No orders found',
                    message: 'Your puja kit orders will appear here.',
                    actionLabel: null,
                    onAction: null,
                  );
                }

                return RefreshIndicator(
                  onRefresh: c.fetchOrders,
                  color: AppColors.primary,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(18, 6, 18, 28),
                    itemCount:
                        c.orders.length + (c.page < c.totalPages ? 1 : 0),
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      if (index == c.orders.length) {
                        c.loadNextPage();
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: ChakraLoadingIndicator(
                              size: 24,
                              color: AppColors.primary,
                            ),
                          ),
                        );
                      }

                      return _OrderCard(order: c.orders[index]);
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});
  final AdminOrder order;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UserOrdersController>();
    final itemCount = order.items.length;
    final isDelivered =
        order.orderStatus == OrderStatus.delivered ||
        order.orderStatus == OrderStatus.fulfilled;
    final isCancelled = order.orderStatus == OrderStatus.cancelled;
    final showPickupPin = order.isPickup &&
        order.hasPickupCollectionCode &&
        order.orderStatus != OrderStatus.fulfilled &&
        order.orderStatus != OrderStatus.cancelled &&
        order.orderStatus != OrderStatus.collected;
    final canConfirmFulfillment = order.canUserConfirmFulfillment;
    final refundRequest = controller.refundRequestFor(order.id);
    final replacementRequest = controller.replacementRequestFor(order.id);
    final dateLabel = isDelivered
        ? 'Delivered on'
        : isCancelled
        ? 'Cancelled on'
        : 'Ordered on';
    final headline = order.orderNumber.isNotEmpty
        ? 'Order #${order.orderNumber}'
        : (itemCount > 1 ? '$itemCount products' : 'Order');

    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.userOrderDetail, arguments: order),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
        decoration: BoxDecoration(
          color: Color(0xFFFCF7EF).withValues(alpha: 0.62),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              headline,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.lora(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1C1917),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$dateLabel : ${order.formattedDate}',
              style: AppTypography.inter(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: isDelivered
                    ? const Color(0xFF088B56)
                    : isCancelled
                    ? const Color(0xFFD14343)
                    : const Color(0xFFC06A2D),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                UserOrderStatusChips(
                  order: order,
                  request: replacementRequest,
                  refundRequest: refundRequest,
                  compact: true,
                ),
                FulfillmentMethodChip(method: order.fulfillmentMethod),
              ],
            ),
            if (showPickupPin) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFCD34D)),
                ),
                child: Text(
                  'Collection PIN: ${order.pickupCollection!.code}',
                  style: AppTypography.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF78350F),
                  ).copyWith(letterSpacing: 1.2),
                ),
              ),
            ],
            if (order.isDelivery && order.delivery?.hasPodStatus == true) ...[
              const SizedBox(height: 8),
              Text(
                'Delivery verified: ${order.delivery!.pod!.displayLabel}',
                style: AppTypography.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF088B56),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              'Items in this order ($itemCount)',
              style: AppTypography.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF6C5B46),
              ),
            ),
            const SizedBox(height: 8),
            ...order.items.map(
              (lineItem) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _CompactOrderLine(
                  item: lineItem,
                  statusTag: resolvedItemLineStatus(
                    order: order,
                    productId: lineItem.productId,
                    replacementRequest: replacementRequest,
                    refundRequest: refundRequest,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (order.subtotalAmount > order.totalAmount) ...[
                  Text(
                    order.formattedSubtotal,
                    style: AppTypography.inter(
                      fontSize: 9,
                      color: const Color(0x8A6C5B46),
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(width: 5),
                ],
                Text(
                  order.formattedTotal,
                  style: AppTypography.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFDC5B0A),
                  ),
                ),
              ],
            ),
            if (canConfirmFulfillment) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 34,
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final result = await OrderFulfillmentFeedbackSheet.show(
                      context,
                      isPickup: order.isPickup,
                    );
                    if (result == null) return;
                    final ok = await controller.confirmDelivery(
                      order.id,
                      satisfied: result.satisfied,
                      feedback: result.feedback,
                    );
                    if (ok) controller.fetchOrders();
                  },
                  icon: const Icon(Icons.rate_review_outlined, size: 15),
                  label: const Text('Feedback'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF088B56),
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
            if (kOrderReturnReplaceEnabled && order.needsUserReturn) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 34,
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ReturnInstructionsSheet.show(
                      context,
                      order: order,
                    );
                  },
                  icon: const Icon(Icons.inventory_2_outlined, size: 15),
                  label: const Text('How to return'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFB45309),
                    side: const BorderSide(color: Color(0xFFFDBA74)),
                    textStyle: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
            if (canUserRequestReturnOrReplace(
              order,
              refundRequest: refundRequest,
            )) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 34,
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ReturnOrReplaceSheet.show(
                      context,
                      order: order,
                      onSubmitted: () =>
                          Get.find<UserOrdersController>().fetchOrders(),
                    );
                  },
                  icon: const Icon(Icons.undo_rounded, size: 15),
                  label: const Text('Return or replace'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE95700),
                    side: const BorderSide(color: Color(0xFFE95700)),
                    textStyle: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OrderStatusPill extends StatelessWidget {
  const _OrderStatusPill({required this.order});

  final AdminOrder order;

  @override
  Widget build(BuildContext context) {
    final statusText =
        order.orderStatus == OrderStatus.cancelled &&
            order.paymentStatus == PaymentStatus.refundInitiated
        ? 'Cancelled - refund initiated'
        : order.orderStatus == OrderStatus.cancelled &&
              order.paymentStatus == PaymentStatus.refunded
        ? 'Cancelled - refunded'
        : order.orderStatus.label;
    final color = _statusColor(order.orderStatus);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: .28)),
        ),
        child: Text(
          statusText,
          style: AppTypography.inter(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _CompactOrderLine extends StatelessWidget {
  const _CompactOrderLine({
    required this.item,
    this.statusTag,
  });

  final OrderLineItem item;
  final ({String label, Color color})? statusTag;

  @override
  Widget build(BuildContext context) {
    final title = item.title.trim().isEmpty ? 'Puja Kit' : item.title.trim();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE7D5BC)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 48,
              height: 48,
              child: item.image.trim().isNotEmpty
                  ? Image.network(
                      item.image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const _ThumbFallback(),
                    )
                  : const _ThumbFallback(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.lora(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1C1917),
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Qty: ${item.qty}',
                      style: AppTypography.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6C5B46),
                      ),
                    ),
                    if (statusTag != null)
                      ItemLineStatusChip(
                        label: statusTag!.label,
                        color: statusTag!.color,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Color _statusColor(OrderStatus status) {
  switch (status) {
    case OrderStatus.cancelled:
      return const Color(0xFFD14343);
    case OrderStatus.delivered:
    case OrderStatus.fulfilled:
      return const Color(0xFF088B56);
    case OrderStatus.shipped:
    case OrderStatus.outForDelivery:
      return const Color(0xFF253FA8);
    case OrderStatus.readyForPickup:
    case OrderStatus.packed:
    case OrderStatus.collected:
      return const Color(0xFF0E7490);
    case OrderStatus.processing:
      return const Color(0xFFC06A2D);
    case OrderStatus.placed:
      return const Color(0xFFE95700);
    case OrderStatus.unknown:
      return const Color(0xFF78716C);
  }
}

class _ThumbFallback extends StatelessWidget {
  const _ThumbFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFFFF7E8),
      child: Icon(Icons.shopping_bag_outlined, color: Color(0x996B4A2B)),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Material(
          color: Color(0xFFFCF7EF),
          shape: const CircleBorder(),
          elevation: 5,
          shadowColor: const Color(0x22000000),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onBack,
            child: const SizedBox(
              width: 40,
              height: 40,
              child: Icon(Icons.arrow_back, size: 19, color: Color(0xFF1C1C1C)),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 58, color: const Color(0x668B765D)),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.lora(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF4A1C00),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.inter(
                fontSize: 11,
                color: const Color(0xFF6C5B46),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
