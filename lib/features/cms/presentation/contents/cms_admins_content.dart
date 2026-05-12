// lib/features/cms/presentation/contents/cms_admins_content.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _CmsAdminsContentState extends State<CmsAdminsContent> {
  late final AdminController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<AdminController>();
    // Reload admins every time the screen is opened so the list stays
    // in sync after promotions / demotions performed elsewhere.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ctrl.loadAdmins();
    });
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
                        onTap: _ctrl.loadAdmins,
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
                      'Loading admins...',
                      style: TextStyle(
                        color: CmsColors.textSecond,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }

            if (_ctrl.error != null && _ctrl.admins.isEmpty) {
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
                      onTap: _ctrl.loadAdmins,
                    ),
                  ],
                ),
              );
            }

            return _UserList(
              users: _ctrl.admins,
              emptyIcon: Icons.admin_panel_settings_outlined,
              emptyTitle: 'No Admins Yet',
              emptySubtitle: 'Promote a user to admin using the button above',
              onAction: (user) => _removeAdminDialog(context, user),
              actionLabel: 'Remove',
              actionColor: Colors.red,
              actionIcon: Icons.remove_moderator_outlined,
              onRefresh: _ctrl.loadAdmins,
              showPanelAccessToggle: true,
              onTogglePanelAccess: (user, value) =>
                  _ctrl.setPanelAccess(id: user.id, canLoginAdminPanel: value),
              isPanelAccessPending: _ctrl.isPanelAccessPending,
            );
          }),
        ),
      ],
    );
  }

  // ── Promote / invite admin — Super Admin API ──────────────────
  void _showPromoteDialog(BuildContext ctx) {
    final fullNameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    showDialog<void>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Promote to Admin',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: CmsColors.textPrimary,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter details for the new admin. They will receive an invitation '
                'email when possible.',
                style: TextStyle(color: CmsColors.textSecond, fontSize: 13),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: fullNameCtrl,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(fontSize: 13),
                decoration: _inviteFieldDecoration(
                  label: 'Full name',
                  hint: 'e.g. Jane Doe',
                  icon: Icons.person_outline,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(fontSize: 13),
                decoration: _inviteFieldDecoration(
                  label: 'Email',
                  hint: 'user@example.com',
                  icon: Icons.email_outlined,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                style: const TextStyle(fontSize: 13),
                decoration: _inviteFieldDecoration(
                  label: 'Phone (optional)',
                  hint: '+91 …',
                  icon: Icons.phone_outlined,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
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
                      final fullName = fullNameCtrl.text.trim();
                      final email = emailCtrl.text.trim();
                      final phoneRaw = phoneCtrl.text.trim();
                      if (fullName.isEmpty || email.isEmpty) {
                        Get.snackbar(
                          'Required',
                          'Please enter full name and email.',
                          snackPosition: SnackPosition.TOP,
                          backgroundColor: CmsColors.orangeDark,
                          colorText: Colors.white,
                          margin: const EdgeInsets.all(12),
                        );
                        return;
                      }
                      final result = await _ctrl.inviteAdmin(
                        fullName: fullName,
                        email: email,
                        phone: phoneRaw.isEmpty ? null : phoneRaw,
                      );
                      if (!dialogCtx.mounted) return;
                      if (result == null) return;

                      Navigator.pop(dialogCtx);

                      if (result.emailDelivered) {
                        showCmsSnackbar(
                          title: 'Success',
                          message:
                              'Admin created. Invitation email sent.',
                        );
                      } else if (result.passwordResetLink != null &&
                          result.passwordResetLink!.isNotEmpty) {
                        _showPasswordResetLinkDialog(
                          ctx,
                          result.passwordResetLink!,
                        );
                      } else {
                        showCmsSnackbar(
                          title: 'Success',
                          message: 'Admin created.',
                        );
                      }
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
                  : const Icon(Icons.person_add_outlined, size: 18),
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
    ).then((_) {
      fullNameCtrl.dispose();
      emailCtrl.dispose();
      phoneCtrl.dispose();
    });
  }

  void _showPasswordResetLinkDialog(BuildContext ctx, String resetLink) {
    showDialog<void>(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Invitation email not sent',
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
              'Copy this password reset link and share it securely with the new admin.',
              style: TextStyle(color: CmsColors.textSecond, fontSize: 13),
            ),
            const SizedBox(height: 12),
            SelectableText(
              resetLink,
              style: const TextStyle(fontSize: 12, color: CmsColors.textPrimary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: const Text(
              'Close',
              style: TextStyle(color: CmsColors.textSecond),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: resetLink));
              if (!dCtx.mounted) return;
              Navigator.pop(dCtx);
              showCmsSnackbar(
                title: 'Copied',
                message: 'Password reset link copied to clipboard.',
              );
            },
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copy link'),
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

  InputDecoration _inviteFieldDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 13),
      prefixIcon: Icon(icon, size: 18, color: CmsColors.textSecond),
      filled: true,
      fillColor: CmsColors.bg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
// USER LIST
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
    this.showPanelAccessToggle = false,
    this.onTogglePanelAccess,
    this.isPanelAccessPending,
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
  final bool showPanelAccessToggle;
  final Future<bool> Function(AdminModel user, bool value)? onTogglePanelAccess;
  final bool Function(String id)? isPanelAccessPending;

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
          showPanelAccessToggle: showPanelAccessToggle,
          onTogglePanelAccess: onTogglePanelAccess == null
              ? null
              : (value) => onTogglePanelAccess!(users[i], value),
          isPanelAccessPending: isPanelAccessPending == null
              ? null
              : () => isPanelAccessPending!(users[i].id),
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
    this.showPanelAccessToggle = false,
    this.onTogglePanelAccess,
    this.isPanelAccessPending,
  });

  final AdminModel user;
  final String actionLabel;
  final Color actionColor;
  final IconData actionIcon;
  final VoidCallback onAction;
  final bool showPanelAccessToggle;
  final Future<bool> Function(bool value)? onTogglePanelAccess;
  final bool Function()? isPanelAccessPending;

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

          // Active / Inactive toggle (super-admin admin-panel access).
          if (showPanelAccessToggle &&
              onTogglePanelAccess != null &&
              user.role.toLowerCase() != 'superadmin') ...[
            _PanelAccessToggle(
              user: user,
              onChanged: onTogglePanelAccess!,
              isPending: isPanelAccessPending,
            ),
            const SizedBox(width: 10),
          ],

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

