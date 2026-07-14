// lib/features/cms/presentation/contents/cms_users_content.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/core/utils/cms_search_scheduler.dart';
import 'package:satya_devotte_app/features/cms/models/admin_model.dart';
import 'package:satya_devotte_app/features/cms/presentation/controllers/admin_controller.dart';
import 'package:satya_devotte_app/features/cms/presentation/pages/cms_shell_page.dart';
import 'package:satya_devotte_app/features/cms/presentation/widgets/cms_shared_widgets.dart';

Widget _cmsClickable({
  required VoidCallback onTap,
  required Widget child,
  HitTestBehavior behavior = HitTestBehavior.deferToChild,
}) {
  return MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: onTap,
      behavior: behavior,
      child: child,
    ),
  );
}

const _cmsButtonClickCursor = WidgetStatePropertyAll<MouseCursor>(
  SystemMouseCursors.click,
);

class CmsUsersContent extends StatefulWidget {
  const CmsUsersContent({super.key});

  @override
  State<CmsUsersContent> createState() => _CmsUsersContentState();
}

class _CmsUsersContentState extends State<CmsUsersContent> {
  late final AdminController _ctrl;
  late final CmsSearchScheduler _searchScheduler;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<AdminController>();
    _searchScheduler = CmsSearchScheduler(
      onSearch: _ctrl.setRegularUsersSearch,
    );
    // Reset search query on enter so we get fresh data
    _ctrl.loadRegularUsers(page: 1, search: '');
  }

  @override
  void dispose() {
    _searchScheduler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width >= 768;

    return Column(
      children: [
        // ── Toolbar ──────────────────────────────────────────────
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isWeb ? 24 : 16,
            vertical: 14,
          ),
          color: CmsColors.white,
          child: Row(
            children: [
              Expanded(
                child: CmsSearchBar(
                  hint: 'Search users...',
                  onChanged: _searchScheduler.onQueryChanged,
                ),
              ),
              const SizedBox(width: 12),
              Obx(
                () => _ctrl.isLoadingRegularUsers
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: CmsColors.orange,
                        ),
                      )
                    : _cmsClickable(
                        onTap: _ctrl.loadRegularUsers,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: CmsColors.bg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: CmsColors.border),
                          ),
                          child: const Icon(
                            Icons.refresh,
                            size: 18,
                            color: CmsColors.textSecond,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: CmsColors.border),

        // ── Content ──────────────────────────────────────────────
        Expanded(
          child: Obx(() {
            // Loading
            if (_ctrl.isLoadingRegularUsers && _ctrl.regularUsers.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: CmsColors.orange),
                    SizedBox(height: 14),
                    Text(
                      'Loading users...',
                      style: TextStyle(
                        color: CmsColors.textSecond,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }

            // Error
            if (_ctrl.error != null && _ctrl.regularUsers.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 36,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _ctrl.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: CmsColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CmsPrimaryButton(
                      label: 'Retry',
                      icon: Icons.refresh,
                      onTap: _ctrl.loadRegularUsers,
                    ),
                  ],
                ),
              );
            }

            final users = _ctrl.regularUsers;
            final isSearchEmpty = _ctrl.regularUsersSearch.isEmpty;

            // Empty
            if (users.isEmpty) {
              return CmsEmptyState(
                icon: Icons.people_outline,
                title: isSearchEmpty ? 'No Users Yet' : 'No Results',
                subtitle: isSearchEmpty
                    ? 'Registered users will appear here'
                    : 'No users match "${_ctrl.regularUsersSearch}"',
              );
            }

            // List (mobile) or Table (web)
            return Column(
              children: [
                Expanded(
                  child: isWeb
                      ? _UsersTable(
                          users: users,
                          onRefresh: () => _ctrl.loadRegularUsers(),
                        )
                      : _UsersList(
                          users: users,
                          onRefresh: () => _ctrl.loadRegularUsers(),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: _UsersPaginationBar(ctrl: _ctrl),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════
// WEB — DataTable layout (matches the screenshot design)
// ════════════════════════════════════════════════════════════════
class _UsersTable extends StatelessWidget {
  const _UsersTable({required this.users, required this.onRefresh});
  final List<AdminModel> users;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: CmsColors.orange,
      onRefresh: onRefresh,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth - 32),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: CmsColors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: DataTable(
                  dataRowMinHeight: 52,
                  dataRowMaxHeight: 52,
                  headingRowHeight: 46,
                  horizontalMargin: 20,
                  columnSpacing: 0,
                  headingRowColor: WidgetStateProperty.all(
                    const Color(0xFFF5F7FA),
                  ),
                  headingTextStyle: const TextStyle(
                    color: CmsColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  dataTextStyle: const TextStyle(
                    color: CmsColors.textPrimary,
                    fontSize: 13,
                  ),

                  columns: const [
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Email')),
                    DataColumn(label: Text('Role')),
                    DataColumn(label: Text('Provider')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: users
                      .map(
                        (u) => DataRow(
                          cells: [
                            // Name + avatar
                            DataCell(
                              Row(
                                children: [
                                  _Avatar(user: u),
                                  const SizedBox(width: 10),
                                  Text(
                                    u.displayName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Email
                            DataCell(
                              Text(
                                u.email,
                                style: const TextStyle(
                                  color: CmsColors.textSecond,
                                ),
                              ),
                            ),
                            // Role badge
                            DataCell(_RoleBadge(role: u.role)),
                            // Provider
                            DataCell(_ProviderBadge(email: u.email)),
                            // Actions
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Tooltip(
                                    message: 'View Profile',
                                    child: IconButton(
                                      style: IconButton.styleFrom().copyWith(
                                        mouseCursor: _cmsButtonClickCursor,
                                      ),
                                      icon: const Icon(
                                        Icons.visibility_outlined,
                                        size: 18,
                                        color: Colors.blue,
                                      ),
                                      onPressed: () =>
                                          _showUserDetail(context, u),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showUserDetail(BuildContext ctx, AdminModel u) {
    showDialog<void>(
      context: ctx,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 360,
          decoration: BoxDecoration(
            color: CmsColors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header with gradient bg ──────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF1A2A4E),
                      const Color(0xFF1A2A4E).withOpacity(0.85),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    // Close button top-right
                    Align(
                      alignment: Alignment.topRight,
                      child: _cmsClickable(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Color(0xFFFCF7EF).withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Color(0xFFFCF7EF),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Avatar
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Color(0xFFFCF7EF).withOpacity(0.4),
                          width: 2,
                        ),
                      ),
                      child: _Avatar(user: u, radius: 32),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      u.displayName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFCF7EF),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      u.email,
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFFFCF7EF).withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Role badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Color(0xFFFCF7EF).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Color(0xFFFCF7EF).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        u.roleLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFFCF7EF),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Info rows ────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _DetailTile(
                      icon: Icons.badge_outlined,
                      label: 'Username',
                      value: u.displayName,
                    ),
                    _DetailTile(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: u.email,
                    ),
                    _DetailTile(
                      icon: Icons.login_outlined,
                      label: 'Provider',
                      value: _providerFromEmail(u.email),
                    ),
                    if (u.phone != null && u.phone!.isNotEmpty)
                      _DetailTile(
                        icon: Icons.phone_outlined,
                        label: 'Phone',
                        value: u.phone!,
                      ),
                    if (u.createdAt != null)
                      _DetailTile(
                        icon: Icons.calendar_today_outlined,
                        label: 'Joined',
                        value: _formatDate(u.createdAt!),
                      ),

                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _providerFromEmail(String email) {
    if (email.contains('gmail')) return 'Google';
    if (email.contains('yahoo')) return 'Yahoo';
    if (email.contains('outlook') || email.contains('hotmail')) {
      return 'Microsoft';
    }
    return 'Email';
  }

  static String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      const m = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${d.day} ${m[d.month - 1]} ${d.year}';
    } catch (_) {
      return iso;
    }
  }
}

// ════════════════════════════════════════════════════════════════
// MOBILE — Card list layout
// ════════════════════════════════════════════════════════════════
class _UsersList extends StatelessWidget {
  const _UsersList({required this.users, required this.onRefresh});
  final List<AdminModel> users;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: CmsColors.orange,
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: users.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (ctx, i) {
          final u = users[i];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: CmsColors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
              ],
            ),
            child: Row(
              children: [
                _Avatar(user: u),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        u.displayName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: CmsColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        u.email,
                        style: const TextStyle(
                          fontSize: 12,
                          color: CmsColors.textSecond,
                        ),
                      ),
                      const SizedBox(height: 5),
                      _RoleBadge(role: u.role),
                    ],
                  ),
                ),
                CmsActionIcon(
                  icon: Icons.visibility_outlined,
                  color: Colors.blue,
                  onTap: () {},
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// SMALL HELPERS
// ════════════════════════════════════════════════════════════════
class _Avatar extends StatelessWidget {
  const _Avatar({required this.user, this.radius = 16});
  final AdminModel user;
  final double radius;

  @override
  Widget build(BuildContext context) {
    if (user.profileImage != null && user.profileImage!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(user.profileImage!),
        onBackgroundImageError: (_, __) {},
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF1A2A4E),
      child: Text(
        user.initials,
        style: TextStyle(
          color: Color(0xFFFCF7EF),
          fontSize: radius * 0.75,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});
  final String role;

  @override
  Widget build(BuildContext context) {
    final color = role.toLowerCase() == 'superadmin'
        ? const Color(0xFF9C27B0)
        : role.toLowerCase() == 'admin'
        ? CmsColors.orange
        : Colors.green;
    final label = role.toLowerCase() == 'superadmin'
        ? 'Super Admin'
        : role.toLowerCase() == 'admin'
        ? 'Admin'
        : 'User';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ProviderBadge extends StatelessWidget {
  const _ProviderBadge({required this.email});
  final String email;

  String get _provider {
    if (email.contains('gmail')) return 'Google';
    if (email.contains('yahoo')) return 'Yahoo';
    if (email.contains('outlook') || email.contains('hotmail')) {
      return 'Microsoft';
    }
    return 'Email';
  }

  @override
  Widget build(BuildContext context) => Text(
    _provider,
    style: const TextStyle(color: CmsColors.textSecond, fontSize: 13),
  );
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: CmsColors.bg,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: CmsColors.border),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: CmsColors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: CmsColors.orange),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: CmsColors.textSecond,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  color: CmsColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _UsersPaginationBar extends StatelessWidget {
  const _UsersPaginationBar({required this.ctrl});
  final AdminController ctrl;

  static const _pageSizes = [10, 25, 50, 100];

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isWide = MediaQuery.of(context).size.width >= 768;
      final page = ctrl.regularUsersPage;
      final size = ctrl.regularUsersPageSize;
      final totalPages = ctrl.regularUsersTotalPages;
      final totalRows = ctrl.regularUsersTotal;
      final start = totalRows == 0 ? 0 : (page - 1) * size + 1;
      final end = (page * size).clamp(0, totalRows);

      final children = <Widget>[
        Text(
          'Showing $start-$end of $totalRows',
          style: const TextStyle(fontSize: 12, color: CmsColors.textSecond),
        ),
        const SizedBox(width: 18),
        const Text(
          'Rows per page:',
          style: TextStyle(fontSize: 12, color: CmsColors.textSecond),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: CmsColors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: CmsColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _pageSizes.contains(size) ? size : _pageSizes.first,
              isDense: true,
              style: const TextStyle(
                fontSize: 12,
                color: CmsColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              items: _pageSizes
                  .map((s) => DropdownMenuItem(value: s, child: Text('$s')))
                  .toList(),
              onChanged: ctrl.isLoadingRegularUsers
                  ? null
                  : (v) {
                      if (v != null) {
                        ctrl.setRegularUsersPageSize(v);
                      }
                    },
            ),
          ),
        ),
      ];

      final pager = <Widget>[
        _UsersPagerBtn(
          icon: Icons.chevron_left,
          enabled: page > 1 && !ctrl.isLoadingRegularUsers,
          onTap: () => ctrl.setRegularUsersPage(page - 1),
        ),
        for (final n in _pageRange(page, totalPages))
          n == -1
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    '...',
                    style: TextStyle(color: CmsColors.textSecond),
                  ),
                )
              : _UsersPageNumberBtn(
                  number: n,
                  isActive: n == page,
                  onTap: () => ctrl.setRegularUsersPage(n),
                ),
        _UsersPagerBtn(
          icon: Icons.chevron_right,
          enabled: page < totalPages && !ctrl.isLoadingRegularUsers,
          onTap: () => ctrl.setRegularUsersPage(page + 1),
        ),
      ];

      if (isWide) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: CmsColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: CmsColors.border),
          ),
          child: Row(
            children: [
              ...children,
              const Spacer(),
              ...pager.map(
                (w) => Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: w,
                ),
              ),
            ],
          ),
        );
      }

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: CmsColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CmsColors.border),
        ),
        child: Column(
          children: [
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 6,
              children: children,
            ),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              runSpacing: 4,
              children: pager,
            ),
          ],
        ),
      );
    });
  }

  List<int> _pageRange(int current, int total) {
    if (total <= 7) return [for (int i = 1; i <= total; i++) i];
    final out = <int>[1];
    final start = (current - 1).clamp(2, total - 4);
    final end = (current + 1).clamp(5, total - 1);
    if (start > 2) out.add(-1);
    for (int i = start; i <= end; i++) {
      out.add(i);
    }
    if (end < total - 1) out.add(-1);
    out.add(total);
    return out;
  }
}

class _UsersPagerBtn extends StatelessWidget {
  const _UsersPagerBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
    child: GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled ? CmsColors.white : CmsColors.bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: CmsColors.border),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? CmsColors.textPrimary : CmsColors.textSecond,
        ),
      ),
    ),
  );
}

class _UsersPageNumberBtn extends StatelessWidget {
  const _UsersPageNumberBtn({
    required this.number,
    required this.isActive,
    required this.onTap,
  });

  final int number;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _cmsClickable(
    onTap: onTap,
    child: Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isActive ? CmsColors.orange : CmsColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? CmsColors.orange : CmsColors.border,
        ),
      ),
      child: Text(
        '$number',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: isActive ? Color(0xFFFCF7EF) : CmsColors.textPrimary,
        ),
      ),
    ),
  );
}
