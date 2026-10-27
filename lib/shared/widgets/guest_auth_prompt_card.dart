import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/core/presentation/get_snackbar_insets.dart';
import 'package:satya_devotte_app/core/services/offline_service.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:satya_devotte_app/features/auth/presentation/pages/email_login_page.dart';
import 'package:satya_devotte_app/shared/widgets/custom_button.dart';
import 'package:satya_devotte_app/shared/widgets/terms_and_privacy_text.dart';

/// Reusable auth prompt card used both in the guest popup dialog
/// and on the guest Profile screen.
class GuestAuthPromptCard extends StatelessWidget {
  const GuestAuthPromptCard({
    super.key,
    required this.title,
    this.showCloseButton = false,
    this.onClose,
    this.onSuccess,
    this.isCard = false,
    this.padding,
    this.backgroundColor = Colors.white,
  });

  final String title;
  final bool showCloseButton;
  final VoidCallback? onClose;
  final VoidCallback? onSuccess;
  final bool isCard;
  final EdgeInsetsGeometry? padding;
  final Color backgroundColor;

  AuthController get _controller => Get.find<AuthController>();

  void _handleSuccess(BuildContext context) {
    onSuccess?.call();
    if (context.mounted && Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop(true);
    }
    _controller.navigateAfterLogin();
  }

  @override
  Widget build(BuildContext context) {
    final showApple = defaultTargetPlatform == TargetPlatform.iOS;

    final content = Obx(() {
      final isGoogleLoading = _controller.isGoogleSignInLoading;
      final isAppleLoading = _controller.isAppleSignInLoading;
      final isEmailLoading = _controller.isEmailSignInLoading;
      final isAnyLoading = isGoogleLoading || isAppleLoading || isEmailLoading;

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showCloseButton)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: onClose ??
                        () {
                          if (Navigator.of(context, rootNavigator: true).canPop()) {
                            Navigator.of(context, rootNavigator: true).pop();
                          }
                        },
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.close,
                        size: 22,
                        color: Color(0xFF1F1F1F),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.lora(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1C1917),
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(height: 20),
          _SocialButton(
            label: 'Continue with Google',
            backgroundColor: const Color(0xFFFCF7EF),
            textColor: const Color(0xFF1F1F1F),
            hasBorder: true,
            leading: SvgPicture.asset(
              'assets/svgs/google.svg',
              width: 18,
              height: 18,
            ),
            isLoading: isGoogleLoading,
            isEnabled: !isAnyLoading,
            onTap: () async {
              final offlineService = Get.find<OfflineService>();
              if (!offlineService.checkAndShowDialog()) return;

              final isSuccess = await _controller.signInWithGoogle();
              if (isSuccess && context.mounted) {
                _handleSuccess(context);
              } else if (_controller.lastAuthError != null) {
                showAppSnackbar(
                  title: 'Login Failed',
                  message: _controller.lastAuthError!,
                  isError: true,
                );
              }
            },
          ),
          if (showApple) ...[
            const SizedBox(height: 12),
            _SocialButton(
              label: 'Continue with Apple',
              backgroundColor: Colors.black,
              textColor: const Color(0xFFFCF7EF),
              leading: SvgPicture.asset(
                'assets/svgs/apple.svg',
                width: 18,
                height: 18,
                colorFilter: const ColorFilter.mode(
                  Color(0xFFFCF7EF),
                  BlendMode.srcIn,
                ),
              ),
              isLoading: isAppleLoading,
              isEnabled: !isAnyLoading,
              onTap: () async {
                final offlineService = Get.find<OfflineService>();
                if (!offlineService.checkAndShowDialog()) return;

                final isSuccess = await _controller.signInWithApple();
                if (isSuccess && context.mounted) {
                  _handleSuccess(context);
                } else if (_controller.lastAuthError != null) {
                  showAppSnackbar(
                    title: 'Login Failed',
                    message: _controller.lastAuthError!,
                    isError: true,
                  );
                }
              },
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Divider(
                  color: Colors.black.withValues(alpha: 0.12),
                  thickness: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'Or',
                  style: TextStyle(
                    color: Colors.black.withValues(alpha: 0.55),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: Divider(
                  color: Colors.black.withValues(alpha: 0.12),
                  thickness: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          CustomButton(
            label: 'Continue with Email',
            gradientColors: const [
              AppColors.gradientStart,
              AppColors.gradientEnd,
            ],
            textColor: const Color(0xFFFCF7EF),
            isLoading: isEmailLoading,
            enabled: !isAnyLoading,
            borderRadius: 14,
            onTap: () {
              final offlineService = Get.find<OfflineService>();
              if (!offlineService.checkAndShowDialog()) return;

              // If inside a dialog, dismiss the dialog before navigating to email login
              if (showCloseButton &&
                  Navigator.of(context, rootNavigator: true).canPop()) {
                Navigator.of(context, rootNavigator: true).pop();
              }
              Get.to(() => const EmailLoginPage());
            },
          ),
          const SizedBox(height: 16),
          const TermsAndPrivacyPolicyText(
            fontSize: 11.0,
            textColor: Color(0xFF57534E),
          ),
        ],
      );
    });

    if (isCard) {
      return Container(
        width: double.infinity,
        padding: padding ?? const EdgeInsets.fromLTRB(20, 24, 20, 20),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A7A4E12),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: content,
      );
    }

    return content;
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.leading,
    required this.onTap,
    this.isLoading = false,
    this.isEnabled = true,
    this.hasBorder = false,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Widget leading;
  final VoidCallback onTap;
  final bool isLoading;
  final bool isEnabled;
  final bool hasBorder;

  @override
  Widget build(BuildContext context) {
    final canTap = isEnabled && !isLoading;
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(14),
      elevation: hasBorder ? 1 : 0,
      shadowColor: Colors.black12,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: canTap ? onTap : null,
        child: Container(
          height: 48,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: hasBorder
                ? Border.all(color: Colors.black.withValues(alpha: 0.12))
                : null,
          ),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: textColor,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      leading,
                      const SizedBox(width: 12),
                      Text(
                        label,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Tracks active guest auth dialog so duplicates are not stacked
bool _isGuestAuthDialogShowing = false;

/// Displays the reusable guest auth popup dialog matching Image 1 (left side).
/// Returns `true` if the user successfully signed in, or `null`/`false` if dismissed.
Future<bool?> showGuestAuthDialog(
  BuildContext context, {
  String title = 'Please sign in or sign up to view the content',
  VoidCallback? onSuccess,
}) async {
  if (_isGuestAuthDialogShowing) return null;
  _isGuestAuthDialogShowing = true;

  try {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (dialogCtx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 28,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
            child: GuestAuthPromptCard(
              title: title,
              showCloseButton: true,
              onSuccess: onSuccess,
            ),
          ),
        );
      },
    );
  } finally {
    _isGuestAuthDialogShowing = false;
  }
}
