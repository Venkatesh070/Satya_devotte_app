import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/features/donations/presentation/widgets/donation_ui.dart';
import 'package:satya_devotte_app/features/profile/presentation/controllers/profile_controller.dart';
import 'package:satya_devotte_app/features/profile/presentation/pages/profile_about_page.dart';
import 'package:satya_devotte_app/features/profile/presentation/pages/profile_achievements_page.dart';
import 'package:satya_devotte_app/features/profile/presentation/pages/profile_more_options_page.dart';
import 'package:satya_devotte_app/features/profile/presentation/pages/profile_pooja_history_page.dart';
import 'package:satya_devotte_app/features/profile/presentation/widgets/profile_ui.dart';
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final profileController = Get.find<ProfileController>();

    return Obx(() {
      final userData = profileController.resolvedUser;

      final name = (userData?['fullName'] ?? userData?['name'] ?? 'Devotee')
          .toString();
      final phone = (userData?['phone'] ?? 'Not provided').toString();

      String dob = 'Not provided';
      final rawDob = userData?['dateOfBirth'];
      if (rawDob != null) {
        try {
          final date = DateTime.parse(rawDob.toString());
          dob = DateFormat('dd MMM yyyy').format(date);
        } catch (_) {
          dob = rawDob.toString();
        }
      }

      final sunSign = (userData?['sunSign'] ?? 'Not provided').toString();
      final moonSign = (userData?['moonSign'] ?? 'Not provided').toString();
      final imageUrl = userData?['imageUrl'] ?? userData?['profileImageUrl'];

      final initials = name.isNotEmpty
          ? name
                .split(' ')
                .map((e) => e.isNotEmpty ? e[0] : '')
                .take(2)
                .join()
                .toUpperCase()
          : 'D';

      return Scaffold(
        backgroundColor: AppColors.appBgColor,
        body: RefreshIndicator(
          onRefresh: profileController.loadProfile,
          child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
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
                          _InfoCard(phone, dob, sunSign, moonSign),
                          const SizedBox(height: 30),
                          const ProfileSectionHeading('Spiritual'),
                          ProfileLinkTile(
                            icon: Icons.volunteer_activism_outlined,
                            label: 'Donations',
                            onTap: () => Get.toNamed(AppRoutes.userDonations),
                          ),
                          ProfileLinkTile(
                            icon: Icons.temple_hindu_outlined,
                            label: 'Pooja History',
                            onTap: () =>
                                Get.to(() => const ProfilePoojaHistoryPage()),
                          ),
                          // ProfileLinkTile(
                          //   icon: Icons.emoji_events_outlined,
                          //   label: 'Achievements',
                          //   onTap: () =>
                          //       Get.to(() => const ProfileAchievementsPage()),
                          // ),
                          const SizedBox(height: 30),
                          const ProfileSectionHeading('Settings'),
                          ProfileLinkTile(
                            icon: Icons.info_outline,
                            label: 'About the app',
                            onTap: () => Get.to(() => const ProfileAboutPage()),
                          ),
                          ProfileLinkTile(
                            icon: Icons.settings_outlined,
                            label: 'More options',
                            onTap: () =>
                                Get.to(() => const ProfileMoreOptionsPage()),
                          ),
                          const SizedBox(height: 40),
                          _Footer(),
                          const SizedBox(height: 150),
                        ],
                      ),
                    ),
                  ],
                ),
          ),
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
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 200,
          child: Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: [
              const Positioned.fill(
                child: Image(
                  image: AssetImage('assets/images/pooja/pujaHeaderImg.png'),
                  fit: BoxFit.fill,
                  alignment: Alignment.topCenter,
                ),
              ),
              Positioned(
                bottom: -40,
                child: Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                          color: AppColors.appBgColor,
                          width: 4,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x40000000),
                            blurRadius: 18,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: imageUrl != null && imageUrl!.isNotEmpty
                          ? ClipOval(
                              child: Image.network(
                                imageUrl!,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Text(
                                      initials,
                                      style: AppTypography.inter(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF1C1917),
                                      ),
                                    ),
                              ),
                            )
                          : Text(
                              initials,
                              style: AppTypography.inter(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1C1917),
                              ),
                            ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => Get.toNamed(AppRoutes.editProfile),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                AppColors.gradientStart,
                                AppColors.gradientEnd,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),

                          child: const Icon(
                            Icons.edit_outlined,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 52),
        Text(
          name,
          style: AppTypography.lora(
            fontSize: 24,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1C1917),
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard(this.phone, this.dob, this.sunSign, this.moonSign);

  final String phone;
  final String dob;
  final String sunSign;
  final String moonSign;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        color: Color(0xFFFCF7EF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Color(0xFFFCF7EF)),
      ),
      child: Column(
        children: [
          _InfoRow(Icons.phone_outlined, 'Phone Number', phone),
          const Divider(height: 24, color: DonationUi.cardBorder),
          _InfoRow(Icons.calendar_today_outlined, 'Date of Birth', dob),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _SignBadge('Sun Sign', sunSign)),
              const SizedBox(width: 12),
              Expanded(child: _SignBadge('Moon Sign', moonSign)),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.appBgColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: DonationUi.cardBorder),
          ),
          child: Icon(icon, size: 20, color: DonationUi.textMuted),
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
                value,
                style: AppTypography.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0XFF1C1917),
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
  const _SignBadge(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
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
          value,
          style: AppTypography.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color(0XFF1C1917),
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
          Text(
            'Sathya v1.2.0',
            style: AppTypography.inter(fontSize: 12, color: Colors.grey),
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
