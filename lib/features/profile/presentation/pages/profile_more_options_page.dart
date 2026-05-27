import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:satya_devotte_app/features/donations/presentation/widgets/donation_ui.dart';
import 'package:satya_devotte_app/features/profile/presentation/controllers/profile_controller.dart';
import 'package:satya_devotte_app/features/profile/presentation/widgets/profile_ui.dart';
import 'package:satya_devotte_app/shared/pages/chakra_loader_page.dart';

/// Figma "More Options" — Logout & Delete Account.
class ProfileMoreOptionsPage extends StatelessWidget {
  const ProfileMoreOptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final profile = Get.find<ProfileController>();

    return Scaffold(
      backgroundColor: DonationUi.background,
      appBar: DonationSimpleAppBar(title: 'More Options', onBack: Get.back),
      body: Stack(
        children: [
          ListView(
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
                  userName: profile.userName,
                  onConfirm: (comment) async {
                    final ok = await auth.deleteAccount(comment: comment);
                    if (ok) {
                      Get.offAllNamed(AppRoutes.login);
                      Get.snackbar(
                        'Account Deleted',
                        'Your account has been deleted successfully.',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    } else {
                      Get.snackbar(
                        'Error',
                        auth.lastAuthError ?? 'Failed to delete account.',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    }
                  },
                ),
              ),
            ],
          ),
          Obx(
            () => auth.isAuthLoading
                ? const ChakraLoaderPage(asOverlay: true)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
