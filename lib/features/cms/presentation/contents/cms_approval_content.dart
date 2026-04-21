import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/features/cms/models/pooja_model.dart';
import 'package:satya_devotte_app/features/cms/presentation/controllers/pooja_controller.dart';
import 'package:satya_devotte_app/features/cms/presentation/pages/cms_shell_page.dart';
import 'package:satya_devotte_app/features/cms/presentation/widgets/cms_shared_widgets.dart';

class CmsApprovalContent extends StatefulWidget {
  const CmsApprovalContent({super.key});

  @override
  State<CmsApprovalContent> createState() => _CmsApprovalContentState();
}

class _CmsApprovalContentState extends State<CmsApprovalContent>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final PoojaController _ctrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _ctrl = Get.find<PoojaController>();
    // Super admin approval view always needs ALL statuses regardless of rituals filter
    _ctrl.loadAllPoojas();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width >= 768;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Info banner ──────────────────────────────────────
        Container(
          margin: EdgeInsets.fromLTRB(
            isWeb ? 24 : 16,
            isWeb ? 20 : 14,
            isWeb ? 24 : 16,
            0,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFE082)),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.verified_user_outlined,
                color: Color(0xFFF9A825),
                size: 18,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Super Admin only — Approve or Reject content before it goes live to devotees.',
                  style: TextStyle(
                    color: Color(0xFF5D4037),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Tab bar ──────────────────────────────────────────
        const SizedBox(height: 16),
        Container(
          color: CmsColors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: CmsColors.orange,
            unselectedLabelColor: CmsColors.textSecond,
            indicatorColor: CmsColors.orange,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
            tabs: [
              // Pending tab — shows live badge count
              Obx(() {
                final n = _ctrl.poojas
                    .where((p) => p.status == 'Pending')
                    .length;
                return Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Pending'),
                      if (n > 0) ...[
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
                            '$n',
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
                );
              }),
              const Tab(text: 'Approved'),
              const Tab(text: 'All'),
            ],
          ),
        ),
        const Divider(height: 1, color: CmsColors.border),

        // ── Tab views ────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: Pending — approve / reject actions shown
              _ApprovalList(
                ctrl: _ctrl,
                filterStatus: 'Pending',
                showActions: true,
                emptyIcon: Icons.check_circle_outline,
                emptyTitle: 'All Caught Up!',
                emptySubtitle: 'No poojas waiting for approval',
              ),
              // Tab 2: Approved — read-only
              _ApprovalList(
                ctrl: _ctrl,
                filterStatus: 'Published',
                showActions: false,
                emptyIcon: Icons.thumb_up_alt_outlined,
                emptyTitle: 'No Approved Poojas',
                emptySubtitle: 'Approved poojas will appear here',
              ),
              // Tab 3: All — full history
              _ApprovalList(
                ctrl: _ctrl,
                filterStatus: 'All',
                showActions: false,
                emptyIcon: Icons.list_alt_outlined,
                emptyTitle: 'No Poojas Yet',
                emptySubtitle: 'All submitted poojas will appear here',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════
// LIST WIDGET — reused for all 3 tabs
// ════════════════════════════════════════════════════════════════
class _ApprovalList extends StatelessWidget {
  const _ApprovalList({
    required this.ctrl,
    required this.filterStatus,
    required this.showActions,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  final PoojaController ctrl;
  final String filterStatus;
  final bool showActions;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width >= 768;

    return Obx(() {
      // ── Loading ───────────────────────────────────────────
      if (ctrl.isLoading) {
        return const Center(
          child: CircularProgressIndicator(color: CmsColors.orange),
        );
      }

      // ── Error ─────────────────────────────────────────────
      if (ctrl.error != null && ctrl.poojas.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 36,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                ctrl.error!,
                style: const TextStyle(
                  color: CmsColors.textPrimary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              CmsPrimaryButton(
                label: 'Retry',
                icon: Icons.refresh,
                onTap: ctrl.loadAllPoojas,
              ),
            ],
          ),
        );
      }

      // ── Filter ────────────────────────────────────────────
      final list = filterStatus == 'All'
          ? ctrl.poojas
          : ctrl.poojas.where((p) => p.status == filterStatus).toList();

      // ── Empty ─────────────────────────────────────────────
      if (list.isEmpty) {
        return CmsEmptyState(
          icon: emptyIcon,
          title: emptyTitle,
          subtitle: emptySubtitle,
        );
      }

      // ── List ─────────────────────────────────────────────
      return RefreshIndicator(
        color: CmsColors.orange,
        onRefresh: ctrl.loadAllPoojas,
        child: ListView.separated(
          padding: EdgeInsets.all(isWeb ? 24 : 16),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (ctx, i) => _ApprovalCard(
            pooja: list[i],
            showActions: showActions,
            onApprove: () => _approveDialog(ctx, list[i], ctrl),
            onReject: () => _rejectDialog(ctx, list[i], ctrl),
          ),
        ),
      );
    });
  }

  // ── Approve confirmation dialog ──────────────────────────────
  void _approveDialog(
    BuildContext ctx,
    PoojaModel pooja,
    PoojaController ctrl,
  ) {
    showDialog<void>(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Approve Pooja',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: CmsColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pooja name highlight
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.withOpacity(0.2)),
              ),
              child: Text(
                pooja.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: CmsColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'This will publish the pooja and make it visible to all devotees in the app.',
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
              await ctrl.approvePooja(pooja.id);
            },
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Approve & Publish'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
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

  // ── Reject with reason dialog ────────────────────────────────
  void _rejectDialog(BuildContext ctx, PoojaModel pooja, PoojaController ctrl) {
    final reasonCtrl = TextEditingController();
    showDialog<void>(
      context: ctx,
      builder: (_) => StatefulBuilder(
        builder: (dialogCtx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Reject Pooja',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: CmsColors.textPrimary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pooja name
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.withOpacity(0.2)),
                ),
                child: Text(
                  pooja.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: CmsColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Enter reason — admin will see this and fix before resubmitting.',
                style: TextStyle(color: CmsColors.textSecond, fontSize: 13),
              ),
              const SizedBox(height: 10),
              // Reason input
              TextField(
                controller: reasonCtrl,
                maxLines: 3,
                autofocus: true,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText:
                      'e.g. Missing steps, incorrect deity, incomplete description...',
                  hintStyle: const TextStyle(
                    color: Color(0xFFAAAAAA),
                    fontSize: 12,
                  ),
                  filled: true,
                  fillColor: CmsColors.bg,
                  contentPadding: const EdgeInsets.all(12),
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
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text(
                'Cancel',
                style: TextStyle(color: CmsColors.textSecond),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final reason = reasonCtrl.text.trim();
                if (reason.isEmpty) {
                  Get.snackbar(
                    'Required',
                    'Please enter a reason',
                    snackPosition: SnackPosition.TOP,
                    backgroundColor: CmsColors.orange,
                    colorText: Colors.white,
                    margin: const EdgeInsets.all(12),
                  );
                  return;
                }
                Navigator.pop(dialogCtx);
                await ctrl.rejectPooja(pooja.id, reason);
              },
              icon: const Icon(Icons.close, size: 16),
              label: const Text('Reject'),
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
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// APPROVAL CARD
// ════════════════════════════════════════════════════════════════
class _ApprovalCard extends StatelessWidget {
  const _ApprovalCard({
    required this.pooja,
    required this.showActions,
    required this.onApprove,
    required this.onReject,
  });

  final PoojaModel pooja;
  final bool showActions;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  Color get _statusColor {
    switch (pooja.status) {
      case 'Published':
        return Colors.green;
      case 'Pending':
        return CmsColors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width >= 768;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CmsColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _statusColor.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row ────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pooja icon
              Container(
                width: isWeb ? 52 : 44,
                height: isWeb ? 52 : 44,
                decoration: BoxDecoration(
                  color: CmsColors.orange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.self_improvement,
                  color: CmsColors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),

              // Title + meta
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pooja.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: CmsColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (pooja.deity.isNotEmpty)
                          _MetaTag(Icons.person_outline, pooja.deity),
                        if (pooja.duration.isNotEmpty)
                          _MetaTag(Icons.timer_outlined, pooja.duration),
                        if (pooja.difficulty.isNotEmpty)
                          _MetaTag(Icons.signal_cellular_alt, pooja.difficulty),
                        if (pooja.category.isNotEmpty)
                          _MetaTag(Icons.category_outlined, pooja.category),
                      ],
                    ),
                  ],
                ),
              ),

              // Status badge
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _statusColor.withOpacity(0.3)),
                ),
                child: Text(
                  pooja.status,
                  style: TextStyle(
                    color: _statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          // ── Steps + Items summary ───────────────────────────
          if (pooja.steps.isNotEmpty || pooja.requiredItems.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: CmsColors.border),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.format_list_numbered,
                  size: 13,
                  color: CmsColors.textSecond,
                ),
                const SizedBox(width: 4),
                Text(
                  '${pooja.steps.length} steps',
                  style: const TextStyle(
                    fontSize: 12,
                    color: CmsColors.textSecond,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(
                  Icons.check_box_outlined,
                  size: 13,
                  color: CmsColors.textSecond,
                ),
                const SizedBox(width: 4),
                Text(
                  '${pooja.requiredItems.length} items needed',
                  style: const TextStyle(
                    fontSize: 12,
                    color: CmsColors.textSecond,
                  ),
                ),
                if (pooja.audioUrl != null) ...[
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.music_note,
                    size: 13,
                    color: CmsColors.textSecond,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Audio',
                    style: TextStyle(fontSize: 12, color: CmsColors.textSecond),
                  ),
                ],
                if (pooja.videoUrl != null) ...[
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.videocam,
                    size: 13,
                    color: CmsColors.textSecond,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Video',
                    style: TextStyle(fontSize: 12, color: CmsColors.textSecond),
                  ),
                ],
              ],
            ),
          ],

          // ── Action buttons (Pending tab only) ──────────────
          if (showActions) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: CmsColors.border),
            const SizedBox(height: 12),
            Row(
              children: [
                // Reject button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(
                      Icons.cancel_outlined,
                      size: 16,
                      color: Colors.red,
                    ),
                    label: const Text(
                      'Reject',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.red.withOpacity(0.4)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Approve button
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Approve & Publish',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Meta tag chip ─────────────────────────────────────────────────
class _MetaTag extends StatelessWidget {
  const _MetaTag(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: CmsColors.bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CmsColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: CmsColors.textSecond),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: CmsColors.textSecond),
          ),
        ],
      ),
    );
  }
}
