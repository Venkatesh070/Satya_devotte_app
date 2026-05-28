// lib/features/poojakit/presentation/pages/user_orders_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/features/cms/data/models/admin_order_models.dart';
import 'package:satya_devotte_app/features/poojakit/presentation/widgets/replacement_request_sheet.dart';
import 'package:satya_devotte_app/features/poojakit/state/user_orders_controller.dart';

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
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
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
                            child: CircularProgressIndicator(
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
    final item = order.items.isNotEmpty ? order.items.first : null;
    final title = item?.title.trim().isNotEmpty == true
        ? item!.title
        : 'Lakshmi Puja Kit';
    final count = order.items.fold<int>(0, (sum, e) => sum + e.qty);
    final isDelivered =
        order.orderStatus == OrderStatus.delivered ||
        order.orderStatus == OrderStatus.fulfilled;
    final isCancelled = order.orderStatus == OrderStatus.cancelled;
    final dateLabel = isDelivered
        ? 'Delivered on'
        : isCancelled
        ? 'Cancelled on'
        : 'Ordered on';

    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.userOrderDetail, arguments: order),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.62),
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
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _OrderThumb(image: item?.image ?? ''),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.lora(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF1C1917),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
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
                      const SizedBox(height: 7),
                      _OrderStatusPill(order: order),
                      const SizedBox(height: 7),

                      _Bullet(
                        text: count == 0
                            ? 'Puja kit essentials included.'
                            : '$count items required for performing the puja.',
                      ),
                      const _Bullet(text: 'Sufficient for 2 members.'),
                      const SizedBox(height: 8),
                      Container(
                        height: 22,
                        width: double.infinity,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Text(
                          'No of items : ${count == 0 ? order.items.length : count}',
                          style: AppTypography.inter(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF8B765D),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
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
            if (order.orderStatus == OrderStatus.delivered) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 34,
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ReplacementRequestSheet.show(
                      context,
                      orderId: order.id,
                      orderNumber: order.orderNumber,
                      onSubmitted: () =>
                          Get.find<UserOrdersController>().fetchOrders(),
                    );
                  },
                  icon: const Icon(Icons.sync_problem_outlined, size: 15),
                  label: const Text('Raise Replacement Request'),
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

Color _statusColor(OrderStatus status) {
  switch (status) {
    case OrderStatus.cancelled:
      return const Color(0xFFD14343);
    case OrderStatus.delivered:
    case OrderStatus.fulfilled:
      return const Color(0xFF088B56);
    case OrderStatus.shipped:
      return const Color(0xFF253FA8);
    case OrderStatus.processing:
      return const Color(0xFFC06A2D);
    case OrderStatus.placed:
      return const Color(0xFFE95700);
    case OrderStatus.unknown:
      return const Color(0xFF78716C);
  }
}

class _OrderThumb extends StatelessWidget {
  const _OrderThumb({required this.image});
  final String image;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 100,
        height: 100,
        child: image.trim().isNotEmpty
            ? Image.network(
                image,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const _ThumbFallback(),
              )
            : const _ThumbFallback(),
      ),
    );
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

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '. ',
            style: AppTypography.inter(
              fontSize: 12,
              height: 1.25,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF78716C),
            ),
          ),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.inter(
                fontSize: 10,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF78716C),
              ),
            ),
          ),
        ],
      ),
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
          color: Colors.white,
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
