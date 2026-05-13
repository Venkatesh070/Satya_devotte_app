// CMS — Notifications.
//
// Admins can:
//   • Send a push broadcast immediately or schedule it
//   • Browse the paginated history (filterable by status)
//   • Cancel a SCHEDULED broadcast before its send time
//
// All of these calls go through [CmsNotificationsController] which wraps
// [NotificationsRepository] (POST /notifications/send, GET /notifications,
// POST /notifications/:id/cancel).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:satya_devotte_app/features/cms/presentation/controllers/cms_notifications_controller.dart';
import 'package:satya_devotte_app/features/cms/presentation/pages/cms_shell_page.dart';
import 'package:satya_devotte_app/features/notifications/data/models/app_notification.dart';
import 'package:satya_devotte_app/features/notifications/data/models/send_notification_request.dart';

class CmsNotificationsContent extends StatefulWidget {
  const CmsNotificationsContent({super.key});

  @override
  State<CmsNotificationsContent> createState() =>
      _CmsNotificationsContentState();
}

class _CmsNotificationsContentState extends State<CmsNotificationsContent> {
  static const Color _navy = Color(0xFF1A2A4A);

  late final CmsNotificationsController _ctrl;

  // Form
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  String _audience = 'ALL';
  DateTime? _scheduledAt;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<CmsNotificationsController>();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  // ── Schedule picker ────────────────────────────────────────────
  Future<void> _pickSchedule() async {
    final now = DateTime.now();
    final base = _scheduledAt ?? now.add(const Duration(minutes: 30));
    final date = await showDatePicker(
      context: context,
      initialDate: base.isBefore(now) ? now : base,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (!mounted || date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );
    if (!mounted || time == null) return;
    final combined = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    if (!combined.isAfter(DateTime.now())) {
      _showSnack('Schedule time must be in the future.', isError: true);
      return;
    }
    setState(() => _scheduledAt = combined);
  }

  void _clearSchedule() => setState(() => _scheduledAt = null);

  // ── Send ────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (_ctrl.isSending) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final req = SendNotificationRequest(
      title: _titleCtrl.text.trim(),
      body: _bodyCtrl.text.trim(),
      audience: _audience,
      scheduledAt: _scheduledAt,
    );
    final created = await _ctrl.send(req);
    if (!mounted) return;
    if (created == null) {
      final msg = _ctrl.lastSendError ?? 'Failed to send notification.';
      _showSnack(msg, isError: true);
      return;
    }
    final isScheduled = created.status == NotificationStatus.scheduled;
    _showSnack(
      isScheduled
          ? 'Scheduled for ${_fmtFullDate(created.scheduledAt ?? _scheduledAt!)}'
          : 'Notification queued for delivery.',
    );
    _titleCtrl.clear();
    _bodyCtrl.clear();
    setState(() {
      _audience = 'ALL';
      _scheduledAt = null;
    });
  }

  void _showSnack(String message, {bool isError = false}) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? CmsColors.red : CmsColors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _fmtFullDate(DateTime dt) =>
      DateFormat('d MMM yyyy, h:mm a').format(dt.toLocal());

  // ── Build ───────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 24 : 16,
        vertical: 20,
      ),
      children: [
        _SendNotificationCard(
          formKey: _formKey,
          titleCtrl: _titleCtrl,
          bodyCtrl: _bodyCtrl,
          audience: _audience,
          onAudienceChanged: (v) {
            if (v == null) return;
            setState(() => _audience = v);
          },
          scheduledAt: _scheduledAt,
          onPickSchedule: _pickSchedule,
          onClearSchedule: _clearSchedule,
          isSending: () => _ctrl.isSending,
          onSubmit: _submit,
        ),
        const SizedBox(height: 24),
        const Text(
          'Recently Sent',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _navy,
          ),
        ),
        const SizedBox(height: 12),
        _StatusFilterBar(ctrl: _ctrl),
        const SizedBox(height: 8),
        Obx(() {
          if (_ctrl.isLoading && _ctrl.items.isEmpty) {
            return const _ListLoading();
          }
          if (_ctrl.listError != null && _ctrl.items.isEmpty) {
            return _ListError(
              message: _ctrl.listError!,
              onRetry: _ctrl.refreshList,
            );
          }
          if (_ctrl.isEmpty) {
            return const _ListEmpty();
          }
          return Column(
            children: [
              for (int i = 0; i < _ctrl.items.length; i++) ...[
                _NotificationCard(
                  notification: _ctrl.items[i],
                  isCancelling: _ctrl.isCancelling(_ctrl.items[i].id),
                  onCancel: () => _confirmCancel(_ctrl.items[i]),
                ),
                if (i != _ctrl.items.length - 1) const SizedBox(height: 10),
              ],
              const SizedBox(height: 14),
              _NotificationsPaginationBar(ctrl: _ctrl),
            ],
          );
        }),
        const SizedBox(height: 12),
      ],
    );
  }

  Future<void> _confirmCancel(AppNotification n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel scheduled broadcast?'),
        content: Text(
          '"${n.title}" will not be delivered. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: CmsColors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Cancel broadcast'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    final err = await _ctrl.cancel(n.id);
    if (!mounted) return;
    _showSnack(
      err ?? 'Notification cancelled.',
      isError: err != null,
    );
  }
}

