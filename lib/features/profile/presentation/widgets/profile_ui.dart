import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/features/donations/presentation/widgets/donation_ui.dart';
import 'package:satya_devotte_app/shared/widgets/custom_button.dart';

/// Blue → orange gradient used on Figma action buttons.
const kFigmaActionGradient = [
  AppColors.gradientStart,
  AppColors.gradientEnd,
];

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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: DonationUi.cardBorder),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDestructive
                        ? const Color(0xFFFFF1F0)
                        : const Color(0xFFFAF7F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: isDestructive
                        ? const Color(0xFFB10F1A)
                        : DonationUi.headerOrange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDestructive
                          ? const Color(0xFFB10F1A)
                          : DonationUi.textPrimary,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: isDestructive
                      ? const Color(0xFFE8C4C4)
                      : DonationUi.chevron,
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: AppTypography.inter(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: DonationUi.textMuted,
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
  required Future<void> Function() onConfirm,
}) {
  return Get.bottomSheet<void>(
    _DeleteAccountSheet(onConfirm: onConfirm),
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
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
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
            const SizedBox(height: 20),
            Text(
              title,
              style: AppTypography.lora(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: DonationUi.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: AppTypography.inter(
                fontSize: 14,
                height: 1.45,
                color: DonationUi.textMuted,
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              label: confirmLabel,
              textColor: Colors.white,
              gradientColors: kFigmaActionGradient,
              borderRadius: 14,
              onTap: onConfirm,
            ),
          ],
        ),
      ),
    );
  }
}

class _DeleteAccountSheet extends StatefulWidget {
  const _DeleteAccountSheet({required this.onConfirm});

  final Future<void> Function() onConfirm;

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
      final ok = _ctrl.text.trim().toUpperCase() == 'DELETE';
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
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
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
            const SizedBox(height: 20),
            Text(
              'Delete Account',
              style: AppTypography.lora(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: DonationUi.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Are you sure you want to delete your account? This action cannot be undone.',
              style: AppTypography.inter(
                fontSize: 14,
                height: 1.45,
                color: DonationUi.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ctrl,
              decoration: InputDecoration(
                hintText: 'Type DELETE to confirm',
                filled: true,
                fillColor: DonationUi.cardFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: DonationUi.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: DonationUi.cardBorder),
                ),
              ),
            ),
            const SizedBox(height: 20),
            CustomButton(
              label: 'Yes, delete',
              textColor: Colors.white,
              gradientColors: kFigmaActionGradient,
              borderRadius: 14,
              enabled: _canDelete,
              onTap: () async {
                Get.back();
                await widget.onConfirm();
              },
            ),
          ],
        ),
      ),
    );
  }
}
