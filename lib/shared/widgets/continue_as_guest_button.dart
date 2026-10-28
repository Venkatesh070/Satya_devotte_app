import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/features/auth/presentation/controllers/auth_controller.dart';

/// A centered, prominently clickable button for continuing as a guest.
/// Designed with a tactile pill container, visible border, subtle elevation,
/// devotee person icon, and directional chevron to ensure devotees immediately
/// recognize it as an interactive call-to-action.
class ContinueAsGuestButton extends StatelessWidget {
  const ContinueAsGuestButton({
    super.key,
    this.enabled = true,
    this.onTap,
  });

  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: const Color(0xFFFCF7EF),
        borderRadius: BorderRadius.circular(22),
        elevation: 1.5,
        shadowColor: const Color(0x2A4A1C00),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: enabled
              ? () async {
                  if (onTap != null) {
                    onTap!();
                  } else if (Get.isRegistered<AuthController>()) {
                    await Get.find<AuthController>().continueAsGuest();
                  } else {
                    Get.offAllNamed(AppRoutes.home);
                  }
                }
              : null,
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: const Color(0xFFE0D6C2),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.person_outline_rounded,
                  size: 19,
                  color: Color(0xFF4A1C00),
                ),
                const SizedBox(width: 8),
                Text(
                  'Continue as Guest',
                  style: AppTypography.inter(
                    color: const Color(0xFF4A1C00),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: Color(0xFF4A1C00),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
