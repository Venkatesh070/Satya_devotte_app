// lib/features/cms/presentation/contents/cms_admins_content.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class CmsAdminsContent extends StatefulWidget {
  const CmsAdminsContent({super.key});

  @override
  State<CmsAdminsContent> createState() => _CmsAdminsContentState();
}

class _CmsAdminsContentState extends State<CmsAdminsContent> {
  late final AdminController _ctrl;
  final ScrollController _listScrollController = ScrollController();
  late final TextEditingController _searchCtrl;
  late final CmsSearchScheduler _searchScheduler;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<AdminController>();
    _searchCtrl = TextEditingController(text: _ctrl.adminsSearch);
    _searchScheduler = CmsSearchScheduler(
      onSearch: _ctrl.setAdminsSearch,
    );
    // Reload when this tab is shown; skip full-screen loading if list exists.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _ctrl.loadAdmins(showLoadingIndicator: _ctrl.admins.isEmpty);
      }
    });
  }

  @override
  void dispose() {
    _searchScheduler.dispose();
    _searchCtrl.dispose();
    _listScrollController.dispose();
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
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (value) {
                      _searchScheduler.onQueryChanged(value);
                      setState(() {});
                    },
                    onSubmitted: _searchScheduler.searchNow,
                    style: const TextStyle(
                      fontSize: 13,
                      color: CmsColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search by name or email...',
                      hintStyle: const TextStyle(
                        color: Color(0xFFAAAAAA),
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        size: 16,
                        color: Color(0xFFAAAAAA),
                      ),
                      suffixIcon: _searchCtrl.text.isEmpty
                          ? null
                          : IconButton(
                              style: IconButton.styleFrom().copyWith(
                                mouseCursor: _cmsButtonClickCursor,
                              ),
                              icon: const Icon(Icons.close, size: 16),
                              onPressed: () {
                                _searchCtrl.clear();
                                _searchScheduler.searchNow('');
                                setState(() {});
                              },
                            ),
                      filled: true,
                      fillColor: CmsColors.bg,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: CmsColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: CmsColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: CmsColors.orange),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Obx(
                () => _ctrl.isLoadingAdmins
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: CmsColors.orange,
                        ),
                      )
                    : _cmsClickable(
                        onTap: () =>
                            _ctrl.loadAdmins(showLoadingIndicator: false),
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
                label: isWeb ? 'Create Admin' : 'Create',
                icon: Icons.person_add_outlined,
                onTap: () => _showPromoteDialog(context),
              ),
            ],
          ),
        ),

        const Divider(height: 1, color: CmsColors.border),

        // ── Content ───────────────────────────────────────────────
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: Obx(() {
                  if (_ctrl.isLoadingAdmins && _ctrl.admins.isEmpty) {
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
                    scrollController: _listScrollController,
                    users: _ctrl.admins,
                    emptyIcon: Icons.admin_panel_settings_outlined,
                    emptyTitle: _ctrl.adminsSearch.trim().isEmpty
                        ? 'No Admins Yet'
                        : 'No matching admins',
                    emptySubtitle: _ctrl.adminsSearch.trim().isEmpty
                        ? 'Promote a user to admin using the button above'
                        : 'Try a different name or email',
                    onAction: (user) => _removeAdminDialog(context, user),
                    actionLabel: 'Remove',
                    actionColor: Colors.red,
                    actionIcon: Icons.remove_moderator_outlined,
                    onRefresh: () =>
                        _ctrl.loadAdmins(showLoadingIndicator: false),
                    showPanelAccessToggle: true,
                    onTogglePanelAccess: (user, value) => _ctrl.setPanelAccess(
                      id: user.id,
                      canLoginAdminPanel: value,
                    ),
                    isPanelAccessPending: _ctrl.isPanelAccessPending,
                    onResendPasswordReset: (user) =>
                        _resendPasswordResetLink(context, user),
                    isPasswordResetPending: _ctrl.isPasswordResetPending,
                  );
                }),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  isWeb ? 24 : 16,
                  0,
                  isWeb ? 24 : 16,
                  12,
                ),
                child: _AdminsPaginationBar(ctrl: _ctrl),
              ),
            ],
          ),
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
          'Create Admin',
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
            style: TextButton.styleFrom().copyWith(
              mouseCursor: _cmsButtonClickCursor,
            ),
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
              label: const Text('Create'),
              style: ElevatedButton.styleFrom(
                backgroundColor: CmsColors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ).copyWith(mouseCursor: _cmsButtonClickCursor),
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

  Future<void> _resendPasswordResetLink(
    BuildContext ctx,
    AdminModel user,
  ) async {
    final link = await _ctrl.resendPasswordResetLink(user.id);
    if (!ctx.mounted) return;
    if (link == null || link.isEmpty) return;

    _showPasswordResetLinkDialog(
      ctx,
      link,
      title: 'Password reset link',
      subtitle:
          'Copy this link and share it securely with ${user.displayName}.',
    );
  }

  void _showPasswordResetLinkDialog(
    BuildContext ctx,
    String resetLink, {
    String title = 'Invitation email sent',
    String subtitle =
        'Copy this password reset link and share it securely with the new admin.',
  }) {
    showDialog<void>(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: CmsColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subtitle,
              style: const TextStyle(color: CmsColors.textSecond, fontSize: 13),
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
            style: TextButton.styleFrom().copyWith(
              mouseCursor: _cmsButtonClickCursor,
            ),
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
            ).copyWith(mouseCursor: _cmsButtonClickCursor),
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
            style: TextButton.styleFrom().copyWith(
              mouseCursor: _cmsButtonClickCursor,
            ),
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
            ).copyWith(mouseCursor: _cmsButtonClickCursor),
          ),
        ],
      ),
    );
  }
}

