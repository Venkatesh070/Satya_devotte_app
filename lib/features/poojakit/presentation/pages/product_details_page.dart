// lib/features/poojakit/presentation/pages/product_details_page.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/features/cms/models/product_model.dart';
import 'package:satya_devotte_app/features/poojakit/state/cart_controller.dart';
import 'package:satya_devotte_app/shared/widgets/chakra_loading_indicator.dart';

class ProductDetailsPage extends StatefulWidget {
  const ProductDetailsPage({super.key});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  late final ProductModel _product;
  late final CartController _cartCtrl;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is ProductModel) {
      _product = args;
    } else {
      // Fallback to avoid crash if arguments are invalid
      _product = ProductModel.fromJson({});
    }
    _cartCtrl = Get.find<CartController>();
  }

  Future<void> _addToCartAndOpenCart() async {
    await _cartCtrl.addToCart(_product.id, quantity: 1);
    if (!mounted) return;
    Get.toNamed(AppRoutes.poojaKitCart);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBgColor,
      body: SafeArea(
        child: Column(
          children: [
            _ShopTopBar(
              title: '',
              onBack: () => Get.back(),
              cartController: _cartCtrl,
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                      child: Column(
                        children: [
                          _ProductHeader(product: _product),
                          if (_product.category.toLowerCase() == 'pujakit') ...[
                            const SizedBox(height: 24),
                            _KitItemsSection(items: _product.items),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
            Obx(() {
              final busy = _cartCtrl.isBusy(_product.id);
              final closed = _product.isOrderClosed;

              return _GradientCtaBar(
                enabled: _product.inStock && !busy && !closed,
                label: !_product.inStock
                    ? 'Out of stock'
                    : closed
                    ? 'Orders closed'
                    : busy
                    ? 'Adding...'
                    : 'Add to cart',
                onTap: _product.inStock && !busy && !closed
                    ? _addToCartAndOpenCart
                    : null,
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _CartBadge extends StatelessWidget {
  const _CartBadge({required this.controller});
  final CartController controller;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        _CircleIconButton(
          icon: Icons.shopping_cart_outlined,
          onTap: () async {
            await controller.fetchCart();
            if (context.mounted) {
              Get.toNamed(AppRoutes.poojaKitCart);
            }
          },
        ),
        Positioned(
          right: -1,
          top: -1,
          child: Obx(() {
            final count = controller.itemCount;
            if (count == 0) return const SizedBox.shrink();
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE95700),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 1.2),
              ),
              constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _ShopTopBar extends StatelessWidget {
  const _ShopTopBar({
    required this.title,
    required this.onBack,
    required this.cartController,
  });

  final String title;
  final VoidCallback onBack;
  final CartController cartController;

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
            Align(
              alignment: Alignment.centerRight,
              child: _CartBadge(controller: cartController),
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
      color: Colors.white,
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

class _ProductHeader extends StatelessWidget {
  const _ProductHeader({required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    final isPujakit = product.category.toLowerCase() == 'pujakit';
    final itemCount = product.items.length;
    final detailText = isPujakit
        ? (itemCount == 0
              ? product.description
              : '$itemCount items required for performing the puja.')
        : product.description;

    return Column(
      children: [
        _ProductHeroImage(imageUrl: product.imageUrl, isPujakit: isPujakit),
        const SizedBox(height: 16),
        Text(
          product.title,
          textAlign: TextAlign.center,
          style: AppTypography.lora(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1C1917),
          ),
        ),
        const SizedBox(height: 10),
        if (isPujakit) ...[
          Text(
            detailText.trim().isEmpty
                ? 'Complete puja essentials.'
                : detailText,
            textAlign: TextAlign.center,
            style: AppTypography.inter(
              fontSize: 12,
              height: 1.35,
              color: const Color(0xFF78716C),
            ),
          ),
          Text(
            product.inStock
                ? 'Sufficient for 2 members.'
                : 'Currently out of stock.',
            textAlign: TextAlign.center,
            style: AppTypography.inter(
              fontSize: 12,
              height: 1.35,
              color: const Color(0xFF78716C),
            ),
          ),
        ] else ...[
          // For non-pujakit categories
          Text(
            product.displayPrice,
            textAlign: TextAlign.center,
            style: AppTypography.lora(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          if (detailText.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              detailText,
              textAlign: TextAlign.center,
              style: AppTypography.inter(
                fontSize: 12,
                height: 1.35,
                color: const Color(0xFF78716C),
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _ProductHeroImage extends StatelessWidget {
  const _ProductHeroImage({required this.imageUrl, required this.isPujakit});
  final String? imageUrl;
  final bool isPujakit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isPujakit ? 147 : double.infinity,
      height: isPujakit ? 111 : 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 18,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: imageUrl != null && imageUrl!.trim().isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                placeholder: (context, url) => const ColoredBox(
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
                errorWidget: (context, url, error) => ColoredBox(
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

class _KitItemsSection extends StatelessWidget {
  const _KitItemsSection({required this.items});

  final List<ProductItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Puja Kit Items',
          style: AppTypography.lora(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1C1917),
          ),
        ),
        const SizedBox(height: 10),
        if (items.isEmpty)
          _KitItemPill(text: 'No items listed.')
        else
          ...items.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _KitItemPill(
                text: '${_formatQuantity(e.quantity)} x ${e.displayLabel}',
              ),
            ),
          ),
      ],
    );
  }

  String _formatQuantity(num value) {
    if (value % 1 == 0) return value.toInt().toString();
    return value.toString();
  }
}

class _KitItemPill extends StatelessWidget {
  const _KitItemPill({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        text,
        style: AppTypography.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF1C1917),
        ),
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
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
