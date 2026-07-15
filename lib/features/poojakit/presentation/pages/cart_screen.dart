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
  @override
  void initState() {
    super.initState();
    final c = Get.find<CartController>();
    c.fetchCart();
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<CartController>();
    final checkoutCtrl = Get.find<PoojaKitCheckoutController>();

    return Scaffold(
      backgroundColor: AppColors.appBgColor,
      body: SafeArea(
        child: Column(
          children: [
            _ShopTopBar(title: 'Shopping Cart', onBack: () => Get.back()),
            Expanded(
              child: Obx(() {
                if (c.isLoading && c.cart == null) {
                  return const SizedBox.shrink();
                }

                final cart = c.cart;
                if (cart == null || cart.isEmpty) {
                  return const _EmptyCart();
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                  child: Column(
                    children: [
                      ...cart.items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _CartItemTile(item: item, controller: c),
                        ),
                      ),
                      const Divider(
                        height: 26,
                        thickness: 0.7,
                        color: Color(0x1A6B4A2B),
                      ),
                      Obx(
                        () => _DeliveryLocationSection(
                          address: checkoutCtrl.shippingAddress,
                          onChangeTap: () => Get.toNamed(
                            AppRoutes.poojaKitCheckout,
                            arguments: null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _BillSummarySection(cart: cart),
                      const SizedBox(height: 86),
                    ],
                  ),
                );
              }),
            ),
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
    final address = checkoutCtrl.shippingAddress;
    if (address == null) {
      Get.toNamed(AppRoutes.poojaKitCheckout, arguments: null);
      return;
    }

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

class _CartItemTile extends StatelessWidget {
  const _CartItemTile({required this.item, required this.controller});
  final CartItemModel item;
  final CartController controller;

  @override
  Widget build(BuildContext context) {
    final product = item.product;
    final isBusy = controller.isBusy(product.id);

    final itemCount = product.items.length;
    return Column(
      children: [
        Row(
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
                      fontSize: 16,
                      height: 1.25,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1C1917),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  _CartBullet(
                    text: itemCount == 0
                        ? product.description
                        : '$itemCount items required for performing the puja.',
                  ),
                  _CartBullet(text: 'Sufficient for 2 members.'),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      if (product.salePrice != null &&
                          product.salePrice! < product.price) ...[
                        Text(
                          '${product.currency} ${_formatPrice(product.price)}',
                          style: AppTypography.inter(
                            fontSize: 10,
                            color: const Color(0x8A6C5B46),
                            decoration: TextDecoration.lineThrough,
                            decorationColor: const Color(0x8A6C5B46),
                          ),
                        ),
                        const SizedBox(width: 5),
                      ],
                      Text(
                        '${product.currency} ${_formatPrice(product.effectivePrice)}',
                        style: AppTypography.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFDC5B0A),
                        ),
                      ),
                    ],
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
            _qtyBtn(
              Icons.remove,
              isBusy
                  ? null
                  : () => controller.updateQuantity(
                      product.id,
                      item.quantity - 1,
                    ),
            ),
            Container(
              width: 42,
              alignment: Alignment.center,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                child: isBusy
                    ? const SizedBox(
                        key: ValueKey('busy'),
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          color: Color(0xFFDC5B0A),
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        item.quantity.toString().padLeft(2, '0'),
                        key: ValueKey(item.quantity),
                        style: AppTypography.inter(
                          color: const Color(0xFFDC5B0A),
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
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
    );
  }

  static String _formatPrice(num value) {
    if (value % 1 == 0) return value.toInt().toStringAsFixed(2);
    return value.toStringAsFixed(2);
  }

  Widget _qtyBtn(IconData icon, VoidCallback? onTap) {
    return Material(
      color: Color(0xFFFCF7EF),
      borderRadius: BorderRadius.circular(2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(2),
        child: SizedBox(
          width: 28,
          height: 28,
          child: Icon(
            icon,
            color: onTap == null
                ? AppColors.textColor.withValues(alpha: 0.35)
                : AppColors.textColor,
            size: 15,
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
              fontSize: 12,
              height: 1.25,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF78716C),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.inter(
                fontSize: 12,
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
        width: 100,
        height: 100,
        child: imageUrl != null && imageUrl!.trim().isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                placeholder: (_, _) => const ColoredBox(
                  color: Color(0xFFFFF7E8),
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: ChakraLoadingIndicator(
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                errorWidget: (_, _, _) => ColoredBox(
                  color: Color(0xFFFFF7E8),
                  child: Image.asset(
                    'assets/images/default_img.png',
                    fit: BoxFit.cover,
                  ),
                ),
              )
            : ColoredBox(
                color: Color(0xFFFFF7E8),
                child: Image.asset(
                  'assets/images/default_img.png',
                  fit: BoxFit.cover,
                ),
              ),
      ),
    );
  }
}

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
      color: Color(0xFFFCF7EF),
      shape: const CircleBorder(),
      elevation: 5,
      shadowColor: const Color(0x22000000),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 19, color: const Color(0xFF1C1C1C)),
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

class _DeliveryLocationSection extends StatelessWidget {
  const _DeliveryLocationSection({
    required this.onChangeTap,
    required this.address,
  });

  final VoidCallback onChangeTap;
  final AddressModel? address;

  @override
  Widget build(BuildContext context) {
    final savedAddress = address;
    final addressText = savedAddress == null
        ? 'No location set'
        : [
            savedAddress.addressLine1,
            savedAddress.city,
            savedAddress.postalCode,
            savedAddress.country,
          ].where((e) => e.trim().isNotEmpty).join(', ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Color(0xFFFCF7EF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8E0D6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery Location',
            style: AppTypography.lora(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1C1917),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7E8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8E0D6)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF183EA4), Color(0xFFE35600)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ).createShader(bounds),
                  blendMode: BlendMode.srcIn,
                  child: Icon(
                    Icons.location_on_outlined,
                    size: 18,
                    color: Color(0xFF6C5B46),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    addressText,
                    style: AppTypography.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF6C5B46),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.center,
            child: OutlinedButton(
              onPressed: onChangeTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFE95700),
                side: const BorderSide(color: Color(0xFFE95700)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
              ),
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF183EA4), Color(0xFFE35600)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ).createShader(bounds),
                blendMode: BlendMode.srcIn,
                child: Text(
                  address == null
                      ? 'Set Delivery Location'
                      : 'Change Delivery Location',
                  style: AppTypography.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BillSummarySection extends StatelessWidget {
  const _BillSummarySection({required this.cart});
  final CartModel cart;

  static String _formatPrice(num value) {
    if (value % 1 == 0) return value.toInt().toStringAsFixed(2);
    return value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = cart.subtotal ?? cart.totalAmount;
    final delivery = cart.deliveryCharge ?? 0;
    final toPay = cart.totalAmount;
    debugPrint('Cart Model - subtotal: ${cart.subtotal}, deliveryCharge: ${cart.deliveryCharge}, totalAmount: ${cart.totalAmount}');

    Widget row(String left, String right, {bool bold = false}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              left,
              style: AppTypography.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF1D1B19),
              ),
            ),
            Text(
              right,
              style: AppTypography.inter(
                fontSize: 14,
                fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
                color: const Color(0xFF1D1B19),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Color(0xFFFCF7EF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8E0D6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bill Summary',
            style: AppTypography.lora(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1C1917),
            ),
          ),
          const SizedBox(height: 12),
          row('Subtotal', '${cart.currency} ${_formatPrice(subtotal)}'),
          row('Delivery charge', '${cart.currency} ${_formatPrice(delivery)}'),
          const Divider(height: 16, color: Color(0x1A6B4A2B)),
          row('To pay', '${cart.currency} ${_formatPrice(toPay)}', bold: true),
          Text(
            'Inclusive of all taxes and charges',
            style: AppTypography.inter(
              fontSize: 8,
              fontWeight: FontWeight.w400,
              color: Color(0XFF1D1B19),
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
                color: Color(0xFFFCF7EF),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
