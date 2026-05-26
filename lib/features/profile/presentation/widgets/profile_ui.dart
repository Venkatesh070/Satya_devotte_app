import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/features/donations/presentation/widgets/donation_ui.dart';
import 'package:satya_devotte_app/shared/widgets/custom_button.dart';

/// Blue → orange gradient used on Figma action buttons.
const kFigmaActionGradient = [AppColors.gradientStart, AppColors.gradientEnd];

class ProfileLinkTile extends StatelessWidget {
  const ProfileLinkTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: const Color(0xFFFFFCF6),
        borderRadius: BorderRadius.circular(14),
        elevation: 5,
        shadowColor: const Color(0x1A7A4E12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            constraints: const BoxConstraints(minHeight: 58),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFF2E6D1)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF2DC),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: isDestructive
                        ? const Color(0xFFB45026)
                        : const Color(0xFFC28335),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1C1917),
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: const Color(0xFF78716C),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProfileSectionHeading extends StatelessWidget {
  const ProfileSectionHeading(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: AppTypography.lora(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color(0XFF1C1917),
        ),
      ),
    );
  }
}

/// Logout bottom sheet — Figma modal with gradient button.
Future<void> showProfileLogoutSheet({
  required Future<void> Function() onConfirm,
}) {
  return Get.bottomSheet<void>(
    _ProfileConfirmSheet(
      title: 'Logout',
      message: 'Are you sure you want to logout of the app?',
      confirmLabel: 'Logout',
      onConfirm: () async {
        Get.back();
        await onConfirm();
      },
    ),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}

/// Delete account bottom sheet — Figma modal with text field + gradient button.
Future<void> showProfileDeleteAccountSheet({
  required String userName,
  required Future<void> Function(String comment) onConfirm,
}) {
  return Get.bottomSheet<void>(
    _DeleteAccountSheet(userName: userName, onConfirm: onConfirm),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}

class _ProfileConfirmSheet extends StatelessWidget {
  const _ProfileConfirmSheet({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.onConfirm,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      decoration: const BoxDecoration(
        color: Color(0xFFFEF9F3),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: DonationUi.cardBorder,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  style: AppTypography.lora(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: DonationUi.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: AppTypography.inter(
                    fontSize: 14,
                    height: 1.5,
                    color: DonationUi.textMuted,
                  ),
                ),
                const SizedBox(height: 32),
                CustomButton(
                  label: confirmLabel,
                  textColor: Colors.white,
                  gradientColors: kFigmaActionGradient,
                  borderRadius: 14,
                  onTap: onConfirm,
                ),
              ],
            ),
            Positioned(
              right: 0,
              top: 10,
              child: GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF3E5D0),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 18,
                    color: Color(0xFF3B1E08),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeleteAccountSheet extends StatefulWidget {
  const _DeleteAccountSheet({required this.userName, required this.onConfirm});

  final String userName;
  final Future<void> Function(String comment) onConfirm;

  @override
  State<_DeleteAccountSheet> createState() => _DeleteAccountSheetState();
}

class _DeleteAccountSheetState extends State<_DeleteAccountSheet> {
  final _ctrl = TextEditingController();
  bool _canDelete = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      final ok = _ctrl.text.trim().isNotEmpty;
      if (ok != _canDelete) setState(() => _canDelete = ok);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      decoration: const BoxDecoration(
        color: Color(0xFFFEF9F3),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: DonationUi.cardBorder,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Delete Account',
                  style: AppTypography.lora(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: DonationUi.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Hey ${widget.userName}, Are you sure you want to delete your account?',
                  style: AppTypography.inter(
                    fontSize: 14,
                    height: 1.5,
                    color: DonationUi.textMuted,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _ctrl,
                  style: AppTypography.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: DonationUi.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter your reason for deletion',
                    hintStyle: AppTypography.inter(
                      fontSize: 14,
                      color: DonationUi.textMuted.withValues(alpha: 0.5),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: DonationUi.cardBorder,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: DonationUi.cardBorder,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFED5A00)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                CustomButton(
                  label: 'Yes, Delete',
                  textColor: Colors.white,
                  gradientColors: kFigmaActionGradient,
                  borderRadius: 14,
                  enabled: _canDelete,
                  onTap: () async {
                    final comment = _ctrl.text.trim();
                    if (comment.isEmpty) return;
                    Get.back();
                    await widget.onConfirm(comment);
                  },
                ),
              ],
            ),
            Positioned(
              right: 0,
              top: 10,
              child: GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF3E5D0),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 18,
                    color: Color(0xFF3B1E08),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
