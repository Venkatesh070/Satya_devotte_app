// lib/features/poojakit/presentation/pages/cart_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/core/utils/toast_util.dart';
import 'package:satya_devotte_app/features/poojakit/data/models/address_model.dart';
import 'package:satya_devotte_app/features/poojakit/data/models/cart_model.dart';
import 'package:satya_devotte_app/features/poojakit/state/cart_controller.dart';
import 'package:satya_devotte_app/features/poojakit/state/poojakit_checkout_controller.dart';
import 'package:satya_devotte_app/shared/widgets/chakra_loading_indicator.dart';
import 'package:satya_devotte_app/features/poojakit/presentation/pages/poojakit_page.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  String _deliveryOption = 'warehouse'; // 'warehouse' | 'door'
  String _deliveryTarget = 'overnight'; // 'overnight' (R 150) | 'oneday' (R 100)
  final TextEditingController _couponCtrl =
      TextEditingController(text: 'FIRSTDEVOTEE');
  bool _isCouponApplied = false;

  @override
  void initState() {
    super.initState();
    final c = Get.find<CartController>();
    c.fetchCart();
  }

  @override
  void dispose() {
    _couponCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<CartController>();
    final checkoutCtrl = Get.find<PoojaKitCheckoutController>();

    return Scaffold(
      backgroundColor: const Color(0xFFFAECD2),
      body: SafeArea(
        child: Column(
          children: [
            _ShopTopBar(title: 'Shopping Cart', onBack: () => Get.back()),
            Expanded(
              child: Obx(() {
                if (c.isLoading && c.cart == null) {
                  return const Center(
                    child: ChakraLoadingIndicator(size: 24, color: AppColors.primary),
                  );
                }

                final cart = c.cart;
                if (cart == null || cart.isEmpty) {
                  return const _EmptyCart();
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                  child: Column(
                    children: [
                      // ── Cart Items List ──
                      ...cart.items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _CartItemTile(item: item, controller: c),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── Delivery Options Section ──
                      Obx(
                        () => _DeliveryOptionsSection(
                          selectedOption: _deliveryOption,
                          onOptionChanged: (opt) => setState(() => _deliveryOption = opt),
                          selectedTarget: _deliveryTarget,
                          onTargetChanged: (target) => setState(() => _deliveryTarget = target),
                          address: checkoutCtrl.shippingAddress,
                          onAddressTap: () => Get.toNamed(
                            AppRoutes.poojaKitCheckout,
                            arguments: null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── Coupon Code Section ──
                      _CouponCodeSection(
                        controller: _couponCtrl,
                        isApplied: _isCouponApplied,
                        onApplyTap: () {
                          if (_couponCtrl.text.trim().isEmpty) return;
                          setState(() {
                            _isCouponApplied = !_isCouponApplied;
                          });
                          if (_isCouponApplied) {
                            ToastUtil.showSuccess('Coupon FIRSTDEVOTEE applied successfully!');
                          }
                        },
                      ),
                      const SizedBox(height: 14),

                      // ── Bill Summary Section ──
                      _BillSummarySection(
                        cart: cart,
                        isCouponApplied: _isCouponApplied,
                        deliveryOption: _deliveryOption,
                        deliveryTarget: _deliveryTarget,
                      ),
                      const SizedBox(height: 86),
                    ],
                  ),
                );
              }),
            ),

            // ── Fixed Bottom CTA Bar ──
            Obx(() {
              final cart = c.cart;
              if (cart == null || cart.isEmpty) {
                return _GradientCtaBar(
                  enabled: true,
                  label: 'Go to shopping',
                  onTap: () => Get.off(() => const PoojaKitPage()),
                );
              }
              return _GradientCtaBar(
                enabled: true,
                label: 'Proceed to Payment',
                onTap: () => _handleProceedToPayment(c, checkoutCtrl),
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _handleProceedToPayment(
    CartController cartCtrl,
    PoojaKitCheckoutController checkoutCtrl,
  ) async {
    // If door delivery selected and no address, prompt user to add address
    if (_deliveryOption == 'door' && checkoutCtrl.shippingAddress == null) {
      Get.toNamed(AppRoutes.poojaKitCheckout, arguments: null);
      return;
    }

    // Default warehouse address fallback if warehouse pickup selected
    final address = _deliveryOption == 'door'
        ? checkoutCtrl.shippingAddress!
        : const AddressModel(
            fullName: 'Warehouse Pickup',
            phone: '+27 413-434-3434',
            addressLine1: '74a00 Main Rd 12 Prosea Street',
            city: 'Durban',
            state: 'KwaZulu-Natal',
            postalCode: '4001',
            country: 'South Africa',
          );

    final init = await checkoutCtrl.initiateCartCheckout(
      shippingAddress: address,
    );
    if (init != null) {
      Get.toNamed(AppRoutes.poojaKitPayment, arguments: init);
      return;
    }

    ToastUtil.showError(checkoutCtrl.lastError ?? 'Failed to initiate order');
  }
}

// ════════════════════════════════════════════════════════════════
// CART ITEM TILE
// ════════════════════════════════════════════════════════════════
class _CartItemTile extends StatelessWidget {
  const _CartItemTile({required this.item, required this.controller});
  final CartItemModel item;
  final CartController controller;

  static String _formatPrice(num value) {
    if (value % 1 == 0) return value.toInt().toStringAsFixed(2);
    return value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final product = item.product;
    final isBusy = controller.isBusy(product.id);
    final itemCount = product.items.length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFCF7EF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E0D6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProductThumb(imageUrl: product.imageUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  style: AppTypography.lora(
                    fontSize: 15,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1C1917),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                _CartBullet(
                  text: itemCount == 0
                      ? product.description
                      : '$itemCount items required for performing the puja.',
                ),
                _CartBullet(text: 'Sufficient for 2 members.'),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${product.currency} ${_formatPrice(product.effectivePrice)}',
                      style: AppTypography.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFE95700),
                      ),
                    ),
                    // Quantity selector inline
                    Row(
                      children: [
                        _qtyBtn(
                          Icons.remove,
                          isBusy || item.quantity <= 1
                              ? null
                              : () => controller.updateQuantity(
                                    product.id,
                                    item.quantity - 1,
                                  ),
                        ),
                        Container(
                          width: 32,
                          alignment: Alignment.center,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 160),
                            child: isBusy
                                ? const SizedBox(
                                    key: ValueKey('busy'),
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      color: Color(0xFFE95700),
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    item.quantity.toString().padLeft(2, '0'),
                                    key: ValueKey(item.quantity),
                                    style: AppTypography.inter(
                                      color: const Color(0xFFE95700),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                          ),
                        ),
                        _qtyBtn(
                          Icons.add,
                          isBusy
                              ? null
                              : () => controller.updateQuantity(
                                    product.id,
                                    item.quantity + 1,
                                  ),
                        ),
                      ],
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

  Widget _qtyBtn(IconData icon, VoidCallback? onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7E8),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFFE8E0D6)),
          ),
          child: Icon(
            icon,
            color: onTap == null
                ? const Color(0x556C5B46)
                : const Color(0xFF1C1917),
            size: 13,
          ),
        ),
      ),
    );
  }
}

class _CartBullet extends StatelessWidget {
  const _CartBullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final value = text.trim().isEmpty ? 'Complete puja essentials.' : text;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '. ',
            style: AppTypography.inter(
              fontSize: 11,
              height: 1.25,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF78716C),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.inter(
                fontSize: 11,
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

class _ProductThumb extends StatelessWidget {
  const _ProductThumb({required this.imageUrl});
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 80,
        height: 80,
        child: imageUrl != null && imageUrl!.trim().isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                placeholder: (_, _) => const ColoredBox(
                  color: Color(0xFFFFF7E8),
                  child: Center(
                    child: ChakraLoadingIndicator(
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                errorWidget: (_, _, _) => ColoredBox(
                  color: const Color(0xFFFFF7E8),
                  child: Image.asset(
                    'assets/images/default_img.png',
                    fit: BoxFit.cover,
                  ),
                ),
              )
            : ColoredBox(
                color: const Color(0xFFFFF7E8),
                child: Image.asset(
                  'assets/images/default_img.png',
                  fit: BoxFit.cover,
                ),
              ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// DELIVERY OPTIONS SECTION
// ════════════════════════════════════════════════════════════════
class _DeliveryOptionsSection extends StatelessWidget {
  const _DeliveryOptionsSection({
    required this.selectedOption,
    required this.onOptionChanged,
    required this.selectedTarget,
    required this.onTargetChanged,
    required this.address,
    required this.onAddressTap,
  });

  final String selectedOption; // 'warehouse' | 'door'
  final ValueChanged<String> onOptionChanged;
  final String selectedTarget; // 'overnight' | 'oneday'
  final ValueChanged<String> onTargetChanged;
  final AddressModel? address;
  final VoidCallback onAddressTap;

  @override
  Widget build(BuildContext context) {
    final isWarehouse = selectedOption == 'warehouse';
    final isDoor = selectedOption == 'door';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFCF7EF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8E0D6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery Options',
            style: AppTypography.inter(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1C1917),
            ),
          ),
          const SizedBox(height: 12),

          // Option 1: Pick from Warehouse
          GestureDetector(
            onTap: () => onOptionChanged('warehouse'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isWarehouse ? const Color(0xFFFFF7E8) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isWarehouse ? const Color(0xFFE95700) : const Color(0xFFE8E0D6),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isWarehouse ? Icons.radio_button_checked : Icons.radio_button_off,
                        size: 18,
                        color: isWarehouse ? const Color(0xFFE95700) : const Color(0xFFA89F91),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Pick from Warehouse',
                        style: AppTypography.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1C1917),
                        ),
                      ),
                    ],
                  ),
                  if (isWarehouse) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(left: 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pickup Location',
                            style: AppTypography.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF6C5B46),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '74a00 Main Rd 12 Prosea Street Glenwood, Durban 4001, SOUTH AFRICA',
                            style: AppTypography.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              color: const Color(0x996C5B46),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Option 2: Door Delivery
          GestureDetector(
            onTap: () => onOptionChanged('door'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDoor ? const Color(0xFFFFF7E8) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDoor ? const Color(0xFFE95700) : const Color(0xFFE8E0D6),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isDoor ? Icons.radio_button_checked : Icons.radio_button_off,
                        size: 18,
                        color: isDoor ? const Color(0xFFE95700) : const Color(0xFFA89F91),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Door Delivery',
                        style: AppTypography.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1C1917),
                        ),
                      ),
                    ],
                  ),
                  if (isDoor) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(left: 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (address != null) ...[
                            Text(
                              [
                                address!.addressLine1,
                                address!.city,
                                address!.postalCode,
                                address!.country,
                              ].where((s) => s.trim().isNotEmpty).join(', '),
                              style: AppTypography.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF6C5B46),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          GestureDetector(
                            onTap: onAddressTap,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF183EA4),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                address == null ? '+ Add New Address' : 'Change Address',
                                style: AppTypography.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Based on your address, you are eligible for the below delivery options.',
                            style: AppTypography.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              color: const Color(0x996C5B46),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Delivery Sub-Option 1: Overnight Delivery
                          GestureDetector(
                            onTap: () => onTargetChanged('overnight'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: selectedTarget == 'overnight'
                                    ? const Color(0xFFFFF7E8)
                                    : const Color(0xFFFCF7EF),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selectedTarget == 'overnight'
                                      ? const Color(0xFFE95700)
                                      : const Color(0xFFE8E0D6),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Overnight Delivery',
                                        style: AppTypography.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF1C1917),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'R 150',
                                        style: AppTypography.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFFE95700),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Icon(
                                    selectedTarget == 'overnight'
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_off,
                                    size: 18,
                                    color: selectedTarget == 'overnight'
                                        ? const Color(0xFFE95700)
                                        : const Color(0xFFA89F91),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Delivery Sub-Option 2: One day Delivery
                          GestureDetector(
                            onTap: () => onTargetChanged('oneday'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: selectedTarget == 'oneday'
                                    ? const Color(0xFFFFF7E8)
                                    : const Color(0xFFFCF7EF),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selectedTarget == 'oneday'
                                      ? const Color(0xFFE95700)
                                      : const Color(0xFFE8E0D6),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'One day Delivery',
                                        style: AppTypography.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF1C1917),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'R 100',
                                        style: AppTypography.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFFE95700),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Icon(
                                    selectedTarget == 'oneday'
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_off,
                                    size: 18,
                                    color: selectedTarget == 'oneday'
                                        ? const Color(0xFFE95700)
                                        : const Color(0xFFA89F91),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// COUPON CODE SECTION
// ════════════════════════════════════════════════════════════════
class _CouponCodeSection extends StatelessWidget {
  const _CouponCodeSection({
    required this.controller,
    required this.isApplied,
    required this.onApplyTap,
  });

  final TextEditingController controller;
  final bool isApplied;
  final VoidCallback onApplyTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFCF7EF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8E0D6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Coupon Code',
            style: AppTypography.inter(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1C1917),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7E8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8E0D6)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    style: AppTypography.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1C1917),
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Enter coupon code',
                      hintStyle: TextStyle(fontSize: 12, color: Color(0xFFA89F91)),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onApplyTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: isApplied ? const Color(0xFF16A34A) : const Color(0xFF183EA4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isApplied) ...[
                          const Icon(Icons.check, size: 12, color: Colors.white),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          isApplied ? 'Applied' : 'Apply',
                          style: AppTypography.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Use this coupon and get additional 10% off on your purchase',
            style: AppTypography.inter(
              fontSize: 10,
              fontWeight: FontWeight.w400,
              color: const Color(0x996C5B46),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// BILL SUMMARY SECTION
// ════════════════════════════════════════════════════════════════
class _BillSummarySection extends StatelessWidget {
  const _BillSummarySection({
    required this.cart,
    required this.isCouponApplied,
    required this.deliveryOption,
    required this.deliveryTarget,
  });

  final CartModel cart;
  final bool isCouponApplied;
  final String deliveryOption;
  final String deliveryTarget;

  static String _formatPrice(num value) {
    if (value % 1 == 0) return value.toInt().toStringAsFixed(2);
    return value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = cart.items.fold<num>(0, (sum, i) => sum + i.lineTotal);
    final discount = isCouponApplied ? (subtotal * 0.10) : 0;
    final vat = 10.00;
    final deliveryCharge = deliveryOption == 'door'
        ? (deliveryTarget == 'overnight' ? 150.0 : 100.0)
        : 0.0;
    final toPay = (subtotal - discount + vat + deliveryCharge).clamp(0, double.infinity);

    Widget lineItem(String left, String right, {Color? rightColor, bool bold = false}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              left,
              style: AppTypography.inter(
                fontSize: 13,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                color: const Color(0xFF1D1B19),
              ),
            ),
            Text(
              right,
              style: AppTypography.inter(
                fontSize: 13,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: rightColor ?? const Color(0xFF1D1B19),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFCF7EF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8E0D6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bill Summary',
            style: AppTypography.inter(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1C1917),
            ),
          ),
          const SizedBox(height: 12),
          ...cart.items.map(
            (item) => lineItem(
              '${item.product.title} x${item.quantity}',
              '${cart.currency} ${_formatPrice(item.lineTotal)}',
            ),
          ),
          lineItem(
            'Delivery charges',
            '${cart.currency} ${_formatPrice(deliveryCharge)}',
          ),
          if (isCouponApplied)
            lineItem(
              'Discount',
              '- ${cart.currency} ${_formatPrice(discount)}',
              rightColor: const Color(0xFFDC2626),
            ),
          lineItem('VAT', '${cart.currency} ${_formatPrice(vat)}'),
          const Divider(height: 20, color: Color(0x1A6B4A2B)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'To pay',
                    style: AppTypography.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1C1917),
                    ),
                  ),
                  Text(
                    '(Includes all taxes and charges)',
                    style: AppTypography.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w400,
                      color: const Color(0x996C5B46),
                    ),
                  ),
                ],
              ),
              Text(
                '${cart.currency} ${_formatPrice(toPay)}',
                style: AppTypography.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1C1917),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// SHARED UI HELPERS
// ════════════════════════════════════════════════════════════════
class _ShopTopBar extends StatelessWidget {
  const _ShopTopBar({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: SizedBox(
        height: 46,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: _CircleIconButton(icon: Icons.arrow_back, onTap: onBack),
            ),
            Text(
              title,
              style: AppTypography.inter(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1D160E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFCF7EF),
      shape: const CircleBorder(),
      elevation: 5,
      shadowColor: const Color(0x22000000),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(Icons.arrow_back, size: 19, color: Color(0xFF1C1C1C)),
        ),
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 70,
            color: AppColors.textColor.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 14),
          Text(
            'Your cart is empty',
            style: AppTypography.lora(
              fontSize: 16,
              color: AppColors.textColor.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientCtaBar extends StatelessWidget {
  const _GradientCtaBar({
    required this.label,
    required this.onTap,
    required this.enabled,
  });

  final String label;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
        child: GestureDetector(
          onTap: enabled ? onTap : null,
          child: Container(
            height: 48,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: enabled
                  ? const LinearGradient(
                      colors: [AppColors.gradientStart, AppColors.gradientEnd],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    )
                  : const LinearGradient(
                      colors: [Color(0xFFB8B1AA), Color(0xFFB8B1AA)],
                    ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: AppTypography.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: const Color(0xFFFCF7EF),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