// ════════════════════════════════════════════════════════════════
// SEND CARD
// ════════════════════════════════════════════════════════════════
class _SendNotificationCard extends StatelessWidget {
  const _SendNotificationCard({
    required this.formKey,
    required this.titleCtrl,
    required this.bodyCtrl,
    required this.audience,
    required this.onAudienceChanged,
    required this.scheduledAt,
    required this.onPickSchedule,
    required this.onClearSchedule,
    required this.isSending,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController titleCtrl;
  final TextEditingController bodyCtrl;
  final String audience;
  final ValueChanged<String?> onAudienceChanged;
  final DateTime? scheduledAt;
  final VoidCallback onPickSchedule;
  final VoidCallback onClearSchedule;
  final bool Function() isSending;
  final VoidCallback onSubmit;

  static const _navy = Color(0xFF1A2A4A);
  static const _orange = Color(0xFFE8590A);

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 720;
    final scheduleText = scheduledAt == null
        ? ''
        : DateFormat('d MMM yyyy, h:mm a').format(scheduledAt!.toLocal());
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Form(
        key: formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Send Push Notification',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _navy,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Broadcasts go out to the chosen audience via Firebase Cloud Messaging.',
              style: TextStyle(fontSize: 12, color: CmsColors.textSecond),
            ),
            const SizedBox(height: 16),
            _LabeledField(
              label: 'Title',
              child: TextFormField(
                controller: titleCtrl,
                maxLength: 120,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'e.g. Diwali is tomorrow!',
                ),
                inputFormatters: [LengthLimitingTextInputFormatter(120)],
                validator: (v) {
                  final s = (v ?? '').trim();
                  if (s.isEmpty) return 'Title is required.';
                  if (s.length > 120) return 'Max 120 characters.';
                  return null;
                },
              ),
            ),
            const SizedBox(height: 12),
            _LabeledField(
              label: 'Message',
              child: TextFormField(
                controller: bodyCtrl,
                maxLines: 4,
                minLines: 3,
                maxLength: 1000,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter notification message...',
                ),
                inputFormatters: [LengthLimitingTextInputFormatter(1000)],
                validator: (v) {
                  final s = (v ?? '').trim();
                  if (s.isEmpty) return 'Message is required.';
                  if (s.length > 1000) return 'Max 1000 characters.';
                  return null;
                },
              ),
            ),
            const SizedBox(height: 12),
            isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _audienceField()),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _scheduleField(scheduleText),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      _audienceField(),
                      const SizedBox(height: 12),
                      _scheduleField(scheduleText),
                    ],
                  ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                onPressed: isSending() ? null : onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _orange,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _orange.withOpacity(0.6),
                  disabledForegroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: isSending()
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        scheduledAt == null ? Icons.send : Icons.schedule_send,
                        size: 18,
                      ),
                label: Text(
                  isSending()
                      ? 'Sending…'
                      : scheduledAt == null
                          ? 'Send Notification'
                          : 'Schedule Notification',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _audienceField() => _LabeledField(
        label: 'Target Audience',
        child: DropdownButtonFormField<String>(
          value: audience,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          items: const [
            DropdownMenuItem(value: 'ALL', child: Text('All Users')),
            DropdownMenuItem(value: 'USERS', child: Text('Users')),
            DropdownMenuItem(value: 'ADMINS', child: Text('Admins')),
            DropdownMenuItem(value: 'SUPERADMIN', child: Text('Super Admin')),
          ],
          onChanged: onAudienceChanged,
        ),
      );

  Widget _scheduleField(String scheduleText) => _LabeledField(
        label: 'Schedule (optional)',
        child: InkWell(
          onTap: onPickSchedule,
          child: InputDecorator(
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: 'Send now',
              suffixIcon: scheduledAt == null
                  ? const Icon(Icons.calendar_today, size: 18)
                  : IconButton(
                      tooltip: 'Clear schedule',
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: onClearSchedule,
                    ),
            ),
            child: Text(
              scheduleText.isEmpty ? 'Send now' : scheduleText,
              style: TextStyle(
                fontSize: 14,
                color: scheduleText.isEmpty
                    ? CmsColors.textSecond
                    : CmsColors.textPrimary,
                fontWeight:
                    scheduleText.isEmpty ? FontWeight.w400 : FontWeight.w600,
              ),
            ),
          ),
        ),
      );
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: CmsColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════
// LIST: status filter chips
// ════════════════════════════════════════════════════════════════
class _StatusFilterBar extends StatelessWidget {
  const _StatusFilterBar({required this.ctrl});
  final CmsNotificationsController ctrl;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Obx(() {
        final active = ctrl.statusFilter;
        return Row(
          children: [
            for (final f in CmsNotificationsController.statusFilters) ...[
              _Chip(
                label: _filterLabel(f),
                isActive: f == active,
                onTap: () => ctrl.setStatusFilter(f),
              ),
              const SizedBox(width: 8),
            ],
            IconButton(
              tooltip: 'Reload',
              onPressed: ctrl.isLoading ? null : ctrl.refreshList,
              icon: ctrl.isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: CmsColors.orange,
                      ),
                    )
                  : const Icon(
                      Icons.refresh,
                      size: 18,
                      color: CmsColors.textSecond,
                    ),
            ),
          ],
        );
      }),
    );
  }

  String _filterLabel(String key) {
    switch (key) {
      case 'ALL':
        return 'All';
      case 'SENT':
        return 'Sent';
      case 'SCHEDULED':
        return 'Scheduled';
      case 'PENDING':
        return 'Pending';
      case 'SENDING':
        return 'Sending';
      case 'FAILED':
        return 'Failed';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return key;
    }
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? CmsColors.orange : CmsColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? CmsColors.orange : CmsColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isActive ? Colors.white : CmsColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// LIST: notification card
// ════════════════════════════════════════════════════════════════
class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.isCancelling,
    required this.onCancel,
  });
  final AppNotification notification;
  final bool isCancelling;
  final VoidCallback onCancel;

  static const _orange = Color(0xFFE8590A);
  static const _navy = Color(0xFF1A2A4A);

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final isScheduled = n.status == NotificationStatus.scheduled;
    final showCancel = isScheduled;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.notifications, color: _orange, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        n.title.isEmpty ? '(untitled)' : n.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: _navy,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _NotificationStatusPill(status: n.status),
                  ],
                ),
                if (n.body.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    n.body,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5, color: Colors.grey),
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 14,
                  runSpacing: 4,
                  children: [
                    _MetaPill(
                      icon: Icons.people_outline,
                      text: n.audienceLabel,
                    ),
                    if (n.totalRecipients > 0)
                      _MetaPill(
                        icon: Icons.check_circle_outline,
                        text:
                            '${n.successCount}/${n.totalRecipients} delivered',
                      ),
                    _MetaPill(
                      icon: Icons.access_time,
                      text: n.formattedTimestamp,
                    ),
                  ],
                ),
                if (showCancel) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: isCancelling ? null : onCancel,
                      icon: isCancelling
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: CmsColors.red,
                              ),
                            )
                          : const Icon(Icons.cancel_outlined, size: 16),
                      label: Text(
                        isCancelling ? 'Cancelling…' : 'Cancel',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: CmsColors.red,
                        side: const BorderSide(color: CmsColors.red),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.grey),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}

