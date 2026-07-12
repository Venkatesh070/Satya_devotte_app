import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/features/donations/presentation/widgets/donation_ui.dart';

class _Achievement {
  const _Achievement({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.completed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool completed;
}

/// Figma Achievements list.
class ProfileAchievementsPage extends StatelessWidget {
  const ProfileAchievementsPage({super.key});

  static const _items = [
    _Achievement(
      icon: Icons.emoji_events_outlined,
      title: 'First Steps',
      subtitle: 'Completed your first puja',
      completed: true,
    ),
    _Achievement(
      icon: Icons.local_fire_department_outlined,
      title: '7 Day Streak',
      subtitle: 'Practised rituals for 7 days in a row',
      completed: true,
    ),
    _Achievement(
      icon: Icons.favorite_outline,
      title: 'Devotee Spirit',
      subtitle: 'Made your first donation',
      completed: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DonationUi.background,
      appBar: DonationSimpleAppBar(title: 'Achievements', onBack: Get.back),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _AchievementCard(item: _items[i]),
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.item});

  final _Achievement item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFFCF7EF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DonationUi.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFAF7F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: DonationUi.headerOrange),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: AppTypography.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: DonationUi.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  style: AppTypography.inter(
                    fontSize: 12,
                    color: DonationUi.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (item.completed)
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: Color(0xFFE7F6EC),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                size: 16,
                color: DonationUi.successGreen,
              ),
            ),
        ],
      ),
    );
  }
}
