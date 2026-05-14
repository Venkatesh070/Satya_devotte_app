import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:satya_devotte_app/features/profile/presentation/controllers/profile_controller.dart';
import 'package:satya_devotte_app/shared/pages/chakra_loader_page.dart';
import 'package:satya_devotte_app/shared/widgets/custom_button.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final profileController = Get.find<ProfileController>();
    return Obx(() {
      final isLoading = profileController.isLoading;
      final error = profileController.error;
      final profile = profileController.profile;
      final sessionUser = profileController.sessionUser;
      final userData =
          sessionUser ?? profile?['user'] as Map<String, dynamic>? ?? profile;
      final email = userData?['email']?.toString();
      final role = userData?['role']?.toString();
      final id =
          userData?['id']?.toString() ??
          userData?['_id']?.toString() ??
          userData?['userId']?.toString();

      return Scaffold(
        body: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Profile',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    if (error != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1F0),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(error),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F3EA),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Email: ${email ?? '-'}'),
                            const SizedBox(height: 6),
                            Text('Role: ${role ?? '-'}'),
                            const SizedBox(height: 6),
                            Text('Id: ${id ?? '-'}'),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),
                    _ProfileLink(
                      icon: Icons.receipt_long_outlined,
                      label: 'My Orders',
                      onTap: () => Get.toNamed(AppRoutes.userOrders),
                    ),
                    const SizedBox(height: 12),
                    _ProfileLink(
                      icon: Icons.volunteer_activism_outlined,
                      label: 'My Contributions',
                      onTap: () => Get.toNamed(AppRoutes.userContributions),
                    ),
                    const Spacer(),
                    CustomButton(
                      label: 'Refresh Profile',
                      onTap: profileController.loadProfile,
                    ),
                    const SizedBox(height: 12),
                    CustomButton(
                      label: 'Logout',
                      onTap: () async {
                        await authController.signOut();
                        Get.offAllNamed(AppRoutes.login);
                      },
                    ),
                  ],
                ),
              ),
            ),
            if (isLoading) const ChakraLoaderPage(asOverlay: true),
          ],
        ),
      );
    });
  }
}

class _ProfileLink extends StatelessWidget {
  const _ProfileLink({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFF7F3EA)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF8B4513)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF333333),
                ),
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