class _NotificationStatusPill extends StatelessWidget {
  const _NotificationStatusPill({required this.status});
  final NotificationStatus status;

  @override
  Widget build(BuildContext context) {
    late final Color bg;
    late final Color fg;
    late final String label;
    switch (status) {
      case NotificationStatus.sent:
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF2E7D32);
        label = 'Sent';
        break;
      case NotificationStatus.scheduled:
        bg = const Color(0xFFE3F2FD);
        fg = const Color(0xFF1565C0);
        label = 'Scheduled';
        break;
      case NotificationStatus.pending:
        bg = const Color(0xFFFFF3E0);
        fg = const Color(0xFFEF6C00);
        label = 'Pending';
        break;
      case NotificationStatus.sending:
        bg = const Color(0xFFFFF8E1);
        fg = const Color(0xFFF9A825);
        label = 'Sending';
        break;
      case NotificationStatus.failed:
        bg = const Color(0xFFFFEBEE);
        fg = const Color(0xFFC62828);
        label = 'Failed';
        break;
      case NotificationStatus.cancelled:
        bg = const Color(0xFFEEEEEE);
        fg = const Color(0xFF616161);
        label = 'Cancelled';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// LIST: pagination
// ════════════════════════════════════════════════════════════════
class _NotificationsPaginationBar extends StatelessWidget {
  const _NotificationsPaginationBar({required this.ctrl});
  final CmsNotificationsController ctrl;

  static const _pageSizes = [10, 20, 50];

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isWide = MediaQuery.of(context).size.width >= 768;
      final page = ctrl.page;
      final size = ctrl.limit;
      final tp = ctrl.totalPages;
      final totalRows = ctrl.total;
      final start = totalRows == 0 ? 0 : (page - 1) * size + 1;
      final end = (page * size).clamp(0, totalRows);

      final left = <Widget>[
        Text(
          'Showing $start–$end of $totalRows',
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
                  .map((s) =>
                      DropdownMenuItem(value: s, child: Text('$s')))
                  .toList(),
              onChanged: (v) {
                if (v != null) ctrl.setLimit(v);
              },
            ),
          ),
        ),
      ];

