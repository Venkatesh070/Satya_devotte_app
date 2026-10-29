import 'package:flutter/material.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/shared/widgets/custom_button.dart';

/// Displays a confirmation dialog informing the user that they are navigating
/// outside of the Sathya app to an external destination URL (e.g. donation website).
class LeavingAppDialog extends StatelessWidget {
  const LeavingAppDialog({
    super.key,
    this.targetUrl,
    this.title = 'Support Sathya',
    this.subtitle =
        'You will be directed to the official Sathya website to complete your donation.',
    this.continueLabel = 'Proceeed to Donate',
    this.cancelLabel = 'Maybe Later',
  });

  final String? targetUrl;
  final String title;
  final String subtitle;
  final String continueLabel;
  final String cancelLabel;

  /// Shows the dialog and returns `true` if the user clicked continue, `false` otherwise.
  static Future<bool?> show(
    BuildContext context, {
    String? targetUrl,
    String title = 'Support Sathya',
    String subtitle =
        'You will be directed to the official Sathya website to complete your donation.',
    String continueLabel = 'Proceed to Donate',
    String cancelLabel = 'Maybe Later',
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => LeavingAppDialog(
        targetUrl: targetUrl,
        title: title,
        subtitle: subtitle,
        continueLabel: continueLabel,
        cancelLabel: cancelLabel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFFEF9F3),
      surfaceTintColor: Colors.transparent,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // App Logo
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFFCF7EF),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7A4E12).withValues(alpha: 0.10),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFEADBC8), width: 1),
                ),
                padding: const EdgeInsets.all(10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/images/appLogo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.volunteer_activism_rounded,
                      color: Color(0xFFED5A00),
                      size: 28,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.lora(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2C1810),
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),

              // Subtitle
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: AppTypography.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF57534E),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // Continue Button
              CustomButton(
                label: continueLabel,
                borderRadius: 14,
                textColor: const Color(0xFFFCF7EF),
                gradientColors: const [
                  AppColors.gradientStart,
                  AppColors.gradientEnd,
                ],
                onTap: () => Navigator.of(context).pop(true),
              ),
              const SizedBox(height: 8),

              // Cancel Button
              SizedBox(
                width: double.infinity,
                height: 44,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF57534E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    cancelLabel,
                    style: AppTypography.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF57534E),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
