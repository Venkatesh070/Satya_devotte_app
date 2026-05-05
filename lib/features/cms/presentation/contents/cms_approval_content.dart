import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/core/models/festival_model.dart';
import 'package:satya_devotte_app/features/cms/models/pooja_model.dart';
import 'package:satya_devotte_app/features/cms/presentation/controllers/festival_controller.dart';
import 'package:satya_devotte_app/features/cms/presentation/controllers/pooja_controller.dart';
import 'package:satya_devotte_app/features/cms/presentation/pages/cms_shell_page.dart';
import 'package:satya_devotte_app/features/cms/models/deity_model.dart';
import 'package:satya_devotte_app/features/cms/presentation/controllers/deity_controller.dart';
import 'package:satya_devotte_app/features/cms/presentation/widgets/cms_shared_widgets.dart';

class CmsApprovalContent extends StatefulWidget {
  const CmsApprovalContent({super.key});

  @override
  State<CmsApprovalContent> createState() => _CmsApprovalContentState();
}

class _CmsApprovalContentState extends State<CmsApprovalContent>
    with SingleTickerProviderStateMixin {
  // Top-level tabs: Poojas | Festivals | Deities
  late final TabController _tabController;
  late final PoojaController _poojaCtrl;
  late final FestivalController _festivalCtrl;
  late final DeityController _deityCtrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _poojaCtrl = Get.find<PoojaController>();
    _festivalCtrl = Get.find<FestivalController>();
    _deityCtrl = Get.find<DeityController>();
    // Load all items for super admin
    _poojaCtrl.loadAllPoojas();
    _festivalCtrl.loadFestivals();
    _deityCtrl.loadDeities();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width >= 768;

    return Container(
      color: CmsColors.bg,
      child: Column(
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

          // ── Top tabs: Poojas | Festivals | Deities ───────────
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
                fontSize: 14,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              tabs: [
                // Poojas tab with pending badge
                Obx(() {
                  final n = _poojaCtrl.poojas
                      .where((p) => p.status == 'Pending')
                      .length;
                  return Tab(
                    child: _TabLabel(label: 'Poojas', count: n),
                  );
                }),
                // Festivals tab with pending badge
                Obx(() {
                  final n = _festivalCtrl.festivals
                      .where((f) => f.status == 'Pending')
                      .length;
                  return Tab(
                    child: _TabLabel(label: 'Festivals', count: n),
                  );
                }),
                // Deities tab with pending badge
                Obx(() {
                  final n = _deityCtrl.deities
                      .where((d) => d.status == 'Pending')
                      .length;
                  return Tab(
                    child: _TabLabel(label: 'Deities', count: n),
                  );
                }),
              ],
            ),
          ),
          const Divider(height: 1, color: CmsColors.border),

          // ── Tab views ────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Poojas approval
                _PoojaApprovalSection(ctrl: _poojaCtrl),
                // Tab 2: Festivals approval
                _FestivalApprovalSection(ctrl: _festivalCtrl),
                // Tab 3: Deities approval
                _DeityApprovalSection(ctrl: _deityCtrl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tab label with count badge ────────────────────────────────────
class _TabLabel extends StatelessWidget {
  const _TabLabel({required this.label, required this.count});
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(label),
      if (count > 0) ...[
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: CmsColors.orange,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ],
  );
}

// ════════════════════════════════════════════════════════════════
// POOJAS APPROVAL SECTION — 3 sub-tabs: Pending | Approved | All
// ════════════════════════════════════════════════════════════════
class _PoojaApprovalSection extends StatefulWidget {
  const _PoojaApprovalSection({required this.ctrl});
  final PoojaController ctrl;

  @override
  State<_PoojaApprovalSection> createState() => _PoojaApprovalSectionState();
}

class _PoojaApprovalSectionState extends State<_PoojaApprovalSection>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Sub-tabs
        Container(
          color: CmsColors.bg,
          child: TabBar(
            controller: _tab,
            labelColor: CmsColors.orange,
            unselectedLabelColor: CmsColors.textSecond,
            indicatorColor: CmsColors.orange,
            indicatorWeight: 2,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            tabs: const [
              Tab(text: 'Pending'),
              Tab(text: 'Approved'),
              Tab(text: 'All'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              _PoojaList(
                ctrl: widget.ctrl,
                filter: 'Pending',
                showActions: true,
              ),
              _PoojaList(
                ctrl: widget.ctrl,
                filter: 'Published',
                showActions: false,
              ),
              _PoojaList(ctrl: widget.ctrl, filter: 'All', showActions: false),
            ],
          ),
        ),
      ],
    );
  }
}

