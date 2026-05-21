// lib/features/cms/presentation/contents/cms_dashboard_content.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/core/network/api_client.dart';
import 'package:satya_devotte_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/features/cms/presentation/pages/cms_shell_page.dart';

class CmsDashboardContent extends StatefulWidget {
  const CmsDashboardContent({super.key});

  @override
  State<CmsDashboardContent> createState() => _CmsDashboardContentState();
}

class _CmsDashboardContentState extends State<CmsDashboardContent> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await Get.find<ApiClient>().dio.get(
        '/api/v1/admin/dashboard',
      );
      final body = res.data as Map<String, dynamic>;
      setState(() {
        _data = body['data'] as Map<String, dynamic>?;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load dashboard';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width >= 768;

    if (_loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: CmsColors.orange),
            SizedBox(height: 14),
            Text(
              'Loading dashboard...',
              style: TextStyle(color: CmsColors.textSecond, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (_error != null || _data == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 36),
            const SizedBox(height: 12),
            Text(
              _error ?? 'No data',
              style: const TextStyle(
                fontSize: 14,
                color: CmsColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: CmsColors.orange,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
            ),
          ],
        ),
      );
    }

    final d = _data!;
    final todayActiveUsers = d['todayActiveUsers'] as int? ?? 0;
    final totalUsers = d['usersCount'] as int? ?? 0;
    final adminsCount = d['adminsCount'] as int? ?? 0;
    final festivals = d['festivals'] as Map<String, dynamic>? ?? {};
    final poojas = d['poojas'] as Map<String, dynamic>? ?? {};
    final donations = d['donations'] as Map<String, dynamic>? ?? {};
    final todaySloka = d['todaySloka'] as Map<String, dynamic>?;

    final totalFestivals =
        (festivals['APPROVED'] as int? ?? 0) +
        (festivals['PENDING'] as int? ?? 0) +
        (festivals['REJECTED'] as int? ?? 0);
    final totalPoojas =
        (poojas['APPROVED'] as int? ?? 0) +
        (poojas['PENDING'] as int? ?? 0) +
        (poojas['REJECTED'] as int? ?? 0);

    return RefreshIndicator(
      color: CmsColors.orange,
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(isWeb ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Stats Grid ──────────────────────────────────
            _StatsGrid(
              isWeb: isWeb,
              stats: [
                _Stat(
                  'Today Active Users',
                  '$todayActiveUsers/$totalUsers',
                  Icons.people_outline,
                  const Color(0xFF4CAF50),
                ),
                _Stat(
                  'Admins',
                  '$adminsCount',
                  Icons.admin_panel_settings_outlined,
                  CmsColors.orange,
                ),
                _Stat(
                  'Total Poojas',
                  '$totalPoojas',
                  Icons.self_improvement_outlined,
                  const Color(0xFF9C27B0),
                ),
                _Stat(
                  'Total Festivals',
                  '$totalFestivals',
                  Icons.celebration_outlined,
                  const Color(0xFF2196F3),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Content Status Row ───────────────────────────
            if (isWeb)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _StatusCard(
                      title: 'Poojas',
                      icon: Icons.self_improvement,
                      color: const Color(0xFF9C27B0),
                      approved: poojas['APPROVED'] as int? ?? 0,
                      pending: poojas['PENDING'] as int? ?? 0,
                      rejected: poojas['REJECTED'] as int? ?? 0,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _StatusCard(
                      title: 'Festivals',
                      icon: Icons.celebration,
                      color: const Color(0xFF2196F3),
                      approved: festivals['APPROVED'] as int? ?? 0,
                      pending: festivals['PENDING'] as int? ?? 0,
                      rejected: festivals['REJECTED'] as int? ?? 0,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _StatusCard(
                      title: 'Donations',
                      icon: Icons.volunteer_activism,
                      color: const Color(0xFF4CAF50),
                      approved: donations['APPROVED'] as int? ?? 0,
                      pending: donations['PENDING'] as int? ?? 0,
                      rejected: donations['REJECTED'] as int? ?? 0,
                    ),
                  ),
                ],
              )
            else
              Column(
                children: [
                  _StatusCard(
                    title: 'Poojas',
                    icon: Icons.self_improvement,
                    color: const Color(0xFF9C27B0),
                    approved: poojas['APPROVED'] as int? ?? 0,
                    pending: poojas['PENDING'] as int? ?? 0,
                    rejected: poojas['REJECTED'] as int? ?? 0,
                  ),
                  const SizedBox(height: 12),
                  _StatusCard(
                    title: 'Festivals',
                    icon: Icons.celebration,
                    color: const Color(0xFF2196F3),
                    approved: festivals['APPROVED'] as int? ?? 0,
                    pending: festivals['PENDING'] as int? ?? 0,
                    rejected: festivals['REJECTED'] as int? ?? 0,
                  ),
                  const SizedBox(height: 12),
                  _StatusCard(
                    title: 'Donations',
                    icon: Icons.volunteer_activism,
                    color: const Color(0xFF4CAF50),
                    approved: donations['APPROVED'] as int? ?? 0,
                    pending: donations['PENDING'] as int? ?? 0,
                    rejected: donations['REJECTED'] as int? ?? 0,
                  ),
                ],
              ),
            const SizedBox(height: 20),

            // ── Today's Sloka ────────────────────────────────
            if (todaySloka != null) _TodaySlokaCard(sloka: todaySloka),

            const SizedBox(height: 20),

            // ── Quick Actions ────────────────────────────────
            const Text(
              "Quick Actions",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: CmsColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            if (isWeb)
              Row(
                children: [
                  Expanded(
                    child: _QuickAction(
                      label: 'Add Puja',
                      icon: Icons.add_circle_outline,
                      color: const Color(0xFF9C27B0),
                      onTap: () {
                        if (!CmsShellNavigation.openAddPuja()) {
                          Get.offNamed(AppRoutes.cmsRitualCreate);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickAction(
                      label: 'Add Festival',
                      icon: Icons.celebration_outlined,
                      color: const Color(0xFF2196F3),
                      onTap: () {
                        if (!CmsShellNavigation.openAddFestival()) {
                          Get.offNamed(AppRoutes.cmsFestivalCreate);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Obx(
                    () => Get.find<AuthController>().isSuperAdmin
                        ? Expanded(
                            child: _QuickAction(
                              label: 'Manage Admins',
                              icon: Icons.admin_panel_settings_outlined,
                              color: CmsColors.orange,
                              onTap: () {
                                if (!CmsShellNavigation.openManageAdmins()) {
                                  Get.offNamed(AppRoutes.cmsAdmins);
                                }
                              },
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              )
            else
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _QuickAction(
                          label: 'Add Puja',
                          icon: Icons.add_circle_outline,
                          color: const Color(0xFF9C27B0),
                          onTap: () {
                            if (!CmsShellNavigation.openAddPuja()) {
                              Get.offNamed(AppRoutes.cmsRitualCreate);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickAction(
                          label: 'Add Festival',
                          icon: Icons.celebration_outlined,
                          color: const Color(0xFF2196F3),
                          onTap: () {
                            if (!CmsShellNavigation.openAddFestival()) {
                              Get.offNamed(AppRoutes.cmsFestivalCreate);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// STATS GRID
// ════════════════════════════════════════════════════════════════
class _Stat {
  const _Stat(this.label, this.value, this.icon, this.color);
  final String label, value;
  final IconData icon;
  final Color color;
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.isWeb, required this.stats});
  final bool isWeb;
  final List<_Stat> stats;

  @override
  Widget build(BuildContext context) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: isWeb ? 4 : 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: isWeb ? 1.8 : 1.5,
    ),
    itemCount: stats.length,
    itemBuilder: (_, i) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CmsColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: stats[i].color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(stats[i].icon, color: stats[i].color, size: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stats[i].value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: stats[i].color,
                ),
              ),
              Text(
                stats[i].label,
                style: const TextStyle(
                  fontSize: 11,
                  color: CmsColors.textSecond,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

// ════════════════════════════════════════════════════════════════
// STATUS CARD — Approved / Pending / Rejected breakdown
// ════════════════════════════════════════════════════════════════
class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.approved,
    required this.pending,
    required this.rejected,
  });
  final String title;
  final IconData icon;
  final Color color;
  final int approved, pending, rejected;

  int get total => approved + pending + rejected;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: CmsColors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: CmsColors.textPrimary,
              ),
            ),
            const Spacer(),
            Text(
              '$total total',
              style: const TextStyle(fontSize: 11, color: CmsColors.textSecond),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _StatusChip('Approved', approved, Colors.green)),
            const SizedBox(width: 8),
            Expanded(child: _StatusChip('Pending', pending, CmsColors.orange)),
            const SizedBox(width: 8),
            Expanded(child: _StatusChip('Rejected', rejected, Colors.red)),
          ],
        ),
        if (total > 0) ...[
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: approved / total,
              minHeight: 6,
              backgroundColor: Colors.red.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            ),
          ),
        ],
      ],
    ),
  );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.label, this.count, this.color);
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: color.withOpacity(0.8),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

// ════════════════════════════════════════════════════════════════
// TODAY'S SLOKA CARD
// ════════════════════════════════════════════════════════════════
class _TodaySlokaCard extends StatefulWidget {
  const _TodaySlokaCard({required this.sloka});
  final Map<String, dynamic> sloka;

  @override
  State<_TodaySlokaCard> createState() => _TodaySlokaCardState();
}

class _TodaySlokaCardState extends State<_TodaySlokaCard> {
  int _selectedTab = -1; // -1 Sloka, 0 Meaning, 1 Contemplation, 2 Prayer

  String _tabText() {
    switch (_selectedTab) {
      case 1:
        return (widget.sloka['contemplation'] as String? ?? '').trim();
      case 2:
        return (widget.sloka['prayer'] as String? ?? '').trim();
      case 0:
      default:
        return (widget.sloka['meaning'] as String? ?? '').trim();
    }
  }

  @override
  Widget build(BuildContext context) {
    final fallback = (widget.sloka['sloka'] as String? ?? '').trim();
    final text = _selectedTab == -1
        ? fallback
        : (_tabText().isNotEmpty ? _tabText() : fallback);
    final author = widget.sloka['author'] as String? ?? '';
    final date = widget.sloka['dateKey'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A2A4E),
            const Color(0xFF1A2A4E).withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A2A4E).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: CmsColors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.menu_book,
                  color: CmsColors.orange,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                "Today's Sloka",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              if (date.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    date,
                    style: const TextStyle(fontSize: 10, color: Colors.white70),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.white,
                height: 1.7,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (author.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  '— ',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
                Text(
                  author,
                  style: const TextStyle(
                    fontSize: 12,
                    color: CmsColors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SlokaActionBtn(
                  label: 'Meaning',
                  icon: Icons.search_outlined,
                  selected: _selectedTab == 0,
                  onTap: () => setState(() => _selectedTab = 0),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SlokaActionBtn(
                  label: 'Contemplation',
                  icon: Icons.self_improvement_outlined,
                  selected: _selectedTab == 1,
                  onTap: () => setState(() => _selectedTab = 1),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SlokaActionBtn(
                  label: 'Prayer / Resolve',
                  icon: Icons.spa_outlined,
                  selected: _selectedTab == 2,
                  onTap: () => setState(() => _selectedTab = 2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SlokaActionBtn extends StatelessWidget {
  const _SlokaActionBtn({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? Colors.white.withOpacity(0.2) : Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected ? Colors.white.withOpacity(0.35) : Colors.white.withOpacity(0.12),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 16,
            color: selected ? CmsColors.orange : Colors.white70,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: selected ? Colors.white : Colors.white70,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );
}

// ════════════════════════════════════════════════════════════════
// QUICK ACTION BUTTON
// ════════════════════════════════════════════════════════════════
class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
