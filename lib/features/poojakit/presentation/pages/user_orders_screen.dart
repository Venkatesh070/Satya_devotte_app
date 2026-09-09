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
            _TopBar(onBack: () => Get.back(), controller: c),
            Expanded(
              child: Obx(() {
                if (c.isLoading && c.orders.isEmpty) {
                  return const Center(
                    child: ChakraLoadingIndicator(
                      size: 32,
                      color: AppColors.primary,
                    ),
                  );
                }

                if (c.error != null && c.orders.isEmpty) {
                  return _EmptyState(
                    icon: Icons.error_outline_rounded,
                    title: 'Could not load orders',
                    message: c.error!,
                    actionLabel: 'Retry',
                    onAction: c.fetchOrders,
                  );
                }

                if (c.orders.isEmpty) {
                  return _EmptyState(
                    icon: Icons.shopping_bag_outlined,
                    title: 'No orders yet',
                    message:
                        'Your puja kits and products orders will appear here.',
                    actionLabel: null,
                    onAction: null,
                  );
                }

                return RefreshIndicator(
                  onRefresh: c.fetchOrders,
                  color: AppColors.primary,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
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
    // final canConfirmFulfillment = order.canUserConfirmFulfillment;
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

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEADBCE), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A1C00).withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Get.toNamed(AppRoutes.userOrderDetail, arguments: order),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row: Order Number & Fulfillment Method
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF4EB),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        size: 16,
                        color: Color(0xFF8B5E3C),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        headline,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.lora(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1C1917),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
                const SizedBox(height: 10),

                // Date & Status Badges
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _OrderDateBadge(
                      label: dateLabel,
                      date: order.formattedDate,
                      isDelivered: isDelivered,
                      isCancelled: isCancelled,
                    ),
                    UserOrderStatusChips(
                      order: order,
                      request: replacementRequest,
                      refundRequest: refundRequest,
                      compact: true,
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFF3EBE0),
                ),
                const SizedBox(height: 12),

                // Items list
                for (int i = 0; i < order.items.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  _CompactOrderLine(
                    item: order.items[i],
                    statusTag: resolvedItemLineStatus(
                      order: order,
                      productId: order.items[i].productId,
                      replacementRequest: replacementRequest,
                      refundRequest: refundRequest,
                    ),
                  ),
                ],

                const SizedBox(height: 12),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFF3EBE0),
                ),
                const SizedBox(height: 10),

                // Footer Row: Total Price + View Details CTA
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Amount',
                          style: AppTypography.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF8C7A6B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            if (order.subtotalAmount > order.totalAmount) ...[
                              Text(
                                order.formattedSubtotal,
                                style: AppTypography.inter(
                                  fontSize: 11,
                                  color: const Color(0x8A6C5B46),
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              order.formattedTotal,
                              style: AppTypography.inter(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          'View Details',
                          style: AppTypography.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2255D4),
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: Color(0xFF2255D4),
                        ),
                      ],
                    ),
                  ],
                ),
                if (kOrderReturnReplaceEnabled && order.needsUserReturn) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 36,
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ReturnInstructionsSheet.show(context, order: order);
                      },
                      icon: const Icon(Icons.inventory_2_outlined, size: 15),
                      label: const Text('How to return'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFB45309),
                        side: const BorderSide(color: Color(0xFFFDBA74)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: AppTypography.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
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
                    height: 36,
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: AppTypography.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactOrderLine extends StatelessWidget {
  const _CompactOrderLine({required this.item, this.statusTag});

  final OrderLineItem item;
  final ({String label, Color color})? statusTag;

  @override
  Widget build(BuildContext context) {
    final title = item.title.trim().isEmpty ? 'Puja Kit' : item.title.trim();
    final imageUrl = item.image.trim();

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        // color: const Color(0xFFFCF9F5),
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        // border: Border.all(color: const Color(0xFFEFE6D8), width: 0.9),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFFAF6EE),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFECE4D0)),
              ),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const _ThumbFallback(),
                    )
                  : const _ThumbFallback(),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                    color: const Color(0xFF1C1917),
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0E8DC),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        'Qty: ${item.qty}',
                        style: AppTypography.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF5D4E37),
                        ),
                      ),
                    ),
                    if (statusTag != null) ...[
                      const SizedBox(width: 6),
                      ItemLineStatusChip(
                        label: statusTag!.label,
                        color: statusTag!.color,
                      ),
                    ],
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

class _ThumbFallback extends StatelessWidget {
  const _ThumbFallback();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFFFF7E8),
      child: Center(
        child: Image.asset(
          'assets/images/default_img.png',
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const Icon(
            Icons.shopping_bag_outlined,
            size: 22,
            color: Color(0xFFBCAAA4),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack, required this.controller});

  final VoidCallback onBack;
  final UserOrdersController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Row(
        children: [
          Material(
            color: const Color(0xFFFCF7EF),
            shape: const CircleBorder(),
            elevation: 3,
            shadowColor: const Color(0x1F000000),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onBack,
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(
                  Icons.arrow_back_rounded,
                  size: 20,
                  color: Color(0xFF1C1917),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Orders',
                  style: AppTypography.lora(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF4A1C00),
                  ),
                ),
                Obx(() {
                  final count = controller.orders.length;
                  if (count == 0) return const SizedBox.shrink();
                  return Text(
                    '$count ${count == 1 ? 'order' : 'orders'} placed',
                    style: AppTypography.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF8C7A6B),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
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
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: const Color(0xFFFAF3E8),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFECDDC7), width: 1.5),
              ),
              child: Icon(icon, size: 40, color: const Color(0xFF9A6B3D)),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.lora(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF4A1C00),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.inter(
                fontSize: 12.5,
                height: 1.4,
                color: const Color(0xFF786C5E),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                ),
                child: Text(
                  actionLabel!,
                  style: AppTypography.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
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

class _OrderDateBadge extends StatelessWidget {
  const _OrderDateBadge({
    required this.label,
    required this.date,
    required this.isDelivered,
    required this.isCancelled,
  });

  final String label;
  final String date;
  final bool isDelivered;
  final bool isCancelled;

  @override
  Widget build(BuildContext context) {
    final statusColor = isDelivered
        ? const Color(0xFF088B56)
        : isCancelled
        ? const Color(0xFFD14343)
        : const Color(0xFF9A5B2D);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.20),
          width: 0.7,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isDelivered
                ? Icons.check_circle_outline_rounded
                : isCancelled
                ? Icons.cancel_outlined
                : Icons.calendar_month_outlined,
            size: 11.5,
            color: statusColor,
          ),
          const SizedBox(width: 4.5),
          Text(
            '$label: ',
            style: AppTypography.inter(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF78716C),
            ),
          ),
          Text(
            date,
            style: AppTypography.inter(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }
}
