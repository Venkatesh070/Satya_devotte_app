// lib/features/poojakit/presentation/pages/user_order_detail_screen.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/core/utils/toast_util.dart';
import 'package:satya_devotte_app/features/cms/data/models/admin_order_models.dart';
import 'package:satya_devotte_app/features/donations/presentation/widgets/donation_ui.dart';
import 'package:satya_devotte_app/features/poojakit/presentation/widgets/replacement_request_sheet.dart';
import 'package:satya_devotte_app/features/poojakit/state/user_orders_controller.dart';
import 'package:satya_devotte_app/shared/widgets/custom_button.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:satya_devotte_app/shared/widgets/gradient_outline_input_border.dart';

const _figmaActionGradient = [AppColors.gradientStart, AppColors.gradientEnd];

class UserOrderDetailScreen extends StatefulWidget {
  const UserOrderDetailScreen({super.key});

  @override
  State<UserOrderDetailScreen> createState() => _UserOrderDetailScreenState();
}

class _UserOrderDetailScreenState extends State<UserOrderDetailScreen> {
  late AdminOrder _order;
  final _c = Get.find<UserOrdersController>();

  @override
  void initState() {
    super.initState();
    _order = Get.arguments as AdminOrder;
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    final updated = await _c.refreshOrderDetail(_order.id);
    if (updated != null && mounted) {
      setState(() => _order = updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBgColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TopBar(onBack: () => Get.back()),
                const SizedBox(height: 18),
                Text(
                  'Order Summary',
                  style: AppTypography.lora(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF4A1C00),
                  ),
                ),
                const SizedBox(height: 16),
                _OrderItemCard(order: _order),
                const SizedBox(height: 16),
                _DeliveryCard(order: _order),
                const SizedBox(height: 12),
                _BillSummaryCard(order: _order),
                const SizedBox(height: 12),
                _TransactionCard(order: _order),
                const SizedBox(height: 14),
                _ActionSection(
                  order: _order,
                  controller: _c,
                  onRefresh: _refresh,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderItemCard extends StatelessWidget {
  const _OrderItemCard({required this.order});
  final AdminOrder order;

  @override
  Widget build(BuildContext context) {
    final item = order.items.isNotEmpty ? order.items.first : null;
    final title = item?.title.trim().isNotEmpty == true
        ? item!.title
        : 'Lakshmi Puja Kit';
    final itemCount = order.items.length;
    final qty = item?.qty ?? 0;

    return Column(
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
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          // maxLines: 1,
                          // overflow: TextOverflow.ellipsis,
                          style: AppTypography.lora(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF2B1A0C),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  _OrderStatusPill(order: order),

                  const SizedBox(height: 7),

                  _Bullet(
                    text: itemCount > 1
                        ? '$itemCount products in this order.'
                        : qty == 0
                        ? 'Puja kit essentials included.'
                        : 'Quantity: $qty',
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
                      itemCount > 1
                          ? 'No of products : $itemCount'
                          : 'No of items : ${qty == 0 ? 1 : qty}',
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

        if (order.items.length > 1) ...[
          const SizedBox(height: 10),
          ...order.items
              .skip(1)
              .map(
                (lineItem) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _CompactOrderLine(item: lineItem),
                ),
              ),
        ],
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
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFDC5B0A),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard({required this.order});
  final AdminOrder order;

  @override
  Widget build(BuildContext context) {
    final address = order.shippingAddress?.singleLine ?? '';
    return _SummaryCard(
      title: 'Delivery Location',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF183EA4), Color(0xFFE35600)],
            ).createShader(bounds),
            child: const Icon(Icons.location_on, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              address.isEmpty ? 'Address not available' : address,
              style: AppTypography.lora(
                fontSize: 14,
                height: 1.3,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF1C1917),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BillSummaryCard extends StatelessWidget {
  const _BillSummaryCard({required this.order});
  final AdminOrder order;

  @override
  Widget build(BuildContext context) {
    final itemAmount = _billItemAmount(order);
    return _SummaryCard(
      title: 'Bill Summary',
      child: Column(
        children: [
          _RowLine(
            label: '${_firstItemTitle(order)} x${_itemCount(order)}',
            value: _formatOrderCurrency(itemAmount, order.currency),
          ),
          _RowLine(label: 'Delivery Charge', value: order.formattedShipping),
          _RowLine(label: 'Tax', value: order.formattedTax),
          const Divider(height: 18, color: Color(0x1A6B4A2B)),
          _RowLine(
            label: 'Amount Paid',
            value: order.formattedTotal,
            icon: Icons.receipt_long_outlined,
            bold: true,
          ),
        ],
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({required this.order});
  final AdminOrder order;

  @override
  Widget build(BuildContext context) {
    return _SummaryCard(
      title: 'Transaction Summary',
      child: Column(
        children: [
          _RowLine(label: 'Transaction Date', value: order.formattedDate),
          _RowLine(
            label: 'Transaction ID',
            value: order.paystackReference.isEmpty
                ? order.orderNumber
                : order.paystackReference,
          ),
          _RowLine(
            label: 'Order Status',
            value:
                order.orderStatus == OrderStatus.cancelled &&
                    order.paymentStatus == PaymentStatus.refundInitiated
                ? 'Cancelled - refund initiated'
                : order.orderStatus.label,
          ),
          if (order.invoice?.url.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 36,
              child: OutlinedButton.icon(
                onPressed: () => launchUrl(Uri.parse(order.invoice!.url)),
                icon: const Icon(Icons.download_rounded, size: 16),
                label: const Text('View Invoice'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFE95700),
                  side: const BorderSide(color: Color(0xFFE95700)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionSection extends StatelessWidget {
  const _ActionSection({
    required this.order,
    required this.controller,
    required this.onRefresh,
  });

  final AdminOrder order;
  final UserOrdersController controller;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final canCancel =
        order.orderStatus.canUserCancel ||
        (order.orderStatus == OrderStatus.unknown &&
            !order.orderStatus.isShippedOrBeyond);
    final canConfirm = order.orderStatus == OrderStatus.shipped;
    final canReplace = order.orderStatus == OrderStatus.delivered;

    if (!canCancel && !canConfirm && !canReplace) {
      return const SizedBox.shrink();
    }

    return Obx(() {
      final loading = controller.isMutating;
      return Column(
        children: [
          if (canConfirm)
            _ActionButton(
              label: 'Confirm Delivery',
              icon: Icons.check_circle_outline,
              loading: loading,
              onTap: () async {
                final ok = await controller.confirmDelivery(
                  order.id,
                  satisfied: true,
                );
                if (ok) onRefresh();
              },
            ),
          if (canReplace)
            _ActionButton(
              label: 'Raise Replacement Request',
              icon: Icons.sync_problem_outlined,
              loading: loading,
              onTap: () {
                ReplacementRequestSheet.show(
                  context,
                  orderId: order.id,
                  orderNumber: order.orderNumber,
                  onSubmitted: onRefresh,
                );
              },
            ),
          if (canCancel)
            _ActionButton(
              label: 'Cancel Order',
              icon: Icons.cancel_outlined,
              loading: loading,
              destructive: true,
              onTap: () => _showCancelDialog(order, controller, onRefresh),
            ),
        ],
      );
    });
  }

  void _showCancelDialog(
    AdminOrder order,
    UserOrdersController controller,
    VoidCallback onRefresh,
  ) {
    Get.bottomSheet<void>(
      _CancelOrderDialog(
        order: order,
        controller: controller,
        onRefresh: onRefresh,
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}

class _CancelOrderDialog extends StatefulWidget {
  const _CancelOrderDialog({
    required this.order,
    required this.controller,
    required this.onRefresh,
  });

  final AdminOrder order;
  final UserOrdersController controller;
  final VoidCallback onRefresh;

  @override
  State<_CancelOrderDialog> createState() => _CancelOrderDialogState();
}

class _CancelOrderDialogState extends State<_CancelOrderDialog> {
  late final TextEditingController _reasonCtrl;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _reasonCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _reasonCtrl.text.trim();
    if (reason.isEmpty) {
      ToastUtil.showInfo('Please enter a reason for cancellation.');
      return;
    }

    setState(() => _submitting = true);
    final ok = await widget.controller.cancelOrder(
      widget.order.id,
      reason: reason,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (!ok) return;

    Get.back<void>();
    widget.onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    // final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFEF9F3),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        // bottom: bottomInset > 0 ? false : true,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: DonationUi.cardBorder,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Cancel Order',
                    style: AppTypography.lora(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: DonationUi.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Are you sure you want to cancel order ${widget.order.orderNumber}? Please enter a reason for cancellation.',
                    style: AppTypography.inter(
                      fontSize: 14,
                      height: 1.5,
                      color: DonationUi.textMuted,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _reasonCtrl,
                    enabled: !_submitting,
                    minLines: 3,
                    maxLines: 4,
                    style: AppTypography.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: DonationUi.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter your reason for cancellation',
                      hintStyle: AppTypography.inter(
                        fontSize: 14,
                        color: DonationUi.textMuted.withValues(alpha: 0.5),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: DonationUi.cardBorder,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: DonationUi.cardBorder,
                        ),
                      ),
                      focusedBorder: GradientOutlineInputBorder(
                        gradient: AppColors.inputBorderGradient,
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFED5A00)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    label: _submitting ? 'Cancelling...' : 'Yes, Cancel',
                    textColor: Colors.white,
                    gradientColors: _figmaActionGradient,
                    borderRadius: 14,
                    enabled: !_submitting,
                    onTap: _submit,
                  ),
                ],
              ),
            ),
            Positioned(
              right: 16,
              top: 16,
              child: GestureDetector(
                onTap: _submitting ? null : () => Get.back<void>(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E5D0).withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 20,
                    color: Color(0xFF3B1E08),
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

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.loading,
    required this.onTap,
    this.destructive = false,
  });

  final String label;
  final IconData icon;
  final bool loading;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: SizedBox(
        width: double.infinity,
        height: 44,
        child: OutlinedButton.icon(
          onPressed: loading ? null : onTap,
          icon: loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(icon, size: 17),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            foregroundColor: destructive
                ? Colors.redAccent
                : const Color(0xFFE95700),
            side: BorderSide(
              color: destructive ? Colors.redAccent : const Color(0xFFE95700),
            ),
            textStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.lora(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1C1917),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _RowLine extends StatelessWidget {
  const _RowLine({
    required this.label,
    required this.value,
    this.icon,
    this.bold = false,
  });

  final String label;
  final String value;
  final IconData? icon;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (icon != null) ...[
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF183EA4), Color(0xFFE35600)],
              ).createShader(bounds),
              child: Icon(icon, size: 14, color: Colors.white),
            ),
            const SizedBox(width: 7),
          ],
          Expanded(
            child: Text(
              label,
              style: AppTypography.inter(
                fontSize: 14,
                fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
                color: const Color(0xFF1D1B19),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.inter(
                fontSize: 14,
                fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
                color: const Color(0xFF1D1B19),
              ),
            ),
          ),
        ],
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

    return Container(
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
    );
  }
}

class _CompactOrderLine extends StatelessWidget {
  const _CompactOrderLine({required this.item});

  final OrderLineItem item;

  @override
  Widget build(BuildContext context) {
    final title = item.title.trim().isEmpty ? 'Puja Kit' : item.title.trim();
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 42,
              height: 42,
              child: item.image.trim().isNotEmpty
                  ? Image.network(
                      item.image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const _ThumbFallback(),
                    )
                  : const _ThumbFallback(),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.lora(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1C1917),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Qty: ${item.qty}',
            style: AppTypography.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF6C5B46),
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
    return ColoredBox(
      color: Color(0xFFFFF7E8),
      child: Image.asset('assets/images/default_img.png', fit: BoxFit.cover),
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
                height: 1.25,
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
    return Align(
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
    );
  }
}

String _firstItemTitle(AdminOrder order) {
  if (order.items.isEmpty) return 'Lakshmi puja kit';
  final title = order.items.first.title.trim();
  return title.isEmpty ? 'Lakshmi puja kit' : title;
}

int _itemCount(AdminOrder order) {
  final count = order.items.fold<int>(0, (sum, item) => sum + item.qty);
  return count == 0 ? order.items.length : count;
}

double _billItemAmount(AdminOrder order) {
  if (order.subtotalAmount > 0) return order.subtotalAmount;

  final lineTotal = order.items.fold<double>(
    0,
    (sum, item) => sum + item.lineTotal,
  );
  if (lineTotal > 0) return lineTotal;

  final derived = order.totalAmount - order.shippingAmount - order.taxAmount;
  if (derived > 0) return derived;

  return order.totalAmount;
}

String _formatOrderCurrency(double amount, String currency) {
  final symbol = currency.trim().isEmpty ? 'ZAR' : currency.toUpperCase();
  final decimals = amount.truncateToDouble() == amount ? 0 : 2;
  return '$symbol ${amount.toStringAsFixed(decimals)}';
}
