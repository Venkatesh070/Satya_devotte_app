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
                foregroundColor: Color(0xFFFCF7EF),
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
    final rituals = d['rituals'] as Map<String, dynamic>? ?? {};
    final deities = d['deities'] as Map<String, dynamic>? ?? {};
    final todaySloka = d['todaySloka'] as Map<String, dynamic>?;

    final totalPoojas =
        (poojas['APPROVED'] as int? ?? 0) +
        (poojas['PENDING'] as int? ?? 0) +
        (poojas['REJECTED'] as int? ?? 0);
    final totalRituals =
        (rituals['APPROVED'] as int? ?? 0) +
        (rituals['PENDING'] as int? ?? 0) +
        (rituals['REJECTED'] as int? ?? 0);

    final overviewStats = [
      _Stat(
        'Active today',
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
        'Pujas',
        '$totalPoojas',
        Icons.self_improvement_outlined,
        const Color(0xFF9C27B0),
      ),
      _Stat(
        'Rituals',
        '$totalRituals',
        Icons.local_fire_department_outlined,
        const Color(0xFFE65100),
      ),
    ];

    final statusCards = [
      _StatusCard(
        title: 'Pujas',
        icon: Icons.self_improvement,
        color: const Color(0xFF9C27B0),
        approved: poojas['APPROVED'] as int? ?? 0,
        pending: poojas['PENDING'] as int? ?? 0,
        rejected: poojas['REJECTED'] as int? ?? 0,
      ),
      _StatusCard(
        title: 'Rituals',
        icon: Icons.local_fire_department,
        color: const Color(0xFFE65100),
        approved: rituals['APPROVED'] as int? ?? 0,
        pending: rituals['PENDING'] as int? ?? 0,
        rejected: rituals['REJECTED'] as int? ?? 0,
      ),
      _StatusCard(
        title: 'Festivals',
        icon: Icons.celebration,
        color: const Color(0xFF2196F3),
        approved: festivals['APPROVED'] as int? ?? 0,
        pending: festivals['PENDING'] as int? ?? 0,
        rejected: festivals['REJECTED'] as int? ?? 0,
      ),
      _StatusCard(
        title: 'Deities',
        icon: Icons.auto_awesome,
        color: CmsColors.orange,
        approved: deities['APPROVED'] as int? ?? 0,
        pending: deities['PENDING'] as int? ?? 0,
        rejected: deities['REJECTED'] as int? ?? 0,
      ),
    ];

    return RefreshIndicator(
      color: CmsColors.orange,
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(isWeb ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionLabel('Overview'),
            const SizedBox(height: 12),
            _EqualCards(
              isWeb: isWeb,
              children: [
                for (final s in overviewStats) _OverviewStatCard(stat: s),
              ],
            ),
            const SizedBox(height: 24),
            const _SectionLabel('Content review'),
            const SizedBox(height: 12),
            _EqualCards(
              isWeb: isWeb,
              children: statusCards,
            ),
            const SizedBox(height: 24),

            // ── Today's Sloka ────────────────────────────────
            if (todaySloka != null) ...[
              _TodaySlokaCard(sloka: todaySloka),
              const SizedBox(height: 24),
            ],

            // ── Quick Actions ────────────────────────────────
            const _SectionLabel('Quick actions'),
            const SizedBox(height: 12),
            if (isWeb)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _QuickAction(
                          label: 'Add Puja',
                          icon: Icons.self_improvement_outlined,
                          color: const Color(0xFF9C27B0),
                          onTap: () {
                            if (!CmsShellNavigation.openAddPuja()) {
                              Get.offNamed(AppRoutes.cmsPujaCreate);
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
                      Expanded(
                        child: _QuickAction(
                          label: 'Add Ritual',
                          icon: Icons.local_fire_department_outlined,
                          color: const Color(0xFF6A1B9A),
                          onTap: () {
                            if (!CmsShellNavigation.openAddRitual()) {
                              Get.offNamed(AppRoutes.cmsManageRituals);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickAction(
                          label: 'Add Deity',
                          icon: Icons.auto_awesome_outlined,
                          color: const Color(0xFF00897B),
                          onTap: () {
                            if (!CmsShellNavigation.openAddDeity()) {
                              Get.offNamed(AppRoutes.cmsDeities);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  Obx(
                    () => Get.find<AuthController>().isSuperAdmin
                        ? Padding(
                            padding: const EdgeInsets.only(top: 12),
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _QuickAction(
                          label: 'Add Puja',
                          icon: Icons.self_improvement_outlined,
                          color: const Color(0xFF9C27B0),
                          onTap: () {
                            if (!CmsShellNavigation.openAddPuja()) {
                              Get.offNamed(AppRoutes.cmsPujaCreate);
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
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickAction(
                          label: 'Add Ritual',
                          icon: Icons.local_fire_department_outlined,
                          color: const Color(0xFF6A1B9A),
                          onTap: () {
                            if (!CmsShellNavigation.openAddRitual()) {
                              Get.offNamed(AppRoutes.cmsManageRituals);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickAction(
                          label: 'Add Deity',
                          icon: Icons.auto_awesome_outlined,
                          color: const Color(0xFF00897B),
                          onTap: () {
                            if (!CmsShellNavigation.openAddDeity()) {
                              Get.offNamed(AppRoutes.cmsDeities);
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
// LAYOUT HELPERS
// ════════════════════════════════════════════════════════════════
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: CmsColors.textPrimary,
      ),
    );
  }
}

class _DashboardCardShell extends StatelessWidget {
  const _DashboardCardShell({required this.child, this.padding});
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CmsColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CmsColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _EqualCards extends StatelessWidget {
  const _EqualCards({required this.isWeb, required this.children});
  final bool isWeb;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (!isWeb) {
      final rows = <Widget>[];
      for (var i = 0; i < children.length; i += 2) {
        final left = children[i];
        final right = i + 1 < children.length ? children[i + 1] : null;
        rows.add(
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: left),
                const SizedBox(width: 12),
                Expanded(child: right ?? const SizedBox.shrink()),
              ],
            ),
          ),
        );
        if (i + 2 < children.length) rows.add(const SizedBox(height: 12));
      }
      return Column(children: rows);
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(child: children[i]),
          ],
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// OVERVIEW STAT CARD
// ════════════════════════════════════════════════════════════════
class _Stat {
  const _Stat(this.label, this.value, this.icon, this.color);
  final String label, value;
  final IconData icon;
  final Color color;
}

class _OverviewStatCard extends StatelessWidget {
  const _OverviewStatCard({required this.stat});
  final _Stat stat;

  @override
  Widget build(BuildContext context) {
    return _DashboardCardShell(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: stat.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(stat.icon, color: stat.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  stat.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    color: stat.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stat.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.2,
                    color: CmsColors.textSecond,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
  Widget build(BuildContext context) {
    final approvedShare = total == 0 ? 0.0 : approved / total;
    final pendingShare = total == 0 ? 0.0 : pending / total;
    final rejectedShare = total == 0 ? 0.0 : rejected / total;

    return _DashboardCardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: color, size: 17),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: CmsColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '$total total',
                style: const TextStyle(
                  fontSize: 11,
                  color: CmsColors.textSecond,
                  fontWeight: FontWeight.w500,
                ),
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
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 6,
              child: total == 0
                  ? Container(color: CmsColors.border)
                  : Row(
                      children: [
                        if (approvedShare > 0)
                          Expanded(
                            flex: (approvedShare * 1000).round().clamp(1, 1000),
                            child: Container(color: Colors.green),
                          ),
                        if (pendingShare > 0)
                          Expanded(
                            flex: (pendingShare * 1000).round().clamp(1, 1000),
                            child: Container(color: CmsColors.orange),
                          ),
                        if (rejectedShare > 0)
                          Expanded(
                            flex: (rejectedShare * 1000).round().clamp(1, 1000),
                            child: Container(color: Colors.red),
                          ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
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
            color: color.withOpacity(0.85),
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
  int _selectedTab = -1; // -1 hidden, 0 Meaning, 1 Contemplation, 2 Prayer

  String _secondaryText() {
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

  Widget _slokaTextBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Color(0xFFFCF7EF).withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Color(0xFFFCF7EF).withOpacity(0.1)),
      ),
      child: Text(
        text.isNotEmpty ? text : '—',
        style: const TextStyle(
          fontSize: 15,
          color: Color(0xFFFCF7EF),
          height: 1.7,
          fontWeight: FontWeight.w400,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shlokaText = (widget.sloka['sloka'] as String? ?? '').trim();
    final author = widget.sloka['author'] as String? ?? '';
    final date = widget.sloka['dateKey'] as String? ?? '';
    final showSecondary = _selectedTab >= 0;

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
                  color: Color(0xFFFCF7EF),
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
                    color: Color(0xFFFCF7EF).withOpacity(0.1),
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
          _slokaTextBox(shlokaText),
          if (showSecondary) ...[
            const SizedBox(height: 10),
            _slokaTextBox(_secondaryText()),
          ],
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
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Color(0xFFFCF7EF).withOpacity(0.2) : Color(0xFFFCF7EF).withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? Color(0xFFFCF7EF).withOpacity(0.35) : Color(0xFFFCF7EF).withOpacity(0.12),
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
                color: selected ? Color(0xFFFCF7EF) : Colors.white70,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
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
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
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
    ),
  );
}