class _PoojaList extends StatelessWidget {
  const _PoojaList({
    required this.ctrl,
    required this.filter,
    required this.showActions,
  });
  final PoojaController ctrl;
  final String filter;
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width >= 768;
    return Obx(() {
      if (ctrl.isLoading) {
        return const Center(
          child: CircularProgressIndicator(color: CmsColors.orange),
        );
      }
      final list = filter == 'All'
          ? ctrl.poojas
          : ctrl.poojas.where((p) => p.status == filter).toList();

      if (list.isEmpty) {
        return CmsEmptyState(
          icon: Icons.self_improvement_outlined,
          title: filter == 'All' ? 'No Poojas' : 'No $filter Poojas',
          subtitle: filter == 'Pending'
              ? 'All caught up! No poojas waiting.'
              : 'Nothing here yet.',
        );
      }

      return RefreshIndicator(
        color: CmsColors.orange,
        onRefresh: ctrl.loadAllPoojas,
        child: ListView.separated(
          padding: EdgeInsets.all(isWeb ? 20 : 14),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (ctx, i) => _PoojaApprovalCard(
            pooja: list[i],
            showActions: showActions,
            onApprove: () => _confirmApprove(ctx, list[i], ctrl),
            onReject: () => _rejectDialog(ctx, list[i], ctrl),
          ),
        ),
      );
    });
  }

  void _confirmApprove(BuildContext ctx, PoojaModel p, PoojaController ctrl) {
    showDialog<void>(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          'Approve Pooja',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.withOpacity(0.2)),
              ),
              child: Text(
                p.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: CmsColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'This will publish the pooja to all devotees.',
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
              await ctrl.approvePooja(p.id);
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

  void _rejectDialog(BuildContext ctx, PoojaModel p, PoojaController ctrl) {
    final reasonCtrl = TextEditingController();
    showDialog<void>(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          'Reject Pooja',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.withOpacity(0.2)),
              ),
              child: Text(
                p.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: CmsColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Reason *',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: CmsColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              autofocus: true,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'e.g. Missing steps, incorrect deity...',
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
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: CmsColors.textSecond),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              if (reasonCtrl.text.trim().isEmpty) {
                showCmsSnackbar(
                  title: 'Required',
                  message: 'Please enter a reason',
                  isError: true,
                );
                return;
              }
              Navigator.pop(ctx);
              await ctrl.rejectPooja(p.id, reasonCtrl.text.trim());
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
    );
  }
}

// ════════════════════════════════════════════════════════════════
// FESTIVALS APPROVAL SECTION
// ════════════════════════════════════════════════════════════════
class _FestivalApprovalSection extends StatefulWidget {
  const _FestivalApprovalSection({required this.ctrl});
  final FestivalController ctrl;

  @override
  State<_FestivalApprovalSection> createState() =>
      _FestivalApprovalSectionState();
}