class _AdminsPaginationBar extends StatelessWidget {
  const _AdminsPaginationBar({required this.ctrl});
  final AdminController ctrl;

  static const _pageSizes = [10, 20, 50, 100];

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isWide = MediaQuery.of(context).size.width >= 768;
      final page = ctrl.adminsPage;
      final size = ctrl.adminsPageSize;
      final totalPages = ctrl.adminsTotalPages;
      final totalRows = ctrl.adminsTotal;
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
              value: _pageSizes.contains(size) ? size : 20,
              isDense: true,
              style: const TextStyle(
                fontSize: 12,
                color: CmsColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              items: _pageSizes
                  .map((s) => DropdownMenuItem(value: s, child: Text('$s')))
                  .toList(),
              onChanged: ctrl.isLoadingAdmins
                  ? null
                  : (v) {
                      if (v != null) {
                        ctrl.setAdminsPageSize(v);
                      }
                    },
            ),
          ),
        ),
      ];

      final pager = <Widget>[
        _AdminsPagerBtn(
          icon: Icons.chevron_left,
          enabled: page > 1 && !ctrl.isLoadingAdmins,
          onTap: () => ctrl.setAdminsPage(page - 1),
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
              : _AdminsPageNumberBtn(
                  number: n,
                  isActive: n == page,
                  onTap: () => ctrl.setAdminsPage(n),
                ),
        _AdminsPagerBtn(
          icon: Icons.chevron_right,
          enabled: page < totalPages && !ctrl.isLoadingAdmins,
          onTap: () => ctrl.setAdminsPage(page + 1),
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

class _AdminsPagerBtn extends StatelessWidget {
  const _AdminsPagerBtn({
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

class _AdminsPageNumberBtn extends StatelessWidget {
  const _AdminsPageNumberBtn({
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
              color: isActive ? Colors.white : CmsColors.textPrimary,
            ),
          ),
        ),
      );
}

// ════════════════════════════════════════════════════════════════
// USER LIST
// ════════════════════════════════════════════════════════════════
class _UserList extends StatelessWidget {
  const _UserList({
    required this.scrollController,
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
    this.onResendPasswordReset,
    this.isPasswordResetPending,
  });

  final ScrollController scrollController;
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
  final Future<void> Function(AdminModel user)? onResendPasswordReset;
  final bool Function(String id)? isPasswordResetPending;

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
        controller: scrollController,
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
          onResendPasswordReset: onResendPasswordReset == null
              ? null
              : () => onResendPasswordReset!(users[i]),
          isPasswordResetPending: isPasswordResetPending == null
              ? null
              : () => isPasswordResetPending!(users[i].id),
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
    this.onResendPasswordReset,
    this.isPasswordResetPending,
  });

  final AdminModel user;
  final String actionLabel;
  final Color actionColor;
  final IconData actionIcon;
  final VoidCallback onAction;
  final bool showPanelAccessToggle;
  final Future<bool> Function(bool value)? onTogglePanelAccess;
  final bool Function()? isPanelAccessPending;
  final Future<void> Function()? onResendPasswordReset;
  final bool Function()? isPasswordResetPending;

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
    final isWeb = MediaQuery.of(context).size.width >= 768;

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

          if (onResendPasswordReset != null &&
              user.role.toLowerCase() != 'superadmin')
            Obx(() {
              final resendPending = isPasswordResetPending?.call() ?? false;
              final ctrl = Get.find<AdminController>();
              AdminModel? current;
              for (final a in ctrl.admins) {
                if (a.id == user.id) {
                  current = a;
                  break;
                }
              }
              final isActive =
                  current?.canLoginAdminPanel ?? user.canLoginAdminPanel;
              final canResend = isActive && !resendPending;
              final accent =
                  isActive ? CmsColors.orange : CmsColors.textSecond;

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Tooltip(
                    message: isActive
                        ? 'Resend password reset link'
                        : 'Cannot resend reset link for inactive admins',
                    child: MouseRegion(
                      cursor: canResend
                          ? SystemMouseCursors.click
                          : SystemMouseCursors.basic,
                      child: GestureDetector(
                        onTap: canResend ? onResendPasswordReset : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withOpacity(isActive ? 0.08 : 0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: accent.withOpacity(isActive ? 0.3 : 0.2),
                            ),
                          ),
                          child: resendPending
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: CmsColors.orange,
                                  ),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.link_outlined,
                                      size: 14,
                                      color: accent,
                                    ),
                                    if (isWeb) ...[
                                      const SizedBox(width: 5),
                                      Text(
                                        'Resend Password reset link',
                                        style: TextStyle(
                                          color: accent,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              );
            }),

          // Action button
          _cmsClickable(
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
