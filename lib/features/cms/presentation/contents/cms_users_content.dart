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
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          decoration: BoxDecoration(
            color: CmsColors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF5F7FA)),
              headingTextStyle: const TextStyle(
                color: CmsColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              dataTextStyle: const TextStyle(
                color: CmsColors.textPrimary,
                fontSize: 13,
              ),
              columnSpacing: 20,
              horizontalMargin: 20,
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
                            style: const TextStyle(color: CmsColors.textSecond),
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
                                  onPressed: () => _showUserDetail(context, u),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Tooltip(
                                message: 'Promote to Admin',
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.star_outline,
                                    size: 18,
                                    color: CmsColors.orange,
                                  ),
                                  onPressed: () => _promoteDialog(context, u),
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
    );
  }

  void _showUserDetail(BuildContext ctx, AdminModel u) {
    showDialog<void>(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'User Profile',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Avatar(user: u, radius: 30),
            const SizedBox(height: 12),
            Text(
              u.displayName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: CmsColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              u.email,
              style: const TextStyle(color: CmsColors.textSecond, fontSize: 13),
            ),
            const SizedBox(height: 12),
            _InfoRow('Role', u.roleLabel),
            if (u.phone != null && u.phone!.isNotEmpty)
              _InfoRow('Phone', u.phone!),
            _InfoRow('Provider', _providerFromEmail(u.email)),
            if (u.createdAt != null)
              _InfoRow('Joined', _formatDate(u.createdAt!)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Close',
              style: TextStyle(color: CmsColors.textSecond),
            ),
          ),
        ],
      ),
    );
  }

  void _promoteDialog(BuildContext ctx, AdminModel u) {
    showDialog<void>(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Promote to Admin',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CmsColors.orange.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: CmsColors.orange.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  _Avatar(user: u),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          u.displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: CmsColors.textPrimary,
                          ),
                        ),
                        Text(
                          u.email,
                          style: const TextStyle(
                            fontSize: 12,
                            color: CmsColors.textSecond,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'This user will be able to add and manage poojas and festivals.',
              style: TextStyle(color: CmsColors.textSecond, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: CmsColors.textSecond),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              await Get.find<AdminController>().promoteToAdmin(u.email);
            },
            icon: const Icon(Icons.star, size: 16),
            label: const Text('Promote'),
            style: ElevatedButton.styleFrom(
              backgroundColor: CmsColors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
          ),
        ],
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
                Row(
                  children: [
                    CmsActionIcon(
                      icon: Icons.visibility_outlined,
                      color: Colors.blue,
                      onTap: () {},
                    ),
                    const SizedBox(width: 6),
                    CmsActionIcon(
                      icon: Icons.star_outline,
                      color: CmsColors.orange,
                      onTap: () {},
                    ),
                  ],
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