      final pager = <Widget>[
        _PagerBtn(
          icon: Icons.chevron_left,
          enabled: page > 1,
          onTap: ctrl.prevPage,
        ),
        for (final n in _pageRange(page, tp))
          n == -1
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    '…',
                    style: TextStyle(color: CmsColors.textSecond),
                  ),
                )
              : _PageNumberBtn(
                  number: n,
                  isActive: n == page,
                  onTap: () => ctrl.goToPage(n),
                ),
        _PagerBtn(
          icon: Icons.chevron_right,
          enabled: page < tp,
          onTap: ctrl.nextPage,
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
              ...left,
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
              children: left,
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

class _PagerBtn extends StatelessWidget {
  const _PagerBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: enabled ? CmsColors.bg : CmsColors.bg.withOpacity(0.6),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: CmsColors.border),
          ),
          child: Icon(
            icon,
            size: 18,
            color: enabled
                ? CmsColors.textPrimary
                : CmsColors.textSecond.withOpacity(0.5),
          ),
        ),
      );
}

class _PageNumberBtn extends StatelessWidget {
  const _PageNumberBtn({
    required this.number,
    required this.isActive,
    required this.onTap,
  });
  final int number;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
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
// LIST: empty / loading / error
// ════════════════════════════════════════════════════════════════
class _ListLoading extends StatelessWidget {
  const _ListLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: CircularProgressIndicator(color: CmsColors.orange),
      ),
    );
  }
}

class _ListEmpty extends StatelessWidget {
  const _ListEmpty();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CmsColors.border),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 36,
            color: CmsColors.textSecond,
          ),
          SizedBox(height: 10),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: CmsColors.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Send your first broadcast using the form above.',
            style: TextStyle(fontSize: 12, color: CmsColors.textSecond),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ListError extends StatelessWidget {
  const _ListError({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CmsColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: CmsColors.red, size: 32),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: CmsColors.textPrimary),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Try again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: CmsColors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
