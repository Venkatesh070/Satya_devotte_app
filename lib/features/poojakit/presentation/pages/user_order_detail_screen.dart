// lib/features/poojakit/presentation/pages/user_order_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/features/cms/data/models/admin_order_models.dart';
import 'package:satya_devotte_app/features/poojakit/state/user_orders_controller.dart';
import 'package:satya_devotte_app/shared/widgets/app_background.dart';
import 'package:url_launcher/url_launcher.dart';

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
  }

  Future<void> _refresh() async {
    final updated = await _c.refreshOrderDetail(_order.id);
    if (updated != null && mounted) {
      setState(() => _order = updated);
    }
  }

  void _onConfirmDelivery() {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          'Confirm Delivery',
          style: AppTypography.lora(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Have you received your order and are you satisfied with it?',
              style: AppTypography.inter(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Text(
              'Note: If you are not satisfied, please email support at stangudu@linkfields.com with your order reference number.',
              style: AppTypography.inter(
                color: const Color(0xFFFFD180),
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              final success = await _c.confirmDelivery(
                _order.id,
                satisfied: true,
              );
              if (success) {
                _refresh();
                Get.snackbar(
                  'Success',
                  'Delivery confirmed. Thank you!',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.green.withOpacity(0.8),
                  colorText: Colors.white,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Yes, Received'),
          ),
        ],
      ),
    );
  }

  void _onCancelOrder() {
    final isPaid = _order.paymentStatus == PaymentStatus.paid;

    if (isPaid) {
      Get.dialog(
        AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: Text(
            'Cancel Paid Order',
            style: AppTypography.lora(color: Colors.white),
          ),
          content: Text(
            'This order is already paid. To request a cancellation and refund, please contact our support team at superadmin@satya.com with your Order Number: ${_order.orderNumber}.',
            style: AppTypography.inter(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text(
                'Close',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                final name = _order.userName.isNotEmpty
                    ? _order.userName
                    : (_order.shippingAddress?.name ?? 'Not provided');
                final email = _order.userEmail.isNotEmpty
                    ? _order.userEmail
                    : (_order.shippingAddress?.email ?? 'Not provided');

                final body =
                    'Cancellation Request Details:\n'
                    'Order Number: ${_order.orderNumber}\n'
                    'Registered Name: $name\n'
                    'Registered Email: $email\n\n'
                    'Please enter your reason for cancellation here:';

                final Uri emailLaunchUri = Uri(
                  scheme: 'mailto',
                  path: 'stangudu@linkfields.com',
                  query:
                      'subject=Cancellation Request: ${_order.orderNumber}&body=${Uri.encodeComponent(body)}',
                );
                launchUrl(emailLaunchUri);
              },
              icon: const Icon(
                Icons.email_outlined,
                size: 18,
                color: Colors.black,
              ),
              label: const Text(
                'Send Email',
                style: TextStyle(color: Colors.black),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD180),
              ),
            ),
          ],
        ),
      );
      return;
    }

    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          'Cancel Order',
          style: AppTypography.lora(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to cancel this order?',
          style: AppTypography.inter(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('No', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              final success = await _c.cancelOrder(_order.id);
              if (success) {
                _refresh();
                Get.snackbar(
                  'Success',
                  'Order cancelled successfully',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.orange.withOpacity(0.8),
                  colorText: Colors.white,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Order Details',
          style: AppTypography.lora(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Get.back(),
        ),
      ),
      body: AppBackground(
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: const Color(0xFFFFD180),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusSection(),
                const SizedBox(height: 20),
                _buildItemsSection(),
                const SizedBox(height: 20),
                _buildShippingSection(),
                const SizedBox(height: 20),
                _buildPaymentSection(),
                const SizedBox(height: 20),
                if (_order.tracking != null &&
                    _order.tracking!.hasTrackingNumber) ...[
                  _buildTrackingSection(),
                  const SizedBox(height: 20),
                ],
                if (_order.invoice != null &&
                    _order.invoice!.url.isNotEmpty) ...[
                  _buildInvoiceSection(),
                  const SizedBox(height: 20),
                ],
                _buildActions(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order #${_order.orderNumber}',
                style: AppTypography.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _order.formattedDate,
                style: AppTypography.inter(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ],
          ),
          _StatusBadge(status: _order.orderStatus),
        ],
      ),
    );
  }

  Widget _buildItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Items',
          style: AppTypography.lora(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _order.items.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: Colors.white10),
            itemBuilder: (context, index) {
              final item = _order.items[index];
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: item.image.isNotEmpty
                          ? Image.network(
                              item.image,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 60,
                              height: 60,
                              color: Colors.white10,
                              child: const Icon(
                                Icons.image,
                                color: Colors.white24,
                              ),
                            ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: AppTypography.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Qty: ${item.qty}',
                            style: AppTypography.inter(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${_order.currency} ${item.lineTotal.toStringAsFixed(2)}',
                      style: AppTypography.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFFD180),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildShippingSection() {
    final addr = _order.shippingAddress;
    if (addr == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Shipping Address',
          style: AppTypography.lora(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                addr.name,
                style: AppTypography.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${addr.line1}\n${addr.city}, ${addr.region} ${addr.postalCode}\n${addr.country}',
                style: AppTypography.inter(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.phone, size: 16, color: Color(0xFFFFD180)),
                  const SizedBox(width: 8),
                  Text(
                    addr.phone,
                    style: AppTypography.inter(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Details',
          style: AppTypography.lora(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              _buildInfoRow('Method', _order.paymentMethod),
              const SizedBox(height: 12),
              _buildInfoRow('Status', _order.paymentStatus.name.toUpperCase()),
              const SizedBox(height: 12),
              const Divider(color: Colors.white12),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Amount',
                    style: AppTypography.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    _order.formattedTotal,
                    style: AppTypography.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFFD180),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrackingSection() {
    final t = _order.tracking!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tracking Information',
          style: AppTypography.lora(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (t.courier.isNotEmpty) ...[
                _buildInfoRow('Courier', t.courier),
                const SizedBox(height: 12),
              ],
              _buildInfoRow('Tracking Number', t.trackingNumber),
              if (t.trackingUrl.isNotEmpty) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => launchUrl(Uri.parse(t.trackingUrl)),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('Track Package'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFFD180),
                      side: const BorderSide(color: Color(0xFFFFD180)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceSection() {
    final inv = _order.invoice!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Invoice',
          style: AppTypography.lora(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('Invoice Number', inv.number),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => launchUrl(Uri.parse(inv.url)),
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('View Invoice'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD180),
                    foregroundColor: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.inter(
            fontSize: 14,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
        Text(
          value,
          style: AppTypography.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    final canCancel =
        (_order.orderStatus == OrderStatus.placed ||
        _order.orderStatus == OrderStatus.processing);
    final canConfirm = _order.orderStatus == OrderStatus.shipped;

    if (!canCancel && !canConfirm) {
      // Show support info if already delivered or fulfilled
      if (_order.orderStatus == OrderStatus.delivered ||
          _order.orderStatus == OrderStatus.fulfilled) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Need help with your order?',
                style: AppTypography.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'If you have any issues or wish to apply for a refund/replacement, please email us at stangudu@linkfields.com with your order number.',
                style: AppTypography.inter(fontSize: 13, color: Colors.white70),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    final name = _order.userName.isNotEmpty
                        ? _order.userName
                        : (_order.shippingAddress?.name ?? 'Not provided');
                    final email = _order.userEmail.isNotEmpty
                        ? _order.userEmail
                        : (_order.shippingAddress?.email ?? 'Not provided');

                    final body =
                        'Order Support Request:\n'
                        'Order Number: ${_order.orderNumber}\n'
                        'Registered Name: $name\n'
                        'Registered Email: $email\n\n'
                        'Please describe the issue with your order:';

                    final Uri emailLaunchUri = Uri(
                      scheme: 'mailto',
                      path: 'stangudu@linkfields.com',
                      query:
                          'subject=Order Support: ${_order.orderNumber}&body=${Uri.encodeComponent(body)}',
                    );
                    launchUrl(emailLaunchUri);
                  },
                  icon: const Icon(Icons.support_agent, size: 18),
                  label: const Text('Contact Support'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFFD180),
                    side: const BorderSide(color: Color(0xFFFFD180)),
                  ),
                ),
              ),
            ],
          ),
        );
      }
      return const SizedBox.shrink();
    }

    return Obx(() {
      final loading = _c.isMutating;
      return Column(
        children: [
          const SizedBox(height: 12),
          if (canConfirm)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: loading ? null : _onConfirmDelivery,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Confirm Delivery',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          if (canCancel)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: loading ? null : _onCancelOrder,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.redAccent,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Cancel Order',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
        ],
      );
    });
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case OrderStatus.placed:
        color = Colors.blue;
        break;
      case OrderStatus.processing:
        color = Colors.orange;
        break;
      case OrderStatus.shipped:
        color = Colors.purple;
        break;
      case OrderStatus.delivered:
      case OrderStatus.fulfilled:
        color = Colors.green;
        break;
      case OrderStatus.cancelled:
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        status.label.toUpperCase(),
        style: AppTypography.inter(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
