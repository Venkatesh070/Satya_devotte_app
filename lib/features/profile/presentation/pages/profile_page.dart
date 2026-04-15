import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:satya_devotte_app/features/profile/presentation/controllers/profile_controller.dart';
import 'package:satya_devotte_app/shared/widgets/custom_button.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final profileController = Get.find<ProfileController>();
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Obx(() {
            final isLoading = profileController.isLoading;
            final error = profileController.error;
            final profile = profileController.profile;
            final sessionUser = profileController.sessionUser;
            final userData = sessionUser ?? profile?['user'] as Map<String, dynamic>? ?? profile;
            final email = userData?['email']?.toString();
            final role = userData?['role']?.toString();
            final id = userData?['id']?.toString() ??
                userData?['_id']?.toString() ??
                userData?['userId']?.toString();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Profile',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                if (isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (error != null)
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
            );
          }),
        ),
      ),
    );
  }
}
