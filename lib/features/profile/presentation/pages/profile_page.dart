import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:satya_devotte_app/features/donations/presentation/widgets/donation_ui.dart';
import 'package:satya_devotte_app/features/profile/presentation/controllers/profile_controller.dart';
import 'package:satya_devotte_app/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:satya_devotte_app/features/profile/presentation/pages/profile_about_page.dart';
import 'package:satya_devotte_app/features/profile/presentation/pages/profile_pooja_history_page.dart';
import 'package:satya_devotte_app/features/profile/presentation/widgets/profile_ui.dart';
import 'package:satya_devotte_app/shared/pages/chakra_loader_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final profileController = Get.find<ProfileController>();
    final authController = Get.find<AuthController>();

    return Obx(() {
      final userData = profileController.resolvedUser;

      String? t(dynamic v) {
        final s = v?.toString().trim();
        if (s == null || s.isEmpty) return null;
        return s;
      }

      // Prefer the real full name. If backend doesn't send it yet, fall back
      // to other known keys (and ultimately to controller's best-effort name).
      final name =
          (t(userData?['fullName']) ??
                  t(userData?['full_name']) ??
                  t(userData?['name']) ??
                  t(userData?['displayName']) ??
                  t(profileController.userName) ??
                  'Devotee')
              .toString();

      final phone = t(userData?['phone']) ?? t(userData?['phoneNumber']);
      final email = t(userData?['email']);
      final sunSign = t(userData?['sunSign']);
      final moonSign = t(userData?['moonSign']);
      final imageUrl = userData?['imageUrl'] ?? userData?['profileImageUrl'];

      String? dob;
      final rawDob = userData?['dateOfBirth'];
      if (rawDob != null && rawDob.toString().trim().isNotEmpty) {
        try {
          dob = DateFormat(
            'dd MMM yyyy',
          ).format(DateTime.parse(rawDob.toString()));
        } catch (_) {
          dob = rawDob.toString();
        }
      }

      final initials = name.isNotEmpty
          ? name
                .split(' ')
                .map((part) => part.isNotEmpty ? part[0] : '')
                .take(2)
                .join()
                .toUpperCase()
          : 'D';

      return Scaffold(
        backgroundColor: AppColors.appBgColor,
        body: Stack(
          children: [
            RefreshIndicator(
              onRefresh: profileController.loadProfile,
              color: AppColors.gradientEnd,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ProfileHeader(
                      name: name,
                      initials: initials,
                      imageUrl: imageUrl?.toString(),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 50),
                          const ProfileSectionHeading('Spiritual'),
                          ProfileLinkTile(
                            icon: Icons.inventory_2_outlined,
                            label: 'My Orders',
                            onTap: () => Get.toNamed(AppRoutes.userOrders),
                          ),
                          const SizedBox(height: 8),
                          _InfoCard(
                            phone: phone,
                            email: email,
                            dob: dob,
                            sunSign: sunSign,
                            moonSign: moonSign,
                          ),
                          const SizedBox(height: 22),
                          const ProfileSectionHeading('Spiritual'),
                          ProfileLinkTile(
                            icon: Icons.volunteer_activism_outlined,
                            label: 'Donations',
                            onTap: () => Get.toNamed(AppRoutes.userDonations),
                          ),
                          ProfileLinkTile(
                            icon: Icons.temple_hindu_outlined,
                            label: 'Puja History',
                            onTap: () =>
                                Get.to(() => const ProfilePoojaHistoryPage()),
                          ),
                          // ProfileLinkTile(
                          //   icon: Icons.emoji_events_outlined,
                          //   label: 'Achievements',
                          //   onTap: () =>
                          //       Get.to(() => const ProfileAchievementsPage()),
                          // ),
                          const SizedBox(height: 22),
                          const ProfileSectionHeading('Settings'),
                          ProfileLinkTile(
                            icon: Icons.info_outline,
                            label: 'About the app',
                            onTap: () => Get.to(() => const ProfileAboutPage()),
                          ),
                          ProfileLinkTile(
                            icon: Icons.logout_outlined,
                            label: 'Logout',
                            onTap: () => showProfileLogoutSheet(
                              onConfirm: () async {
                                await authController.signOut();
                                Get.offAllNamed(AppRoutes.login);
                              },
                            ),
                          ),
                          ProfileLinkTile(
                            icon: Icons.delete_outline,
                            label: 'Delete Account',
                            isDestructive: true,
                            onTap: () => showProfileDeleteAccountSheet(
                              userName: profileController.userName,
                              onConfirm: (comment) async {
                                final ok = await authController.deleteAccount(
                                  comment: comment,
                                );
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
                                    authController.lastAuthError ??
                                        'Failed to delete account.',
                                    snackPosition: SnackPosition.BOTTOM,
                                  );
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 70),
                          _Footer(),
                          const SizedBox(height: 105),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (authController.isAuthLoading)
              const ChakraLoaderPage(asOverlay: true),
          ],
        ),
      );
    });
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.initials,
    this.imageUrl,
  });

  final String name;
  final String initials;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return SizedBox(
      height: topPadding + 178,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topPadding + 150,
            child: const Image(
              image: AssetImage('assets/images/pooja/pujaHeaderImg.png'),
              fit: BoxFit.fill,
              alignment: Alignment.topCenter,
            ),
          ),
          Positioned(
            top: topPadding + 64,
            left: 20,
            child: Text(
              'My Profile',
              style: AppTypography.lora(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
          Positioned(
            top: topPadding + 112,
            child: Column(
              children: [
                _ProfileAvatar(initials: initials, imageUrl: imageUrl),
                const SizedBox(height: 10),
                Text(
                  name,
                  style: AppTypography.lora(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1C1917),
                  ),
                ),
                const SizedBox(height: 8),
                const _HeaderDivider(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderDivider extends StatelessWidget {
  const _HeaderDivider();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Image(
        image: AssetImage('assets/images/home/divider.png'),
        width: 145,
        fit: BoxFit.contain,
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.initials, this.imageUrl});

  final String initials;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: Container(
          alignment: Alignment.center,
          child: imageUrl != null && imageUrl!.isNotEmpty
              ? Image.network(
                  imageUrl!,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _AvatarInitials(initials),
                )
              : _AvatarInitials(initials),
        ),
      ),
    );
  }
}

class _AvatarInitials extends StatelessWidget {
  const _AvatarInitials(this.initials);

  final String initials;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Color(0xFF183EA4), Color(0xFFE35600)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(bounds),
      blendMode: BlendMode.srcIn,
      child: Text(
        initials,
        style: AppTypography.lora(fontSize: 17, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.phone,
    required this.email,
    required this.dob,
    required this.sunSign,
    required this.moonSign,
  });

  final String? phone;
  final String? email;
  final String? dob;
  final String? sunSign;
  final String? moonSign;

  void _openEditProfile(BuildContext context) {
    Navigator.of(
      context,
      rootNavigator: true,
    ).push(MaterialPageRoute<void>(builder: (_) => const EditProfilePage()));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF2E6D1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A7A4E12),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 46),
            child: Column(
              children: [
                _InfoRow(
                  Icons.phone_outlined,
                  'Phone Number',
                  value: phone,
                  placeholder: 'Not added',
                ),
                const SizedBox(height: 16),
                _InfoRow(
                  Icons.mail_outline,
                  'Email ID',
                  value: email,
                  placeholder: 'Not added',
                ),
                const SizedBox(height: 16),
                _InfoRow(
                  Icons.calendar_today_outlined,
                  'Date of Birth',
                  value: dob,
                  placeholder: 'Not set',
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _SignBadge(
                        'Sun Sign',
                        value: sunSign,
                        placeholder: 'Not set',
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: _SignBadge(
                        'Moon Sign',
                        value: moonSign,
                        placeholder: 'Not set',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _openEditProfile(context),
                borderRadius: BorderRadius.circular(20),
                child: Ink(
                  height: 30,
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [AppColors.gradientStart, AppColors.gradientEnd],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Edit Details',
                      style: AppTypography.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(
    this.icon,
    this.label, {
    required this.value,
    required this.placeholder,
  });

  final IconData icon;
  final String label;
  final String? value;
  final String placeholder;

  @override
  Widget build(BuildContext context) {
    final v = (value ?? '').trim();
    final isMissing = v.isEmpty;
    final shown = isMissing ? placeholder : v;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.appBgColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: DonationUi.cardBorder),
          ),
          child: Icon(icon, size: 16, color: DonationUi.textMuted),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.inter(
                  fontSize: 12,
                  color: Color(0XFF78716C),
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text(
                shown,
                style: AppTypography.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: isMissing
                      ? DonationUi.textMuted
                      : const Color(0XFF1C1917),
                  fontStyle: isMissing ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SignBadge extends StatelessWidget {
  const _SignBadge(
    this.label, {
    required this.value,
    required this.placeholder,
  });

  final String label;
  final String? value;
  final String placeholder;

  @override
  Widget build(BuildContext context) {
    final v = (value ?? '').trim();
    final isMissing = v.isEmpty;
    final shown = isMissing ? placeholder : v;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.inter(
            fontSize: 12,
            color: Color(0XFF78716C),
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          shown,
          style: AppTypography.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: isMissing ? DonationUi.textMuted : const Color(0XFF1C1917),
            fontStyle: isMissing ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final info = snapshot.data;
              final version = info?.version ?? '';
              final buildNumber = info?.buildNumber ?? '';
              final label = version.isEmpty
                  ? 'Sathya'
                  : buildNumber.isEmpty
                  ? 'Sathya v$version'
                  : 'Sathya v$version ($buildNumber)';
              return Text(
                label,
                style: AppTypography.inter(fontSize: 12, color: Colors.grey),
              );
            },
          ),
          const SizedBox(height: 4),
          Text(
            'Made with devotion for spirits',
            style: AppTypography.lora(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Color(0XFF78716C),
            ),
          ),
          const SizedBox(height: 12),
          Image.asset(
            'assets/images/redin_consulting.png',
            width: 116,
            height: 32,
          ),
        ],
      ),
    );
  }
}
