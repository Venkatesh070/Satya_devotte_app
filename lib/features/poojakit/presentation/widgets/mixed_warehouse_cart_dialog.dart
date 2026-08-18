import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/features/poojakit/domain/warehouse_cart_rules.dart';

/// Modal when user tries to mix Ayurvedic with Books/Puja Kits in one cart.
class MixedWarehouseCartDialog {
  MixedWarehouseCartDialog._();

  static Future<void> show({
    required String message,
    WarehouseShippingGroup? cartGroup,
  }) async {
    final ctx = Get.context;
    if (ctx == null) return;

    final title = mixedWarehouseCartDialogTitle(cartGroup);

    await showDialog<void>(
      context: ctx,
      barrierDismissible: true,
      builder: (dialogCtx) {
        return Dialog(
          backgroundColor: const Color(0xFFFCF7EF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.shopping_cart_outlined,
                      color: Color(0xFFED5A00),
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: AppTypography.lora(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1C1917),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  message,
                  style: AppTypography.inter(
                    fontSize: 14,
                    height: 1.45,
                    color: const Color(0xFF44403C),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Checkout one category at a time, or open your cart and remove items to switch.',
                  style: AppTypography.inter(
                    fontSize: 12.5,
                    height: 1.4,
                    color: const Color(0xFF78716C),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(dialogCtx).pop();
                          Get.toNamed(AppRoutes.poojaKitCart);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF4A1C00),
                          side: const BorderSide(color: Color(0xFFD6C4A8)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('View cart'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(dialogCtx).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFED5A00),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('OK'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
