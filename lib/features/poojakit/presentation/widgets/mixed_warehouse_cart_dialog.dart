import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/features/poojakit/domain/warehouse_cart_rules.dart';

/// Modal when user tries to mix Ayurvedic with Books/Puja Kits in one cart.
class MixedWarehouseCartDialog {
  MixedWarehouseCartDialog._();

  static Future<void> show({
    required String message,
    WarehouseShippingGroup? cartGroup,
    Future<void> Function()? onClearAndProceed,
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
            side: const BorderSide(color: Color(0xFFE8E0D6)),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header with Icon, Title, and Close (X) button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0x1FED5A00),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.store_mall_directory_outlined,
                        color: Color(0xFFED5A00),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: AppTypography.lora(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1C1917),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(dialogCtx).pop(),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0x124A1C00),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 18,
                          color: Color(0xFF5D4037),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Message content
                Text(
                  message,
                  style: AppTypography.inter(
                    fontSize: 13.5,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF44403C),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  mixedWarehouseDiscardPrompt(cartGroup),
                  style: AppTypography.inter(
                    fontSize: 12,
                    height: 1.4,
                    color: const Color(0xFF78716C),
                  ),
                ),
                const SizedBox(height: 22),
                // Vertical Action Buttons
                GestureDetector(
                  onTap: () async {
                    Navigator.of(dialogCtx).pop();
                    if (onClearAndProceed != null) {
                      await onClearAndProceed();
                    }
                  },
                  child: Container(
                    height: 46,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.gradientStart,
                          AppColors.gradientEnd,
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x28000000),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Clear Cart & Proceed',
                      style: AppTypography.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFCF7EF),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    Navigator.of(dialogCtx).pop();
                    Get.toNamed(AppRoutes.poojaKitCart);
                  },
                  child: Container(
                    height: 46,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCF7EF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFD6C4A8),
                        width: 1.2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'View Cart',
                      style: AppTypography.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF4A1C00),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
