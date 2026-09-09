// lib/features/poojakit/presentation/pages/user_order_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/core/config/order_return_replace_config.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/core/utils/toast_util.dart';
import 'package:satya_devotte_app/features/cms/data/models/admin_order_models.dart';
import 'package:satya_devotte_app/features/cms/data/models/admin_order_request_models.dart';
import 'package:satya_devotte_app/features/donations/presentation/widgets/donation_ui.dart';
import 'package:satya_devotte_app/features/poojakit/presentation/widgets/order_fulfillment_feedback_sheet.dart';
import 'package:satya_devotte_app/features/poojakit/presentation/widgets/order_line_item_picker.dart';
import 'package:satya_devotte_app/features/poojakit/presentation/widgets/pickup_warehouse_return_card.dart';
import 'package:satya_devotte_app/features/poojakit/presentation/widgets/return_instructions_sheet.dart';
import 'package:satya_devotte_app/features/poojakit/presentation/widgets/return_or_replace_sheet.dart';
import 'package:satya_devotte_app/features/poojakit/presentation/widgets/user_order_status_chips.dart';
import 'package:satya_devotte_app/features/poojakit/presentation/widgets/user_refund_status.dart';
import 'package:satya_devotte_app/features/poojakit/state/user_orders_controller.dart';
import 'package:satya_devotte_app/shared/widgets/custom_button.dart';
import 'package:satya_devotte_app/shared/widgets/order_tracking_progress.dart';
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
  OrderRequest? _replacementRequest;
  OrderRequest? _refundRequest;

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
    if (!kOrderReturnReplaceEnabled) {
      if (mounted) {
        setState(() {
          _replacementRequest = null;
          _refundRequest = null;
        });
      }
      return;
    }
    final replacement = await _c.fetchReplacementRequestForOrder(
      updated ?? _order,
    );
    final refund = await _c.fetchRefundRequestForOrder(updated ?? _order);
    if (mounted) {
      setState(() {
        _replacementRequest = replacement;
        _refundRequest = refund ?? _c.refundRequestFor(_order.id);
      });
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
                const SizedBox(height: 12),
                if (_order.orderNumber.isNotEmpty) ...[
                  Text(
                    'Order ID :',
                    style: AppTypography.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF78716C),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '#${_order.orderNumber}',
                    style: AppTypography.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1C1917),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Order Status : ',
                      style: AppTypography.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF78716C),
                      ),
                    ),
                    const SizedBox(width: 4),
                    UserOrderStatusChips(
                      order: _order,
                      request: _replacementRequest,
                      refundRequest: _refundRequest,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _OrderItemCard(
                  order: _order,
                  replacementRequest: _replacementRequest,
                  refundRequest: _refundRequest,
                ),
                const SizedBox(height: 16),
                _DeliveryCard(order: _order),
                if (_order.isDelivery && _order.hasCourierTracking) ...[
                  const SizedBox(height: 12),
                  _TrackingCard(order: _order),
                ],
                if (kOrderReturnReplaceEnabled &&
                    (_replacementRequest != null ||
                        _order.replacementStatusLabel != null)) ...[
                  const SizedBox(height: 12),
                  _ReplacementReturnBanner(
                    order: _order,
                    request: _replacementRequest,
                    onOpenTracking: (url) async {
                      final uri = Uri.tryParse(url);
                      if (uri == null) return;
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    },
                  ),
                ],
                if (kOrderReturnReplaceEnabled &&
                    orderHasRefundActivity(
                      _order,
                      request: _refundRequest,
                    )) ...[
                  const SizedBox(height: 12),
                  UserRefundStatusBanner(
                    order: _order,
                    request: _refundRequest,
                  ),
                ],
                const SizedBox(height: 12),
                _BillSummaryCard(order: _order),
                const SizedBox(height: 12),
                _TransactionCard(order: _order),
                if (_order.canUserConfirmFulfillment) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF6EE7B7)),
                    ),
                    child: Text(
                      _order.isPickup
                          ? 'Your order was picked up. Share your feedback below.'
                          : 'Your order was delivered. Share your feedback below.',
                      style: AppTypography.inter(
                        fontSize: 12,
                        height: 1.4,
                        color: const Color(0xFF065F46),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                _ActionSection(
                  order: _order,
                  controller: _c,
                  replacementRequest: _replacementRequest,
                  refundRequest: _refundRequest,
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
  const _OrderItemCard({
    required this.order,
    this.replacementRequest,
    this.refundRequest,
  });
  final AdminOrder order;
  final OrderRequest? replacementRequest;
  final OrderRequest? refundRequest;

  @override
  Widget build(BuildContext context) {
    final itemCount = order.items.length;

    return _SummaryCard(
      title: 'Items in this order ($itemCount)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < order.items.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
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
        ],
      ),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard({required this.order});
  final AdminOrder order;

  Future<void> _openMapDirections(String address) async {
    if (address.trim().isEmpty) return;
    final encoded = Uri.encodeComponent(address.trim());
    final url = 'https://www.google.com/maps/dir/?api=1&destination=$encoded';
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPickup = order.isPickup;

    if (isPickup) {
      final address = order.pickupLocation?.singleLine ?? '';
      final code = order.pickupCollection?.code.trim() ?? '';
      final showOtp =
          code.isNotEmpty &&
          order.orderStatus != OrderStatus.fulfilled &&
          order.orderStatus != OrderStatus.cancelled;

      return _SummaryCard(
        title: 'Pick from Warehouse',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pickup Location',
              style: AppTypography.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1C1917),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 1.5),
                  child: Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: Color(0xFF78716C),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    address.isEmpty ? 'Pickup location not available' : address,
                    style: AppTypography.inter(
                      fontSize: 12.5,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                      color: const Color(0xFF78716C),
                    ),
                  ),
                ),
              ],
            ),
            if (address.isNotEmpty) ...[
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => _openMapDirections(address),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2255D4),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  elevation: 0,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Get Directions',
                  style: AppTypography.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
            if (showOtp) ...[
              const SizedBox(height: 18),
              Text(
                'Please provide this OTP at the warehouse during pickup to collect your order.',
                style: AppTypography.inter(
                  fontSize: 12,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1C1917),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: code.split('').map((digit) {
                  return Container(
                    width: 38,
                    height: 38,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD95300),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      digit,
                      style: AppTypography.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      );
    }

    final address = order.shippingAddress?.singleLine ?? '';
    final recipientName = order.shippingAddress?.name.trim().isNotEmpty == true
        ? order.shippingAddress!.name.trim()
        : order.userName.trim();

    final recipientPhone =
        order.shippingAddress?.phone.trim().isNotEmpty == true
        ? order.shippingAddress!.phone.trim()
        : (order.delivery?.deliveryAddress.contactPhone.trim() ?? '');

    final userDetails = [
      if (recipientName.isNotEmpty) recipientName,
      if (recipientPhone.isNotEmpty) recipientPhone,
    ].join(' • ');

    return _SummaryCard(
      title: 'Delivery Details',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery Location',
            style: AppTypography.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1C1917),
            ),
          ),
          const SizedBox(height: 8),
          if (userDetails.isNotEmpty) ...[
            Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 16,
                  color: Color(0xFF78716C),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    userDetails,
                    style: AppTypography.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF44403C),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 1.5),
                child: Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: Color(0xFF78716C),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  address.isEmpty ? 'Address not available' : address,
                  style: AppTypography.inter(
                    fontSize: 12.5,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                    color: const Color(0xFF78716C),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrackingCard extends StatelessWidget {
  const _TrackingCard({required this.order});
  final AdminOrder order;

  @override
  Widget build(BuildContext context) {
    return _SummaryCard(
      title: 'Track Order Status',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [OrderTrackingProgress(order: order)],
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
          _RowLine(
            label: order.isPickup ? 'Pickup charge' : 'Delivery Charge',
            value: order.formattedShipping,
          ),
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
          if (order.paymentReference.isNotEmpty)
            _RowLine(label: 'PayFast ref', value: order.paymentReference),
          if (order.resolvedPayfastPaymentId.isNotEmpty)
            _RowLine(
              label: 'PayFast txn ID',
              value: order.resolvedPayfastPaymentId,
            ),
          _RowLine(label: 'Order Status', value: order.orderStatus.label),
          if (order.paymentStatus != PaymentStatus.paid)
            _RowLine(label: 'Payment Status', value: order.paymentStatus.label),
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

class _ReplacementReturnBanner extends StatelessWidget {
  const _ReplacementReturnBanner({
    required this.order,
    required this.request,
    required this.onOpenTracking,
  });

  final AdminOrder order;
  final OrderRequest? request;
  final Future<void> Function(String url) onOpenTracking;

  @override
  Widget build(BuildContext context) {
    final status = request?.status;
    final returnInfo = request?.returnInfo;
    final statusLabel = resolvedReplacementStatusLabel(
      order: order,
      request: request,
    );
    final statusTone = resolvedReplacementStatusTone(
      order: order,
      request: request,
    );
    final title = statusLabel ?? _title(status, returnInfo);
    final body = _body(status, returnInfo);
    final trackingUrl = returnInfo?.trackingUrl.trim() ?? '';
    final waybill = returnInfo?.waybill.trim() ?? '';
    final toneColor = replacementStatusToneColor(statusTone);

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
              Icon(Icons.sync_problem_outlined, size: 18, color: toneColor),
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
          const SizedBox(height: 8),
          Text(
            body,
            style: AppTypography.inter(
              fontSize: 12,
              height: 1.45,
              color: const Color(0xFF7C2D12),
            ),
          ),
          if (request?.affectedItems.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(
              'Items: ${formatAffectedItemsSummary(request!.affectedItems, currency: order.currency)}',
              style: AppTypography.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: toneColor,
              ),
            ),
          ],
          if (order.isPickup &&
              (status == OrderRequestStatus.awaitingReturn ||
                  status == OrderRequestStatus.approved ||
                  order.needsUserReturn)) ...[
            const SizedBox(height: 10),
            PickupWarehouseReturnCard(order: order, compact: true),
          ],
          if (waybill.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Return waybill: $waybill',
              style: AppTypography.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: toneColor,
              ),
            ),
          ],
          if (trackingUrl.isNotEmpty && !order.isPickup) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => onOpenTracking(trackingUrl),
              child: Text(
                'Track return collection',
                style: AppTypography.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: toneColor,
                ).copyWith(decoration: TextDecoration.underline),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _title(OrderRequestStatus? status, ReplacementReturnInfo? info) {
    if (status == OrderRequestStatus.requested) {
      return 'Replacement request submitted';
    }
    if (info?.isReturnReceived == true ||
        status == OrderRequestStatus.returnReceived) {
      return 'Return received';
    }
    if ((info?.waybill.isNotEmpty ?? false) ||
        info?.status.toUpperCase() == 'RETURN_BOOKED') {
      return 'Return collection booked';
    }
    if (status == OrderRequestStatus.awaitingReturn ||
        status == OrderRequestStatus.approved ||
        order.hasOpenReplacement) {
      return order.isPickup
          ? 'Please return the damaged item'
          : 'Return of damaged item required';
    }
    return 'Replacement in progress';
  }

  String _body(OrderRequestStatus? status, ReplacementReturnInfo? info) {
    final rs = order.replacementState.toUpperCase().trim();
    if (rs == 'COMPLETED') {
      return 'Thanks — we have received the damaged item. Your replacement is being prepared.';
    }
    if (rs == 'REQUESTED') {
      return 'We are reviewing your replacement request. You will be notified once it is approved.';
    }
    if (rs == 'IN_PROGRESS' && !order.isPickup) {
      return 'A courier will collect the damaged item from your delivery address. Please keep the parcel ready.';
    }
    if (status == OrderRequestStatus.requested) {
      return 'We are reviewing your request${request?.requestNumber.isNotEmpty == true ? ' (${request!.requestNumber})' : ''}. '
          'You will be notified once it is approved.';
    }
    if (info?.isReturnReceived == true ||
        status == OrderRequestStatus.returnReceived) {
      return 'Thanks — we have received the damaged item. Your replacement is being prepared.';
    }
    final instructions = info?.instructions.trim() ?? '';
    if (instructions.isNotEmpty) return instructions;
    if (order.isPickup) {
      final loc = order.pickupLocation;
      final name = loc?.company.trim().isNotEmpty == true
          ? loc!.company
          : 'the warehouse';
      final addr = [
        if (loc?.enteredAddress.trim().isNotEmpty == true)
          loc!.enteredAddress
        else ...[
          loc?.streetAddress,
          loc?.localArea,
          loc?.city,
          loc?.postalCode,
        ],
      ].whereType<String>().where((s) => s.trim().isNotEmpty).join(', ');
      return [
        'Bring the damaged item to $name to complete your replacement.',
        if (addr.isNotEmpty) 'Address: $addr',
        if (loc?.hours.trim().isNotEmpty == true) 'Hours: ${loc!.hours}',
        'Bring your order number and a valid ID.',
      ].join(' ');
    }
    if ((info?.waybill.isNotEmpty ?? false)) {
      return 'A courier will collect the damaged item from your delivery address. Please keep the parcel ready.';
    }
    return 'Once approved, please return the damaged item so we can send your replacement. '
        'For delivery orders a courier collection will be arranged; for pickup, return it to the warehouse.';
  }
}

class _ActionSection extends StatelessWidget {
  const _ActionSection({
    required this.order,
    required this.controller,
    required this.onRefresh,
    this.replacementRequest,
    this.refundRequest,
  });

  final AdminOrder order;
  final UserOrdersController controller;
  final VoidCallback onRefresh;
  final OrderRequest? replacementRequest;
  final OrderRequest? refundRequest;

  @override
  Widget build(BuildContext context) {
    final canCancel =
        order.orderStatus.canUserCancel ||
        (order.orderStatus == OrderStatus.unknown &&
            !order.orderStatus.isShippedOrBeyond);
    final canConfirm = order.canUserConfirmFulfillment;
    final canReturn = kOrderReturnReplaceEnabled && order.needsUserReturn;
    final canReplace = canUserRequestReturnOrReplace(
      order,
      refundRequest: refundRequest,
    );

    if (!canCancel && !canConfirm && !canReplace && !canReturn) {
      return const SizedBox.shrink();
    }

    return Obx(() {
      final loading = controller.isMutating;
      return Column(
        children: [
          if (canReturn)
            _ActionButton(
              label: 'How to return',
              icon: Icons.inventory_2_outlined,
              loading: loading,
              onTap: () {
                ReturnInstructionsSheet.show(
                  context,
                  order: order,
                  request: replacementRequest,
                );
              },
            ),
          if (canConfirm)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: SizedBox(
                height: 44,
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: loading
                      ? null
                      : () async {
                          final result =
                              await OrderFulfillmentFeedbackSheet.show(
                                context,
                                isPickup: order.isPickup,
                              );
                          if (result == null) return;
                          final ok = await controller.confirmDelivery(
                            order.id,
                            satisfied: result.satisfied,
                            feedback: result.feedback,
                          );
                          if (ok) onRefresh();
                        },
                  icon: loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.rate_review_outlined, size: 17),
                  label: const Text('Feedback'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF088B56),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          if (canReplace)
            _ActionButton(
              label: 'Return or replace',
              icon: Icons.undo_rounded,
              loading: loading,
              onTap: () {
                ReturnOrReplaceSheet.show(
                  context,
                  order: order,
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
                      fillColor: Color(0xFFFCF7EF),
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
                    textColor: Color(0xFFFCF7EF),
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
        color: Color(0xFFFCF7EF).withValues(alpha: 0.72),
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
              child: Icon(icon, size: 14, color: Color(0xFFFCF7EF)),
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

class _CompactOrderLine extends StatelessWidget {
  const _CompactOrderLine({required this.item, this.statusTag});

  final OrderLineItem item;
  final ({String label, Color color})? statusTag;

  @override
  Widget build(BuildContext context) {
    final title = item.title.trim().isEmpty ? 'Puja Kit' : item.title.trim();
    final imageUrl = item.image.trim();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFE8DFC8),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3E2723).withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFFAF6EE),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFECE4D0),
                ),
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
          const SizedBox(width: 12),
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
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                    color: const Color(0xFF1C1917),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3ECE0),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Qty: ${item.qty}',
                        style: AppTypography.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF5D4E37),
                        ),
                      ),
                    ),
                    if (statusTag != null) ...[
                      const SizedBox(width: 8),
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
      color: Color(0xFFFFF7E8),
      child: Image.asset('assets/images/default_img.png', fit: BoxFit.cover),
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
