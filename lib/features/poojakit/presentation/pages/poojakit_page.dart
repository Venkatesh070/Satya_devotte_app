import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/features/cms/models/product_model.dart';
import 'package:satya_devotte_app/features/poojakit/state/poojakit_controller.dart';
import 'package:satya_devotte_app/features/poojakit/state/cart_controller.dart';

class PoojaKitPage extends GetView<PoojaKitController> {
  const PoojaKitPage({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final cartCtrl = Get.find<CartController>();

    return Scaffold(
      backgroundColor: const Color(0xFFFAECD2),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading && controller.products.isEmpty) {
            return const SizedBox.shrink();
          }

          if (controller.error != null && controller.products.isEmpty) {
            return _ShopScaffold(
              cartController: cartCtrl,
              onBack: onBack,
              child: _StateMessage(
                icon: Icons.error_outline,
                title: 'Error loading products',
                actionLabel: 'Retry',
                onAction: () => controller.fetchProducts(refresh: true),
              ),
            );
          }

          if (controller.products.isEmpty) {
            return _ShopScaffold(
              cartController: cartCtrl,
              onBack: onBack,
              child: Image.asset(
                'assets/images/default_img.png',
                fit: BoxFit.cover,
              ),
            );
          }

          return _ShopScaffold(
            cartController: cartCtrl,
            onBack: onBack,
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => controller.fetchProducts(refresh: true),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 118),
                itemCount:
                    controller.products.length + (controller.isLoading ? 1 : 0),
                separatorBuilder: (_, _) => const Divider(
                  height: 22,
                  thickness: 0.7,
                  color: Color(0x1A6B4A2B),
                ),
                itemBuilder: (context, index) {
                  if (index >= controller.products.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 18),
                      child: Center(
                        child: _GradientSpinner(size: 24),
                      ),
                    );
                  }

                  if (index == controller.products.length - 1) {
                    controller.loadNextPage();
                  }

                  final product = controller.products[index];
                  return _ProductListTile(
                    product: product,
                    onTap: () => Get.toNamed(
                      AppRoutes.poojaKitDetails,
                      arguments: product,
                    ),
                    onAddToCartTap: () => cartCtrl.addToCart(product.id),
                  );
                },
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ShopScaffold extends StatelessWidget {
  const _ShopScaffold({
    required this.cartController,
    required this.child,
    this.onBack,
  });

  final CartController cartController;
  final Widget child;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: SizedBox(
            height: 46,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: _CircleIconButton(
                    icon: Icons.arrow_back,
                    onTap: onBack ?? () => Get.back(),
                  ),
                ),
                Text(
                  'Shop',
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
        ),
        Expanded(child: child),
      ],
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

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.icon,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 46, color: const Color(0x996B4A2B)),
          const SizedBox(height: 14),
          Text(
            title,
            style: AppTypography.inter(
              color: const Color(0xFF4A1C00),
              fontWeight: FontWeight.w700,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: onAction,
              child: Text(
                actionLabel!,
                style: AppTypography.inter(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProductListTile extends StatelessWidget {
  const _ProductListTile({
    required this.product,
    required this.onTap,
    required this.onAddToCartTap,
  });

  final ProductModel product;
  final VoidCallback onTap;
  final VoidCallback onAddToCartTap;

  @override
  Widget build(BuildContext context) {
    final isPujakit = product.category.toLowerCase() == 'pujakit';
    final itemCount = product.items.length;
    final description = product.description.trim().isEmpty
        ? 'Complete puja essentials.'
        : product.description.trim();

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 100,
                height: 100,
                child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: product.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => const ColoredBox(
                          color: Color(0xFFFFF7E8),
                          child: Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: _GradientSpinner(size: 18),
                            ),
                          ),
                        ),
                        errorWidget: (_, _, _) => _ProductImageFallback(),
                      )
                    : const _ProductImageFallback(),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.lora(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1C1917),
                    ),
                  ),
                  const SizedBox(height: 5),
                  if (isPujakit) ...[
                    _ProductBullet(
                      text: itemCount == 0
                          ? description
                          : '$itemCount ${itemCount == 1 ? 'item' : 'items'} required for performing the puja.',
                    ),
                    const SizedBox(height: 7),
                    _ProductBullet(text: 'Sufficient for 2 members.'),
                  ] else ...[
                    if (product.description.trim().isNotEmpty)
                      _ProductBullet(text: product.description.trim()),
                  ],
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      if (product.salePrice != null &&
                          product.salePrice! < product.price) ...[
                        Text(
                          '${product.currency} ${_formatPrice(product.price)}',
                          style: AppTypography.inter(
                            fontSize: 12,
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
                      const Spacer(),
                      if (product.inStock)
                        GestureDetector(
                          onTap: onAddToCartTap,
                          child: const Icon(
                            Icons.add_shopping_cart_outlined,
                            size: 20,
                            color: Color(0xFFE95700),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatPrice(num value) {
    if (value % 1 == 0) return value.toInt().toStringAsFixed(2);
    return value.toStringAsFixed(2);
  }
}

class _ProductBullet extends StatelessWidget {
  const _ProductBullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
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

class _ProductImageFallback extends StatelessWidget {
  const _ProductImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFF7E8),
      child: Image.asset('assets/images/default_img.png', fit: BoxFit.cover),
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
                border: Border.all(color: Color(0xFFFCF7EF), width: 1.2),
              ),
              constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Color(0xFFFCF7EF),
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

class _GradientSpinner extends StatelessWidget {
  const _GradientSpinner({this.size = 24});
  final double size;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Color(0xFF183EA4), Color(0xFFE35600)],
      ).createShader(bounds),
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFCF7EF)),
        ),
      ),
    );
  }
}