// ── Active / Inactive switch for an admin ─────────────────────────
class _PanelAccessToggle extends StatelessWidget {
  const _PanelAccessToggle({
    required this.user,
    required this.onChanged,
    this.isPending,
  });

  final AdminModel user;
  final Future<bool> Function(bool value) onChanged;
  final bool Function()? isPending;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final ctrl = Get.find<AdminController>();
      // Read latest value from the controller list so the toggle stays in
      // sync with optimistic updates / refreshes.
      AdminModel? current;
      for (final a in ctrl.admins) {
        if (a.id == user.id) {
          current = a;
          break;
        }
      }
      final isActive = current?.canLoginAdminPanel ?? user.canLoginAdminPanel;
      final pending =
          isPending?.call() ?? ctrl.isPanelAccessPending(user.id);

      final activeColor = const Color(0xFF2E7D32);
      final inactiveColor = CmsColors.textSecond;
      final color = isActive ? activeColor : inactiveColor;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (pending)
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: color,
                ),
              )
            else
              Icon(
                isActive
                    ? Icons.check_circle_outline
                    : Icons.block_outlined,
                size: 14,
                color: color,
              ),
            const SizedBox(width: 6),
            Text(
              isActive ? 'Active' : 'Inactive',
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Transform.scale(
              scale: 0.75,
              child: Switch(
                value: isActive,
                onChanged: pending
                    ? null
                    : (v) {
                        // Fire and forget — controller handles errors.
                        onChanged(v);
                      },
                activeColor: Colors.white,
                activeTrackColor: activeColor,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: inactiveColor.withOpacity(0.5),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      );
    });
  }
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
