import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:satya_devotte_app/features/donations/presentation/widgets/donation_ui.dart';
import 'package:satya_devotte_app/features/profile/presentation/widgets/profile_ui.dart';

/// Figma "More Options" — Logout & Delete Account.
class ProfileMoreOptionsPage extends StatelessWidget {
  const ProfileMoreOptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: DonationUi.background,
      appBar: DonationSimpleAppBar(title: 'More Options', onBack: Get.back),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          ProfileLinkTile(
            icon: Icons.logout_outlined,
            label: 'Logout',
            onTap: () => showProfileLogoutSheet(
              onConfirm: () async {
                await auth.signOut();
                Get.offAllNamed(AppRoutes.login);
              },
            ),
          ),
          ProfileLinkTile(
            icon: Icons.delete_outline,
            label: 'Delete Account',
            isDestructive: true,
            onTap: () => showProfileDeleteAccountSheet(
              onConfirm: () async {
                Get.snackbar(
                  'Account',
                  'Delete account is not available yet.',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
