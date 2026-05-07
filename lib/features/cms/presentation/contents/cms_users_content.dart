// lib/features/cms/presentation/contents/cms_users_content.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/features/cms/models/admin_model.dart';
import 'package:satya_devotte_app/features/cms/presentation/controllers/admin_controller.dart';
import 'package:satya_devotte_app/features/cms/presentation/pages/cms_shell_page.dart';
import 'package:satya_devotte_app/features/cms/presentation/widgets/cms_shared_widgets.dart';

class CmsUsersContent extends StatefulWidget {
  const CmsUsersContent({super.key});

  @override
  State<CmsUsersContent> createState() => _CmsUsersContentState();
}

class _CmsUsersContentState extends State<CmsUsersContent> {
  late final AdminController _ctrl;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<AdminController>();
    _ctrl.loadRegularUsers();
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
                  onChanged: (v) => setState(() => _search = v.toLowerCase()),
                ),
              ),
              const SizedBox(width: 12),
              Obx(
                () => _ctrl.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: CmsColors.orange,
                        ),
                      )
                    : GestureDetector(
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
            if (_ctrl.isLoading && _ctrl.regularUsers.isEmpty) {
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

            // Filter by search
            final users = _ctrl.regularUsers
                .where(
                  (u) =>
                      _search.isEmpty ||
                      u.displayName.toLowerCase().contains(_search) ||
                      u.email.toLowerCase().contains(_search),
                )
                .toList();

            // Empty
            if (users.isEmpty) {
              return CmsEmptyState(
                icon: Icons.people_outline,
                title: _search.isEmpty ? 'No Users Yet' : 'No Results',
                subtitle: _search.isEmpty
                    ? 'Registered users will appear here'
                    : 'No users match "$_search"',
              );
            }

            // List (mobile) or Table (web)
            return isWeb
                ? _UsersTable(users: users, onRefresh: _ctrl.loadRegularUsers)
                : _UsersList(users: users, onRefresh: _ctrl.loadRegularUsers);
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
                      child: GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
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
                          color: Colors.white.withOpacity(0.4),
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
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      u.email,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.7),
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
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        u.roleLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
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
          color: Colors.white,
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

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: CmsColors.textSecond,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            color: CmsColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
