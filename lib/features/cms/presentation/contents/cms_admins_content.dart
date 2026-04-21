// lib/features/cms/presentation/contents/cms_admins_content.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/features/cms/models/admin_model.dart';
import 'package:satya_devotte_app/features/cms/presentation/controllers/admin_controller.dart';
import 'package:satya_devotte_app/features/cms/presentation/pages/cms_shell_page.dart';
import 'package:satya_devotte_app/features/cms/presentation/widgets/cms_shared_widgets.dart';

class CmsAdminsContent extends StatefulWidget {
  const CmsAdminsContent({super.key});

  @override
  State<CmsAdminsContent> createState() => _CmsAdminsContentState();
}

class _CmsAdminsContentState extends State<CmsAdminsContent>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  late final AdminController _ctrl;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _ctrl = Get.find<AdminController>();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width >= 768;

    return Column(
      children: [
        // ── Header ────────────────────────────────────────────────
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
                  hint: 'Search by name or email...',
                  onChanged: (_) {},
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
                        onTap: _ctrl.loadAll,
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
              const SizedBox(width: 10),
              // Promote button
              CmsPrimaryButton(
                label: isWeb ? 'Promote to Admin' : 'Promote',
                icon: Icons.person_add_outlined,
                onTap: () => _showPromoteDialog(context),
              ),
            ],
          ),
        ),

        // ── Tabs: Admins | All Users ──────────────────────────────
        Container(
          color: CmsColors.white,
          child: TabBar(
            controller: _tab,
            labelColor: CmsColors.orange,
            unselectedLabelColor: CmsColors.textSecond,
            indicatorColor: CmsColors.orange,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            unselectedLabelStyle: const TextStyle(fontSize: 13),
            tabs: [
              Obx(
                () => Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Admins'),
                      if (_ctrl.admins.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: CmsColors.orange,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_ctrl.admins.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const Tab(text: 'All Users'),
            ],
          ),
        ),
        const Divider(height: 1, color: CmsColors.border),

        // ── Content ───────────────────────────────────────────────
        Expanded(
          child: Obx(() {
            if (_ctrl.isLoading) {
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

            if (_ctrl.error != null &&
                _ctrl.admins.isEmpty &&
                _ctrl.regularUsers.isEmpty) {
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
                      onTap: _ctrl.loadAll,
                    ),
                  ],
                ),
              );
            }

            return TabBarView(
              controller: _tab,
              children: [
                // Tab 1: Admins list
                _UserList(
                  users: _ctrl.admins,
                  emptyIcon: Icons.admin_panel_settings_outlined,
                  emptyTitle: 'No Admins Yet',
                  emptySubtitle:
                      'Promote a user to admin using the button above',
                  onAction: (user) => _removeAdminDialog(context, user),
                  actionLabel: 'Remove',
                  actionColor: Colors.red,
                  actionIcon: Icons.remove_moderator_outlined,
                  onRefresh: _ctrl.loadAdmins,
                ),
                // Tab 2: Regular users
                _UserList(
                  users: _ctrl.regularUsers,
                  emptyIcon: Icons.people_outline,
                  emptyTitle: 'No Users',
                  emptySubtitle: 'No regular users found',
                  onAction: (user) => _promoteConfirmDialog(context, user),
                  actionLabel: 'Make Admin',
                  actionColor: CmsColors.orange,
                  actionIcon: Icons.star_outline,
                  onRefresh: _ctrl.loadRegularUsers,
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  // ── Promote by email dialog ───────────────────────────────────
  void _showPromoteDialog(BuildContext ctx) {
    final emailCtrl = TextEditingController();
    showDialog<void>(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Promote User to Admin',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: CmsColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the email address of the user you want to promote.',
              style: TextStyle(color: CmsColors.textSecond, fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: emailCtrl,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'e.g. user@example.com',
                hintStyle: const TextStyle(
                  color: Color(0xFFAAAAAA),
                  fontSize: 13,
                ),
                prefixIcon: const Icon(
                  Icons.email_outlined,
                  size: 18,
                  color: CmsColors.textSecond,
                ),
                filled: true,
                fillColor: CmsColors.bg,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: CmsColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: CmsColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: CmsColors.orange),
                ),
              ),
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
          Obx(
            () => ElevatedButton.icon(
              onPressed: _ctrl.isSubmitting
                  ? null
                  : () async {
                      final email = emailCtrl.text.trim();
                      if (email.isEmpty) {
                        Get.snackbar(
                          'Required',
                          'Please enter an email',
                          snackPosition: SnackPosition.TOP,
                          backgroundColor: CmsColors.orange,
                          colorText: Colors.white,
                          margin: const EdgeInsets.all(12),
                        );
                        return;
                      }
                      Navigator.pop(ctx);
                      await _ctrl.promoteToAdmin(email);
                    },
              icon: _ctrl.isSubmitting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.star, size: 16),
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
          ),
        ],
      ),
    );
  }

  // ── Promote from users list (confirm dialog) ──────────────────
  void _promoteConfirmDialog(BuildContext ctx, AdminModel user) {
    showDialog<void>(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Promote to Admin',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: CmsColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _UserInfoCard(user: user, color: CmsColors.orange),
            const SizedBox(height: 12),
            const Text(
              'This user will be able to add poojas and festivals that go through approval.',
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
              await _ctrl.promoteToAdmin(user.email);
            },
            icon: const Icon(Icons.star, size: 16),
            label: const Text('Promote to Admin'),
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

  // ── Remove admin role (confirm dialog) ───────────────────────
  void _removeAdminDialog(BuildContext ctx, AdminModel user) {
    showDialog<void>(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Remove Admin Role',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: CmsColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _UserInfoCard(user: user, color: Colors.red),
            const SizedBox(height: 12),
            const Text(
              'This will remove their admin access. They will become a regular user.',
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
              await _ctrl.removeAdmin(user.id);
            },
            icon: const Icon(Icons.remove_moderator, size: 16),
            label: const Text('Remove Admin'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
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
}

// ════════════════════════════════════════════════════════════════
// USER LIST — reused for both tabs
// ════════════════════════════════════════════════════════════════
class _UserList extends StatelessWidget {
  const _UserList({
    required this.users,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.onAction,
    required this.actionLabel,
    required this.actionColor,
    required this.actionIcon,
    required this.onRefresh,
  });

  final List<AdminModel> users;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;
  final ValueChanged<AdminModel> onAction;
  final String actionLabel;
  final Color actionColor;
  final IconData actionIcon;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width >= 768;

    if (users.isEmpty) {
      return CmsEmptyState(
        icon: emptyIcon,
        title: emptyTitle,
        subtitle: emptySubtitle,
      );
    }

    return RefreshIndicator(
      color: CmsColors.orange,
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: EdgeInsets.all(isWeb ? 24 : 16),
        itemCount: users.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _UserCard(
          user: users[i],
          actionLabel: actionLabel,
          actionColor: actionColor,
          actionIcon: actionIcon,
          onAction: () => onAction(users[i]),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// USER CARD
// ════════════════════════════════════════════════════════════════
class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.actionLabel,
    required this.actionColor,
    required this.actionIcon,
    required this.onAction,
  });

  final AdminModel user;
  final String actionLabel;
  final Color actionColor;
  final IconData actionIcon;
  final VoidCallback onAction;

  Color get _roleColor {
    switch (user.role.toLowerCase()) {
      case 'superadmin':
        return const Color(0xFF9C27B0);
      case 'admin':
        return CmsColors.orange;
      default:
        return CmsColors.textSecond;
    }
  }

  @override
  Widget build(BuildContext context) {
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
          // Avatar
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _roleColor.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: _roleColor.withOpacity(0.3)),
            ),
            child: user.profileImage != null
                ? ClipOval(
                    child: Image.network(
                      user.profileImage!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _initialsText(),
                    ),
                  )
                : _initialsText(),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: CmsColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: const TextStyle(
                    fontSize: 12,
                    color: CmsColors.textSecond,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    // Role badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _roleColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _roleColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        user.roleLabel,
                        style: TextStyle(
                          fontSize: 10,
                          color: _roleColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (user.phone != null && user.phone!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.phone_outlined,
                            size: 11,
                            color: CmsColors.textSecond,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            user.phone!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: CmsColors.textSecond,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Action button
          GestureDetector(
            onTap: onAction,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: actionColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: actionColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(actionIcon, size: 14, color: actionColor),
                  const SizedBox(width: 5),
                  Text(
                    actionLabel,
                    style: TextStyle(
                      color: actionColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _initialsText() => Center(
    child: Text(
      user.initials,
      style: TextStyle(
        color: _roleColor,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

// ── User info card shown inside dialogs ───────────────────────────
class _UserInfoCard extends StatelessWidget {
  const _UserInfoCard({required this.user, required this.color});
  final AdminModel user;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withOpacity(0.06),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: color.withOpacity(0.15),
          child: Text(
            user.initials,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.displayName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: CmsColors.textPrimary,
                ),
              ),
              Text(
                user.email,
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
  );
}