class _FestivalApprovalSectionState extends State<_FestivalApprovalSection>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: CmsColors.bg,
          child: TabBar(
            controller: _tab,
            labelColor: CmsColors.orange,
            unselectedLabelColor: CmsColors.textSecond,
            indicatorColor: CmsColors.orange,
            indicatorWeight: 2,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            tabs: const [
              Tab(text: 'Pending'),
              Tab(text: 'Approved'),
              Tab(text: 'All'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              _FestivalList(
                ctrl: widget.ctrl,
                filter: 'Pending',
                showActions: true,
              ),
              _FestivalList(
                ctrl: widget.ctrl,
                filter: 'Approved',
                showActions: false,
              ),
              _FestivalList(
                ctrl: widget.ctrl,
                filter: 'All',
                showActions: false,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FestivalList extends StatelessWidget {
  const _FestivalList({
    required this.ctrl,
    required this.filter,
    required this.showActions,
  });
  final FestivalController ctrl;
  final String filter;
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width >= 768;
    return Obx(() {
      if (ctrl.isLoading) {
        return const Center(
          child: CircularProgressIndicator(color: CmsColors.orange),
        );
      }
      final list = filter == 'All'
          ? ctrl.festivals
          : ctrl.festivals.where((f) => f.status == filter).toList();

      if (list.isEmpty) {
        return CmsEmptyState(
          icon: Icons.celebration_outlined,
          title: filter == 'All' ? 'No Festivals' : 'No $filter Festivals',
          subtitle: filter == 'Pending'
              ? 'All caught up! No festivals waiting.'
              : 'Nothing here yet.',
        );
      }

      return RefreshIndicator(
        color: CmsColors.orange,
        onRefresh: ctrl.loadFestivals,
        child: ListView.separated(
          padding: EdgeInsets.all(isWeb ? 20 : 14),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (ctx, i) => _FestivalApprovalCard(
            festival: list[i],
            showActions: showActions,
            onApprove: () => _confirmApprove(ctx, list[i], ctrl),
            onReject: () => _rejectDialog(ctx, list[i], ctrl),
          ),
        ),
      );
    });
  }

  void _confirmApprove(
    BuildContext ctx,
    FestivalModel f,
    FestivalController ctrl,
  ) {
    showDialog<void>(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          'Approve Festival',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.withOpacity(0.2)),
              ),
              child: Text(
                f.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: CmsColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'This will publish the festival to all devotees.',
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
              await ctrl.approveFestival(f.id);
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

  void _rejectDialog(
    BuildContext ctx,
    FestivalModel f,
    FestivalController ctrl,
  ) {
    final reasonCtrl = TextEditingController();
    showDialog<void>(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          'Reject Festival',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.withOpacity(0.2)),
              ),
              child: Text(
                f.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: CmsColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Reason *',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: CmsColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              autofocus: true,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'e.g. Wrong date, missing description...',
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
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: CmsColors.textSecond),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              if (reasonCtrl.text.trim().isEmpty) {
                showCmsSnackbar(
                  title: 'Required',
                  message: 'Please enter a reason',
                  isError: true,
                );
                return;
              }
              Navigator.pop(ctx);
              await ctrl.rejectFestival(f.id, reasonCtrl.text.trim());
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
    );
  }
}

// ════════════════════════════════════════════════════════════════
// POOJA APPROVAL CARD
// ════════════════════════════════════════════════════════════════
class _PoojaApprovalCard extends StatelessWidget {
  const _PoojaApprovalCard({
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
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pooja.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: CmsColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${pooja.deity}  •  ${pooja.difficulty}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: CmsColors.textSecond,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
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
          if (showActions) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: CmsColors.border),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(
                      Icons.cancel_outlined,
                      size: 15,
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
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: BorderSide(color: Colors.red.withOpacity(0.4)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(
                      Icons.check_circle_outline,
                      size: 15,
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
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
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

// ════════════════════════════════════════════════════════════════
// FESTIVAL APPROVAL CARD
// ════════════════════════════════════════════════════════════════
class _FestivalApprovalCard extends StatelessWidget {
  const _FestivalApprovalCard({
    required this.festival,
    required this.showActions,
    required this.onApprove,
    required this.onReject,
  });
  final FestivalModel festival;
  final bool showActions;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  Color get _statusColor {
    switch (festival.status) {
      case 'Approved':
        return Colors.green;
      case 'Pending':
        return CmsColors.orange;
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
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
          Row(
            children: [
              // Date badge
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: CmsColors.orange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      festival.displayDay,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: CmsColors.orange,
                      ),
                    ),
                    Text(
                      festival.displayMonth,
                      style: const TextStyle(
                        fontSize: 9,
                        color: CmsColors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      festival.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: CmsColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${festival.category}  •  ${festival.locationDisplay}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: CmsColors.textSecond,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _statusColor.withOpacity(0.3)),
                ),
                child: Text(
                  festival.status,
                  style: TextStyle(
                    color: _statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (showActions) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: CmsColors.border),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(
                      Icons.cancel_outlined,
                      size: 15,
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
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: BorderSide(color: Colors.red.withOpacity(0.4)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(
                      Icons.check_circle_outline,
                      size: 15,
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
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
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

// ════════════════════════════════════════════════════════════════
// DEITIES APPROVAL SECTION
// ════════════════════════════════════════════════════════════════
class _DeityApprovalSection extends StatefulWidget {
  const _DeityApprovalSection({required this.ctrl});
  final DeityController ctrl;

  @override
  State<_DeityApprovalSection> createState() => _DeityApprovalSectionState();
}

class _DeityApprovalSectionState extends State<_DeityApprovalSection>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: CmsColors.bg,
          child: TabBar(
            controller: _tab,
            labelColor: CmsColors.orange,
            unselectedLabelColor: CmsColors.textSecond,
            indicatorColor: CmsColors.orange,
            indicatorWeight: 2,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            tabs: const [
              Tab(text: 'Pending'),
              Tab(text: 'Approved'),
              Tab(text: 'All'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              _DeityList(
                ctrl: widget.ctrl,
                filter: 'Pending',
                showActions: true,
              ),
              _DeityList(
                ctrl: widget.ctrl,
                filter: 'Approved',
                showActions: false,
              ),
              _DeityList(ctrl: widget.ctrl, filter: 'All', showActions: false),
            ],
          ),
        ),
      ],
    );
  }
}

class _DeityList extends StatelessWidget {
  const _DeityList({
    required this.ctrl,
    required this.filter,
    required this.showActions,
  });
  final DeityController ctrl;
  final String filter;
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width >= 768;
    return Obx(() {
      if (ctrl.isLoading) {
        return const Center(
          child: CircularProgressIndicator(color: CmsColors.orange),
        );
      }
      final list = filter == 'All'
          ? ctrl.deities
          : ctrl.deities.where((d) => d.status == filter).toList();

      if (list.isEmpty) {
        return CmsEmptyState(
          icon: Icons.auto_awesome_outlined,
          title: filter == 'All' ? 'No Deities' : 'No $filter Deities',
          subtitle: filter == 'Pending'
              ? 'All caught up! No deities waiting.'
              : 'Nothing here yet.',
        );
      }

      return RefreshIndicator(
        color: CmsColors.orange,
        onRefresh: () => ctrl.loadDeities(),
        child: ListView.separated(
          padding: EdgeInsets.all(isWeb ? 20 : 14),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (ctx, i) => _DeityApprovalCard(
            deity: list[i],
            showActions: showActions,
            onApprove: () => _confirmApprove(ctx, list[i], ctrl),
            onReject: () => _confirmReject(ctx, list[i], ctrl),
          ),
        ),
      );
    });
  }

  void _confirmApprove(BuildContext ctx, DeityModel d, DeityController ctrl) {
    showDialog<void>(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          'Approve Deity',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.withOpacity(0.2)),
              ),
              child: Text(
                d.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: CmsColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'This will publish the deity profile to all devotees.',
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
              await ctrl.approveDeity(d.id);
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

  void _confirmReject(BuildContext ctx, DeityModel d, DeityController ctrl) {
    showDialog<void>(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          'Reject Deity',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.withOpacity(0.2)),
              ),
              child: Text(
                d.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: CmsColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Are you sure you want to reject this deity profile?',
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
              await ctrl.rejectDeity(d.id);
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
    );
  }
}

class _DeityApprovalCard extends StatelessWidget {
  const _DeityApprovalCard({
    required this.deity,
    required this.showActions,
    required this.onApprove,
    required this.onReject,
  });
  final DeityModel deity;
  final bool showActions;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  Color get _statusColor {
    switch (deity.status) {
      case 'Approved':
        return Colors.green;
      case 'Pending':
        return CmsColors.orange;
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
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
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: CmsColors.orange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: CmsColors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deity.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: CmsColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      deity.title,
                      style: const TextStyle(
                        fontSize: 12,
                        color: CmsColors.textSecond,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _statusColor.withOpacity(0.3)),
                ),
                child: Text(
                  deity.status,
                  style: TextStyle(
                    color: _statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (showActions) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: CmsColors.border),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(
                      Icons.cancel_outlined,
                      size: 15,
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
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: BorderSide(color: Colors.red.withOpacity(0.4)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(
                      Icons.check_circle_outline,
                      size: 15,
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
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
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
