import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/features/poojakit/state/poojakit_controller.dart';
import 'package:satya_devotte_app/shared/widgets/app_background.dart';
import 'package:satya_devotte_app/shared/widgets/product_card.dart';

class PoojaKitPage extends GetView<PoojaKitController> {
  const PoojaKitPage({super.key});

  Widget _buildSearchField() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0x22FFFFFF),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              onChanged: (v) => controller.setSearchQuery(v),
              cursorColor: Colors.black,
              style: AppTypography.inter(
                fontSize: 14,
                color: const Color(0xFF232323),
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'Search pooja kits...',
                hintStyle: AppTypography.inter(
                  fontSize: 14,
                  color: const Color(0xFFFFFFFF),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: Column(
          children: [
            // Header
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Puja Kit Store',
                      style: AppTypography.lora(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSearchField(),
                  ],
                ),
              ),
            ),

            Expanded(
              child: Obx(() {
                if (controller.isLoading && controller.products.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }

                if (controller.error != null && controller.products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.white70,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading products',
                          style: AppTypography.inter(color: Colors.white),
                        ),
                        TextButton(
                          onPressed: () =>
                              controller.fetchProducts(refresh: true),
                          child: const Text(
                            'Retry',
                            style: TextStyle(color: Color(0xFFFFD180)),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (controller.products.isEmpty) {
                  return Center(
                    child: Text(
                      'No products available',
                      style: AppTypography.inter(color: Colors.white70),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => controller.fetchProducts(refresh: true),
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.58,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                    itemCount: controller.products.length,
                    itemBuilder: (context, index) {
                      // Trigger next page load
                      if (index == controller.products.length - 1) {
                        controller.loadNextPage();
                      }

                      final product = controller.products[index];
                      return _GridProductCard(product: product);
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

class _GridProductCard extends StatelessWidget {
  const _GridProductCard({required this.product});
  final dynamic product;

  @override
  Widget build(BuildContext context) {
    return ProductCard(
      product: product,
      onTap: () => Get.toNamed(AppRoutes.poojaKitDetails, arguments: product),
      onDonateTap: () =>
          Get.toNamed(AppRoutes.poojaKitCheckout, arguments: product),
    );
  }
}
