import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/core/services/media_upload_service.dart';
import 'package:satya_devotte_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:satya_devotte_app/core/models/festival_model.dart';
import 'package:satya_devotte_app/features/cms/models/pooja_model.dart';
import 'package:satya_devotte_app/features/cms/presentation/controllers/festival_controller.dart';
import 'package:satya_devotte_app/features/cms/presentation/controllers/pooja_controller.dart';
import 'package:satya_devotte_app/core/utils/cms_search_scheduler.dart';
import 'package:satya_devotte_app/features/cms/presentation/pages/cms_shell_page.dart';
import 'package:satya_devotte_app/features/cms/presentation/widgets/cms_shared_widgets.dart';
import 'package:satya_devotte_app/features/cms/presentation/widgets/cms_rich_text_field.dart';
import 'package:satya_devotte_app/features/cms/presentation/widgets/cms_upload_box.dart';

Widget _cmsClickable({
  required VoidCallback onTap,
  required Widget child,
  HitTestBehavior behavior = HitTestBehavior.deferToChild,
}) {
  return MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(onTap: onTap, behavior: behavior, child: child),
  );
}

const _cmsButtonClickCursor = WidgetStatePropertyAll<MouseCursor>(
  SystemMouseCursors.click,
);

// ════════════════════════════════════════════════════════════════
// CMS RITUALS CONTENT — main widget
// Uses the real PoojaController registered in InitialBinding
// (see: config/bindings/initial_binding.dart)
// ════════════════════════════════════════════════════════════════
class CmsRitualsContent extends StatefulWidget {
  const CmsRitualsContent({super.key});

  @override
  State<CmsRitualsContent> createState() => _CmsRitualsContentState();
}

class _CmsRitualsContentState extends State<CmsRitualsContent> {
  final PoojaController _controller = Get.find<PoojaController>();
  final FestivalController _festivalController = Get.find<FestivalController>();
  bool _showAddForm = false;
  PoojaModel? _editingPooja;

  void _openAddForm() {
    if (!mounted) return;
    _festivalController.loadFestivals();
    setState(() {
      _editingPooja = null;
      _showAddForm = true;
    });
  }

  @override
  void initState() {
    super.initState();
    // Always reload with correct filter when entering Manage Poojas.
    // This clears any stale data left by loadAllPoojas() from the Approvals tab.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller.resetAndLoad();
      if (Get.currentRoute == AppRoutes.cmsPujaCreate ||
          Get.currentRoute == AppRoutes.cmsRitualCreate) {
        _openAddForm();
      }
    });
    CmsShellNavigation.openAddPujaTick.addListener(_openAddForm);
  }

  @override
  void dispose() {
    CmsShellNavigation.openAddPujaTick.removeListener(_openAddForm);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showAddForm) {
      return Container(
        color: CmsColors.bg,
        child: _PoojaForm(
          pooja: _editingPooja,
          controller: _controller,
          onCancel: () => setState(() {
            _showAddForm = false;
            _editingPooja = null;
          }),
          onSaved: () {
            _controller.setFilter('All');
            _controller.loadPoojas(); // reload fresh from server
            setState(() {
              _showAddForm = false;
              _editingPooja = null;
            });
          },
        ),
      );
    }
    return Container(
      color: CmsColors.bg,
      child: _PoojaList(
        controller: _controller,
        onAdd: () {
          _festivalController.loadFestivals();
          setState(() {
            _editingPooja = null;
            _showAddForm = true;
          });
        },
        onEdit: (p) => setState(() {
          _editingPooja = p;
          _showAddForm = true;
        }),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// POOJA LIST
// ════════════════════════════════════════════════════════════════
class _PoojaList extends StatefulWidget {
  const _PoojaList({
    required this.controller,
    required this.onAdd,
    required this.onEdit,
  });
  final PoojaController controller;
  final VoidCallback onAdd;
  final ValueChanged<PoojaModel> onEdit;

  @override
  State<_PoojaList> createState() => _PoojaListState();
}

class _PoojaListState extends State<_PoojaList> {
  late final CmsSearchScheduler _searchScheduler;

  @override
  void initState() {
    super.initState();
    _searchScheduler = CmsSearchScheduler(onSearch: widget.controller.setSearch);
  }

  @override
  void dispose() {
    _searchScheduler.dispose();
    super.dispose();
  }

  PoojaController get controller => widget.controller;
  VoidCallback get onAdd => widget.onAdd;
  ValueChanged<PoojaModel> get onEdit => widget.onEdit;

  static const _filters = [
    'All',
    'Approved',
    'Pending',
    'Queued',
    'Draft',
    'Rejected',
  ];

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width >= 768;

    return Column(
      children: [
        // ── SuperAdmin banner ─────────────────────────────────
        Obx(() {
          final isSA = Get.find<AuthController>().isSuperAdmin;
          if (!isSA) return const SizedBox.shrink();
          return Container(
            margin: EdgeInsets.fromLTRB(
              isWeb ? 24 : 16,
              12,
              isWeb ? 24 : 16,
              0,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFFE082)),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  color: Color(0xFFF9A825),
                  size: 15,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Super Admin — Pending pujas show Approve & Reject buttons directly on the card.',
                    style: TextStyle(
                      color: Color(0xFF5D4037),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),

        // ── Toolbar ──────────────────────────────────────────
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
                  hint: 'Search pujas...',
                  onChanged: _searchScheduler.onQueryChanged,
                ),
              ),
              const SizedBox(width: 12),
              Obx(
                () => controller.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: CmsColors.orange,
                        ),
                      )
                    : _cmsClickable(
                        onTap: controller.loadPoojas,
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
              CmsPrimaryButton(
                label: isWeb ? 'Add New Puja' : 'Add',
                icon: Icons.add,
                onTap: onAdd,
              ),
            ],
          ),
        ),

        // ── Filter tabs ──────────────────────────────────────
        Container(
          color: CmsColors.white,
          padding: EdgeInsets.only(left: isWeb ? 24 : 16, bottom: 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Obx(
              () => Row(
                children: _filters.map((f) {
                  final isSel = controller.filter == f;
                  return _cmsClickable(
                    onTap: () => controller.setFilter(f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSel ? CmsColors.orange : CmsColors.bg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSel ? CmsColors.orange : CmsColors.border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            f,
                            style: TextStyle(
                              color: isSel
                                  ? Colors.white
                                  : CmsColors.textSecond,
                              fontSize: 12,
                              fontWeight: isSel
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                          if (f == 'Pending' &&
                              controller.pendingCount > 0) ...[
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: isSel
                                    ? Colors.white.withOpacity(0.3)
                                    : CmsColors.orange,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${controller.pendingCount}',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                          if (f == 'Queued' && controller.queuedCount > 0) ...[
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: isSel
                                    ? Colors.white.withOpacity(0.3)
                                    : CmsColors.orange,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${controller.queuedCount}',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),

        const Divider(height: 1, color: CmsColors.border),

        // ── Content ──────────────────────────────────────────
        Expanded(
          child: Obx(() {
            if (controller.isLoading && controller.poojas.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: CmsColors.orange),
                    SizedBox(height: 14),
                    Text(
                      'Loading poojas...',
                      style: TextStyle(
                        color: CmsColors.textSecond,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }

            if (controller.error != null && controller.poojas.isEmpty) {
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
                      controller.error!,
                      style: const TextStyle(
                        color: CmsColors.textPrimary,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    CmsPrimaryButton(
                      label: 'Retry',
                      icon: Icons.refresh,
                      onTap: controller.loadPoojas,
                    ),
                  ],
                ),
              );
            }

            final list = controller.filteredPoojas;

            if (list.isEmpty) {
              final isSearch = controller.search.isNotEmpty;
              return CmsEmptyState(
                icon: Icons.self_improvement,
                title: isSearch
                    ? 'No matching pujas'
                    : controller.filter == 'All'
                        ? 'No Pujas Yet'
                        : 'No ${controller.filter} Pujas',
                subtitle: isSearch
                    ? 'Try a different search term'
                    : controller.filter == 'All'
                        ? 'Add your first puja to get started'
                        : 'No pujas with this status',
                actionLabel:
                    !isSearch && controller.filter == 'All' ? 'Add Puja' : null,
                onAction:
                    !isSearch && controller.filter == 'All' ? onAdd : null,
              );
            }

            return RefreshIndicator(
              color: CmsColors.orange,
              onRefresh: controller.loadPoojas,
              child: ListView.separated(
                padding: EdgeInsets.all(isWeb ? 24 : 16),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) => _PoojaCard(
                  pooja: list[i],
                  onEdit: () => onEdit(list[i]),
                  onDelete: () async {
                    final ok = await showCmsDeleteDialog(
                      ctx,
                      itemName: list[i].title,
                    );
                    if (ok == true) {
                      await controller.deletePooja(list[i].id);
                      controller.loadPoojas();
                    }
                  },
                  onApprove: () => _approveDialog(ctx, list[i], controller),
                  onQueue: () => controller.queuePooja(list[i].id),
                  onReject: () => _rejectDialog(ctx, list[i], controller),
                ),
              ),
            );
          }),
        ),
        Obx(
          () => Padding(
            padding: EdgeInsets.fromLTRB(isWeb ? 24 : 16, 0, isWeb ? 24 : 16, 16),
            child: CmsPaginationBar(
              page: controller.page,
              pageSize: controller.limit,
              totalPages: controller.totalPages,
              totalRows: controller.total,
              isLoading: controller.isLoading,
              onPageSelected: controller.goToPage,
              onPageSizeChanged: controller.setPageSize,
            ),
          ),
        ),
      ],
    );
  }

  void _approveDialog(BuildContext ctx, PoojaModel p, PoojaController ctrl) {
    showDialog<void>(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          'Approve Puja',
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
              'This will publish the puja to all devotees.',
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
            ).copyWith(mouseCursor: _cmsButtonClickCursor),
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
          'Reject Puja',
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
              if (reasonCtrl.text.trim().isEmpty) {
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
            ).copyWith(mouseCursor: _cmsButtonClickCursor),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// POOJA CARD
// ════════════════════════════════════════════════════════════════
class _PoojaCard extends StatelessWidget {
  const _PoojaCard({
    required this.pooja,
    required this.onEdit,
    required this.onDelete,
    required this.onApprove,
    required this.onQueue,
    required this.onReject,
  });
  final PoojaModel pooja;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onApprove;
  final VoidCallback onQueue;
  final VoidCallback onReject;

  bool get canEdit {
    final auth = Get.find<AuthController>();
    return auth.isSuperAdmin ||
        pooja.status == 'Draft' ||
        pooja.status == 'Rejected';
  }

  String _formatDate(String s) {
    try {
      // Handle DD-MM-YYYY
      final parts = s.split('-');
      if (parts.length == 3 && parts[0].length <= 2) {
        return s.replaceAll('-', '/'); // Convert DD-MM-YYYY to DD/MM/YYYY
      }
      // Handle ISO
      final d = DateTime.parse(s);
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final isSuperAdmin = auth.isSuperAdmin;
    final isCreatorSuperAdmin =
        isSuperAdmin && pooja.createdBy == auth.currentUserId;
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
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: pooja.imageUrl != null && pooja.imageUrl!.isNotEmpty
                ? Image.network(
                    pooja.imageUrl!,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _PoojaIcon(),
                  )
                : _PoojaIcon(),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pooja.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: CmsColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                ClipRect(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          pooja.deity,
                          style: const TextStyle(
                            fontSize: 12,
                            color: CmsColors.textSecond,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      if (pooja.duration.isNotEmpty) ...[
                        const Text(
                          ' • ',
                          style: TextStyle(color: CmsColors.textSecond),
                        ),
                        Text(
                          pooja.duration,
                          style: const TextStyle(
                            fontSize: 12,
                            color: CmsColors.textSecond,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (pooja.date != null && pooja.date!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 11,
                        color: CmsColors.textSecond,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(pooja.date!),
                        style: const TextStyle(
                          fontSize: 11,
                          color: CmsColors.textSecond,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    CmsStatusBadge(status: pooja.status),
                    if (pooja.difficulty.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: CmsColors.bg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          pooja.difficulty,
                          style: const TextStyle(
                            fontSize: 10,
                            color: CmsColors.textSecond,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Rating + actions
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (pooja.rating > 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, size: 13, color: Color(0xFFF5A623)),
                    const SizedBox(width: 3),
                    Text(
                      pooja.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: CmsColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              if (canEdit)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CmsActionIcon(
                      icon: Icons.edit_outlined,
                      color: Colors.blue,
                      onTap: onEdit,
                      tooltip: 'Edit',
                    ),
                    const SizedBox(width: 6),
                    CmsActionIcon(
                      icon: Icons.delete_outline,
                      color: Colors.red,
                      onTap: onDelete,
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              // Approve/Reject buttons for superadmin on pending poojas
              if (isSuperAdmin &&
                  (pooja.status == 'Pending' || pooja.status == 'Queued')) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isCreatorSuperAdmin) ...[
                      if (pooja.status == 'Pending')
                        _SmBtn('Queued', Colors.orange, onQueue),
                      if (pooja.status == 'Pending') const SizedBox(width: 6),
                      _SmBtn('Publish Now', Colors.green, onApprove),
                    ] else ...[
                      _SmBtn('Reject', Colors.red, onReject),
                      const SizedBox(width: 6),
                      _SmBtn('Approve', Colors.green, onApprove),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _PoojaIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 52,
    height: 52,
    decoration: BoxDecoration(
      color: CmsColors.orange.withOpacity(0.12),
      borderRadius: BorderRadius.circular(10),
    ),
    child: const Icon(
      Icons.self_improvement,
      color: CmsColors.orange,
      size: 26,
    ),
  );
}

// ════════════════════════════════════════════════════════════════
// ADD / EDIT POOJA FORM
// ════════════════════════════════════════════════════════════════
class _PoojaForm extends StatefulWidget {
  const _PoojaForm({
    this.pooja,
    required this.controller,
    required this.onCancel,
    required this.onSaved,
  });
  final PoojaModel? pooja;
  final PoojaController controller;
  final VoidCallback onCancel;
  final VoidCallback onSaved;

  @override
  State<_PoojaForm> createState() => _PoojaFormState();
}

class _PoojaFormState extends State<_PoojaForm> {
  late final TextEditingController _titleCtrl;
  List<String> _selectedDeityIds = [];
  late final TextEditingController _durationCtrl;
  late final TextEditingController _idealTimeCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _purposeWhyCtrl;
  late final TextEditingController _purposeBenefitsCtrl;
  late final TextEditingController _deitySummaryAboutCtrl;
  late final TextEditingController _deitySummaryBlessingsCtrl;
  late final TextEditingController _prepPersonalCtrl;
  late final TextEditingController _prepSpaceCtrl;
  late final TextEditingController _prepItemsCtrl;
  late final TextEditingController _mantraPrimaryCtrl;
  late final TextEditingController _mantraRepetitionsCtrl;
  String? _purposeWhyRich;
  String? _deitySummaryAboutRich;
  String? _mantraPrimaryRich;
  String? _mantraMeaningRich;
  String? _blessingsRich;
  late final TextEditingController _mantraAdditionalCtrl;
  late final TextEditingController _mantraMeaningCtrl;
  late final TextEditingController _guidanceMindsetCtrl;
  late final TextEditingController _guidanceAvoidCtrl;
  late final TextEditingController _completionClosureCtrl;
  late final TextEditingController _completionIntegrationCtrl;
  late final TextEditingController _completionBenefitsCtrl;
  late final TextEditingController _completionBlessingsCtrl;
  late final TextEditingController _offeringsTitleCtrl;
  late final TextEditingController _offeringsDescCtrl;
  late final TextEditingController _actionsTitleCtrl;
  late final TextEditingController _actionsDescCtrl;
  late final TextEditingController _symbolismTitleCtrl;
  late final TextEditingController _symbolismDescCtrl;
  DateTime? _selectedDate;
  final List<DateTime> _selectedScheduleDates = [];
  bool _dailyRepeat = false;
  final _stepTitleCtrl = TextEditingController();
  final _stepDescCtrl = TextEditingController();
  final _stepTitleFocus = FocusNode();
  final _itemCtrl = TextEditingController();
  final List<String> _stepImageUrls = [];
  final List<PickedFile> _stepPickedImages = [];

  late String _difficulty;
  late String _category;
  late List<_StepDraft> _stepEntries;
  late List<String> _items;
  late List<String> _idealTimes;
  late List<String> _purposeBenefits;
  late List<String> _deitySummaryBlessings;
  late List<String> _mantraAdditional;
  late List<String> _preparationPersonal;
  late List<String> _preparationSpace;
  late List<String> _guidanceMindset;
  late List<String> _guidanceAvoid;
  late List<String> _completionClosure;
  late List<String> _completionIntegration;
  late List<String> _completionBenefits;
  late List<String> _completionBlessings;
  late List<String> _selectedFestivalIds;
  late List<Map<String, String>> _offeringsMeaningEntries;
  late List<Map<String, String>> _actionsMeaningEntries;
  late List<Map<String, String>> _otherSymbolismEntries;
  bool _showStepEditor = false;
  int? _editingStepIndex;
  bool _showOfferingsEditor = false;
  bool _showActionsEditor = false;
  bool _showOtherSymbolismEditor = false;
  int? _editingOfferingsIndex;
  int? _editingActionsIndex;
  int? _editingOtherSymbolismIndex;

  FestivalController get _festivalCtrl => Get.find<FestivalController>();

  List<FestivalModel> get _approvedFestivals => _festivalCtrl.festivals
      .where(
        (f) =>
            f.status.toLowerCase() == 'approved' ||
            f.status.toLowerCase() == 'published',
      )
      .toList();
  PickedFile? _pickedImage;
  // existing URLs (editing mode)
  String? _imageUrl;

  static const _diffs = ['Beginner', 'Intermediate', 'Advanced'];
  static const _cats = [
    'Daily Puja',
    'Festival',
    'Special Occasion',
    'Full Moon',
    'New Moon',
    'Fasting',
  ];

  bool get _isEdit => widget.pooja != null;

  bool get _isDailyPuja => _category == 'Daily Puja';

  static String? _trimMediaUrl(String? url) {
    final t = url?.trim();
    if (t == null || t.isEmpty) return null;
    return t;
  }

  @override
  void initState() {
    super.initState();
    final p = widget.pooja;
    _titleCtrl = TextEditingController(text: p?.title ?? '');
    _selectedDeityIds = List<String>.from(p?.deities ?? const []);
    _durationCtrl = TextEditingController(text: p?.duration ?? '');
    _idealTimeCtrl = TextEditingController();
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _purposeWhyCtrl = TextEditingController(text: p?.purposeWhy ?? '');
    _purposeWhyRich = p?.purposeWhy;
    _purposeBenefitsCtrl = TextEditingController();
    _deitySummaryAboutCtrl = TextEditingController(
      text: p?.deitySummaryAbout ?? '',
    );
    _deitySummaryAboutRich = p?.deitySummaryAbout;
    _deitySummaryBlessingsCtrl = TextEditingController();
    _prepPersonalCtrl = TextEditingController();
    _prepSpaceCtrl = TextEditingController();
    _prepItemsCtrl = TextEditingController(
      text: p?.preparationItems.join('\n') ?? p?.requiredItems.join('\n') ?? '',
    );
    _mantraPrimaryCtrl = TextEditingController(text: p?.mantraPrimary ?? '');
    _mantraPrimaryRich = p?.mantraPrimary;
    _mantraRepetitionsCtrl = TextEditingController(
      text: p?.mantraRepetitions ?? '',
    );
    _mantraAdditionalCtrl = TextEditingController();
    _mantraMeaningCtrl = TextEditingController(text: p?.mantraMeaning ?? '');
    _mantraMeaningRich = p?.mantraMeaning;
    _guidanceMindsetCtrl = TextEditingController();
    _guidanceAvoidCtrl = TextEditingController();
    _completionClosureCtrl = TextEditingController();
    _completionIntegrationCtrl = TextEditingController();
    _completionBenefitsCtrl = TextEditingController();
    _completionBlessingsCtrl = TextEditingController();
    _offeringsTitleCtrl = TextEditingController();
    _offeringsDescCtrl = TextEditingController();
    _actionsTitleCtrl = TextEditingController();
    _actionsDescCtrl = TextEditingController();
    _symbolismTitleCtrl = TextEditingController();
    _symbolismDescCtrl = TextEditingController();
    _difficulty = _diffs.contains(p?.difficulty) ? p!.difficulty : _diffs.first;
    _category = _cats.contains(p?.category) ? p!.category : _cats.first;
    _dailyRepeat = p?.daily == true && _category == 'Daily Puja';
    _initScheduleDatesFromPooja(p);
    _stepEntries = List<_StepDraft>.from(
      (p?.steps ?? <String>[]).map(_decodeStoredStep),
    );
    _items = List.from(p?.requiredItems ?? []);
    _idealTimes = List.from(p?.idealTime ?? const []);
    _purposeBenefits = List.from(p?.purposeBenefits ?? const []);
    _deitySummaryBlessings = List.from(p?.deitySummaryBlessings ?? const []);
    _mantraAdditional = List.from(p?.mantraAdditional ?? const []);
    _preparationPersonal = List.from(p?.preparationPersonal ?? const []);
    _preparationSpace = List.from(p?.preparationSpace ?? const []);
    _guidanceMindset = List.from(p?.guidanceMindset ?? const []);
    _guidanceAvoid = List.from(p?.guidanceAvoid ?? const []);
    _completionClosure = List.from(p?.completionClosure ?? const []);
    _completionIntegration = List.from(p?.completionIntegration ?? const []);
    _completionBenefits = List.from(p?.completionBenefits ?? const []);
    _completionBlessings = List.from(p?.blessings ?? const []);
    _blessingsRich = p?.blessings.isNotEmpty == true
        ? p!.blessings.first
        : null;
    _selectedFestivalIds = List.from(p?.festivalIds ?? const []);
    _offeringsMeaningEntries = List.from(
      p?.spiritualOfferingsMeaning ?? const [],
    );
    _actionsMeaningEntries = List.from(p?.spiritualActionsMeaning ?? const []);
    _otherSymbolismEntries = List.from(p?.spiritualOtherSymbolism ?? const []);
    _imageUrl = _trimMediaUrl(p?.imageUrl);
    if (_festivalCtrl.festivals.isEmpty) {
      Future.microtask(_festivalCtrl.loadFestivals);
    }
    Future.microtask(widget.controller.loadDeities);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _durationCtrl.dispose();
    _idealTimeCtrl.dispose();
    _descCtrl.dispose();
    _purposeWhyCtrl.dispose();
    _purposeBenefitsCtrl.dispose();
    _deitySummaryAboutCtrl.dispose();
    _deitySummaryBlessingsCtrl.dispose();
    _prepPersonalCtrl.dispose();
    _prepSpaceCtrl.dispose();
    _prepItemsCtrl.dispose();
    _mantraPrimaryCtrl.dispose();
    _mantraRepetitionsCtrl.dispose();
    _mantraAdditionalCtrl.dispose();
    _mantraMeaningCtrl.dispose();
    _guidanceMindsetCtrl.dispose();
    _guidanceAvoidCtrl.dispose();
    _completionClosureCtrl.dispose();
    _completionIntegrationCtrl.dispose();
    _completionBenefitsCtrl.dispose();
    _completionBlessingsCtrl.dispose();
    _offeringsTitleCtrl.dispose();
    _offeringsDescCtrl.dispose();
    _actionsTitleCtrl.dispose();
    _actionsDescCtrl.dispose();
    _symbolismTitleCtrl.dispose();
    _symbolismDescCtrl.dispose();
    _stepTitleCtrl.dispose();
    _stepDescCtrl.dispose();
    _stepTitleFocus.dispose();
    _itemCtrl.dispose();
    super.dispose();
  }

  String? _validate() {
    if (_titleCtrl.text.trim().isEmpty) return 'Pooja name is required';
    if (_selectedDeityIds.isEmpty) {
      return 'At least one deity is required';
    }
    if (_durationCtrl.text.trim().isEmpty) return 'Duration is required';
    return null;
  }

  List<String> _toList(String value) => value
      .split(RegExp(r'[\n,]'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  _StepDraft _decodeStoredStep(String raw) {
    final decoded = PoojaStepCodec.decode(raw);
    return _StepDraft(
      title: decoded.title.isEmpty ? 'Untitled Step' : decoded.title,
      description: decoded.description,
      imageUrls: decoded.imageUrls,
    );
  }

  String _encodeStoredStep(_StepDraft step) {
    return PoojaStepCodec.encode(
      title: step.title,
      description: step.description,
      imageUrls: step.imageUrls,
    );
  }

  List<List<PickedFile>> _stepPickedImagesByStep() => _stepEntries
      .map((step) => List<PickedFile>.from(step.pickedImages))
      .toList();

  Future<void> _pickStepImages() async {
    final files = await Get.find<MediaUploadService>().pickImages();
    if (files.isEmpty) return;
    setState(() => _stepPickedImages.addAll(files));
  }

  void _removeStepPickedImage(int index) {
    setState(() => _stepPickedImages.removeAt(index));
  }

  void _removeStepImageUrl(int index) {
    setState(() => _stepImageUrls.removeAt(index));
  }

  void _clearStepEditorFields() {
    _stepTitleCtrl.clear();
    _stepDescCtrl.clear();
    _stepImageUrls.clear();
    _stepPickedImages.clear();
    _editingStepIndex = null;
  }

  void _focusStepTitleField() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _stepTitleFocus.requestFocus();
        final text = _stepTitleCtrl.text;
        _stepTitleCtrl.selection = TextSelection.collapsed(offset: text.length);
      });
    });
  }

  void _toggleStepEditor() {
    final opening = !_showStepEditor;
    setState(() {
      if (_showStepEditor) {
        _clearStepEditorFields();
        _showStepEditor = false;
      } else {
        _clearStepEditorFields();
        _showStepEditor = true;
      }
    });
    if (opening) _focusStepTitleField();
  }

  void _startEditStep(int index) {
    final step = _stepEntries[index];
    setState(() {
      _editingStepIndex = index;
      _showStepEditor = true;
      _stepTitleCtrl.text = step.title;
      _stepDescCtrl.text = step.description;
      _stepImageUrls
        ..clear()
        ..addAll(step.imageUrls);
      _stepPickedImages
        ..clear()
        ..addAll(step.pickedImages);
    });
    _focusStepTitleField();
  }

  void _cancelStepEdit() {
    setState(() {
      _clearStepEditorFields();
      _showStepEditor = false;
    });
  }

  void _removeStep(int index) {
    setState(() {
      if (_editingStepIndex == index) {
        _clearStepEditorFields();
        _showStepEditor = false;
      } else if (_editingStepIndex != null && index < _editingStepIndex!) {
        _editingStepIndex = _editingStepIndex! - 1;
      }
      final next = List<_StepDraft>.from(_stepEntries);
      next.removeAt(index);
      _stepEntries = next;
    });
  }

  List<String> _serializedSteps() =>
      _stepEntries.map(_encodeStoredStep).where((e) => e.isNotEmpty).toList();

  void _saveStepEntry() {
    final title = _stepTitleCtrl.text.trim();
    final description = _stepDescCtrl.text.trim();
    if (title.isEmpty &&
        description.isEmpty &&
        _stepImageUrls.isEmpty &&
        _stepPickedImages.isEmpty) {
      return;
    }
    final editingIndex = _editingStepIndex;
    final draft = _StepDraft(
      title: title.isEmpty ? 'Untitled Step' : title,
      description: description,
      imageUrls: List<String>.from(_stepImageUrls),
      pickedImages: List<PickedFile>.from(_stepPickedImages),
    );
    setState(() {
      if (editingIndex != null) {
        final next = List<_StepDraft>.from(_stepEntries);
        next[editingIndex] = draft;
        _stepEntries = next;
      } else {
        _stepEntries = [..._stepEntries, draft];
      }
      _clearStepEditorFields();
      _showStepEditor = true;
    });
    _focusStepTitleField();
  }

  void _addChipValue(TextEditingController ctrl, List<String> target) {
    final value = ctrl.text.trim();
    if (value.isEmpty) return;
    if (!target.contains(value)) {
      target.add(value);
    }
    ctrl.clear();
  }

  void _startEditChipText(
    TextEditingController ctrl,
    List<String> target,
    int index,
  ) {
    if (index < 0 || index >= target.length) return;
    final value = target[index];
    ctrl.text = value;
    ctrl.selection = TextSelection.collapsed(offset: value.length);
    target.removeAt(index);
  }

  void _addKeyValueEntry({
    required TextEditingController titleCtrl,
    required TextEditingController descCtrl,
    required List<Map<String, String>> target,
    required void Function() onAdded,
    int? editingIndex,
  }) {
    final title = titleCtrl.text.trim();
    final description = descCtrl.text.trim();
    if (title.isEmpty && description.isEmpty) return;
    final entry = {
      'title': title.isEmpty ? 'Untitled' : title,
      'description': description,
    };
    if (editingIndex != null) {
      target[editingIndex] = entry;
    } else {
      target.add(entry);
    }
    titleCtrl.clear();
    descCtrl.clear();
    onAdded();
  }

  void _startEditKeyValueEntry({
    required int index,
    required List<Map<String, String>> target,
    required TextEditingController titleCtrl,
    required TextEditingController descCtrl,
    required void Function() onStarted,
  }) {
    if (index < 0 || index >= target.length) return;
    final entry = target[index];
    titleCtrl.text = entry['title'] ?? '';
    descCtrl.text = entry['description'] ?? '';
    onStarted();
  }

  void _clearKeyValueEditor({
    required TextEditingController titleCtrl,
    required TextEditingController descCtrl,
    required void Function() onCleared,
  }) {
    titleCtrl.clear();
    descCtrl.clear();
    onCleared();
  }

  void _applyGaneshaTemplate() {
    _titleCtrl.text = 'Ganesha Pooja';
    _durationCtrl.text = '45-60 min';
    _idealTimes = ['Morning'];
    _category = 'Festival';
    _difficulty = 'Beginner';
    _descCtrl.text =
        'A devotional Ganesha ritual performed for obstacle removal, clarity, prosperity, and spiritual grounding.';
    _purposeWhyCtrl.text =
        'This ritual honors Lord Ganesha and is performed for blessings, obstacle removal, and auspicious beginnings.';
    _purposeBenefits = [
      'Peace of mind',
      'smoother life path',
      'removal of challenges',
      'spiritual grounding',
      'success',
    ];
    _deitySummaryAboutCtrl.text =
        'Lord Ganesha is the son of Shiva and Parvati, worshipped as remover of obstacles and giver of wisdom and prosperity.';
    _deitySummaryBlessings = [
      'Obstacle removal',
      'intellect',
      'protection',
      'prosperity',
      'spiritual strength',
    ];
    _prepPersonalCtrl.text =
        'Take a bath and wear clean clothes\nApproach with a calm, focused mind\nAvoid arguments and harsh words';
    _prepSpaceCtrl.text =
        'Clean home entrances and prayer space\nKeep the altar neat and peaceful\nSprinkle turmeric water for purification';
    _items = [
      'Ganesha idol (murthi)',
      'Incense sticks',
      'Clay lamp (diya), oil, wick',
      'Bell',
      'Betel leaves and betel nuts',
      'Sugar/sugar candy',
      'Durva grass',
      'Coconut',
      'Flowers',
      'Camphor',
      'Turmeric and kumkum',
      'Fruits, milk, and water',
    ];
    _prepItemsCtrl.text = _items.join('\n');
    _stepEntries = [
      const _StepDraft(
        title: 'Setup',
        description: 'Arrange offerings, tray, diya, and bell.',
      ),
      const _StepDraft(
        title: 'Invocation',
        description: 'Light incense and chant opening prayers.',
      ),
      const _StepDraft(
        title: 'Offerings',
        description: 'Offer flowers with mantra repetition.',
      ),
      const _StepDraft(
        title: 'Sacred actions',
        description: 'Perform aarti and clockwise circling of flame.',
      ),
      const _StepDraft(
        title: 'Chanting and prayer',
        description: 'Continue mantra and devotional focus.',
      ),
      const _StepDraft(
        title: 'Personal prayer',
        description: 'Pray sincerely for blessings.',
      ),
      const _StepDraft(
        title: 'Atmosphere enhancement',
        description: 'Bhajans and peaceful ambience.',
      ),
      const _StepDraft(
        title: 'Closure',
        description: 'Bow in gratitude and surrender.',
      ),
      const _StepDraft(
        title: 'Prasad distribution',
        description: 'Share blessed offerings.',
      ),
    ];
    _mantraPrimaryCtrl.text = 'Om Shree Ganeshaya Namaha';
    _mantraRepetitionsCtrl.text = '9 or multiples of 9 up to 108';
    _mantraAdditional = ['Ganapati Bappa Morya, Mangal Murti Morya (3 times)'];
    _mantraMeaningCtrl.text =
        'Chanting raises vibration, removes obstacles, and aligns the devotee with peace and divine guidance.';
    _offeringsMeaningEntries = [
      {
        'title': 'Coconut',
        'description': 'Surrender of ego and awakening of divine consciousness',
      },
      {
        'title': 'Flowers',
        'description': 'Offering joy, devotion, and spiritual connection',
      },
    ];
    _actionsMeaningEntries = [
      {
        'title': 'Aarti (circling flame)',
        'description':
            'Removal of darkness and ignorance, offering mind-body-soul',
      },
    ];
    _otherSymbolismEntries = [
      {
        'title': 'Durva grass',
        'description': 'Simplicity and grounded devotion',
      },
      {
        'title': 'Cleaning home',
        'description': 'Invites purity and divine presence',
      },
      {
        'title': 'Chant repetitions',
        'description': 'Transform obstacles into opportunities',
      },
    ];
    _preparationPersonal = [
      'Take a bath and wear clean clothes',
      'Approach with a calm, focused mind',
      'Avoid arguments and harsh words',
    ];
    _preparationSpace = [
      'Clean home entrances and prayer space',
      'Keep the altar neat and peaceful',
      'Sprinkle turmeric water for purification',
    ];
    _guidanceMindset = ['Devotion', 'Humility', 'Gratitude', 'Sincerity'];
    _guidanceAvoid = [
      'Negative intention',
      'Praying for harm',
      'Distractions',
      'Fighting, harsh words, disharmony',
    ];
    _completionClosure = [
      'Offer gratitude',
      'Bow down in surrender',
      'Sit in silence for a few moments',
    ];
    _completionIntegration = [
      'Maintain faith',
      'Act with clarity',
      'Trust obstacles are being removed',
    ];
    _completionBenefits = [
      'Reduced obstacles',
      'Mental clarity',
      'Improved flow in life',
      'Inner peace',
      'Spiritual upliftment',
    ];
    _blessingsRich =
        'May you be blessed with good health, growing wealth, and a prosperous family life.';
    final approved = _approvedFestivals;
    if (approved.isNotEmpty) {
      _selectedFestivalIds = [approved.first.id];
    }
  }

  String _festivalLabelById(String id) {
    final found = _festivalCtrl.festivals.firstWhereOrNull((f) => f.id == id);
    return found?.title ?? id;
  }

  void _initScheduleDatesFromPooja(PoojaModel? p) {
    _selectedScheduleDates.clear();
    _selectedDate = null;
    if (p == null || _dailyRepeat) return;

    final parsed = <DateTime>[];
    if (p.schedules.isNotEmpty) {
      for (final entry in p.schedules) {
        final dateOnly = _parseDateOnly(entry['date'] ?? '');
        if (dateOnly == null) continue;
        final time = _parseTime(entry['time'] ?? '00:00');
        parsed.add(
          DateTime(
            dateOnly.year,
            dateOnly.month,
            dateOnly.day,
            time.hour,
            time.minute,
          ),
        );
      }
    } else if (p.date != null && p.date!.trim().isNotEmpty) {
      final legacy = _parseDate(p.date!);
      if (legacy != null) parsed.add(legacy);
    }
    parsed.sort((a, b) => a.compareTo(b));

    if (_cats.contains(p.category) && p.category == 'Daily Puja') {
      _selectedScheduleDates.addAll(parsed);
    } else if (parsed.isNotEmpty) {
      _selectedDate = parsed.first;
    }
  }


  bool _isSameDateTime(DateTime a, DateTime b) =>
      a.year == b.year &&
      a.month == b.month &&
      a.day == b.day &&
      a.hour == b.hour &&
      a.minute == b.minute;

  String _formatDisplayDateTime(DateTime d) {
    final hour = d.hour;
    final minute = d.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    return '${d.day}/${d.month}/${d.year}, $hour12:$minute $period';
  }

  String _formatApiDateOnly(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.year}';

  String _formatApiTimeOnly(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}';

  List<Map<String, String>> _schedulesApi() {
    if (_isDailyPuja && _dailyRepeat) return const [];
    final source = _isDailyPuja
        ? List<DateTime>.from(_selectedScheduleDates)
        : (_selectedDate != null ? [_selectedDate!] : <DateTime>[]);
    source.sort((a, b) => a.compareTo(b));
    return source
        .map(
          (d) => {
            'date': _formatApiDateOnly(d),
            'time': _formatApiTimeOnly(d),
          },
        )
        .toList();
  }

  void _onCategoryChanged(String? value) {
    final next = value ?? _cats.first;
    if (next == _category) return;
    setState(() {
      if (next == 'Daily Puja' && _category != 'Daily Puja') {
        _selectedScheduleDates.clear();
        if (_selectedDate != null) {
          _selectedScheduleDates.add(_selectedDate!);
          _selectedDate = null;
        }
      } else if (next != 'Daily Puja' && _category == 'Daily Puja') {
        _selectedDate = _selectedScheduleDates.isNotEmpty
            ? _selectedScheduleDates.first
            : null;
        _selectedScheduleDates.clear();
        _dailyRepeat = false;
      }
      _category = next;
    });
  }

  Future<TimeOfDay?> _pickScheduleTime({DateTime? initial}) {
    return showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial ?? DateTime.now()),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: CmsColors.orange,
              onPrimary: Colors.white,
              onSurface: CmsColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
  }

  Future<DateTime?> _pickScheduleDateTime({DateTime? initial}) async {
    final base = initial ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: CmsColors.orange,
              onPrimary: Colors.white,
              onSurface: CmsColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null || !mounted) return null;
    final time = await _pickScheduleTime(initial: base);
    if (!mounted || time == null) return null;
    return DateTime(
      picked.year,
      picked.month,
      picked.day,
      time.hour,
      time.minute,
    );
  }

  Future<void> _pickScheduleDate() async {
    final initial = _isDailyPuja
        ? (_selectedScheduleDates.isNotEmpty
            ? _selectedScheduleDates.last
            : DateTime.now())
        : (_selectedDate ?? DateTime.now());
    final combined = await _pickScheduleDateTime(initial: initial);
    if (combined == null) return;
    setState(() {
      if (_isDailyPuja) {
        if (_selectedScheduleDates.any((d) => _isSameDateTime(d, combined))) {
          return;
        }
        _selectedScheduleDates.add(combined);
        _selectedScheduleDates.sort((a, b) => a.compareTo(b));
      } else {
        _selectedDate = combined;
      }
    });
  }

  Future<void> _editScheduleAt(int index) async {
    final current = _selectedScheduleDates[index];
    final updated = await _pickScheduleDateTime(initial: current);
    if (updated == null || !mounted) return;
    setState(() {
      final duplicate = _selectedScheduleDates
          .asMap()
          .entries
          .any((e) => e.key != index && _isSameDateTime(e.value, updated));
      if (duplicate) return;
      _selectedScheduleDates[index] = updated;
      _selectedScheduleDates.sort((a, b) => a.compareTo(b));
    });
  }

  Widget _buildDailyScheduleSection() {
    if (!_isDailyPuja) {
      return _buildScheduleDateField();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: CmsColors.bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: CmsColors.border),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: CmsColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Puja runs every day without fixed schedule dates',
                      style: TextStyle(
                        fontSize: 11,
                        color: CmsColors.textSecond,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _dailyRepeat,
                activeThumbColor: Colors.white,
                activeTrackColor: CmsColors.orange,
                onChanged: (value) => setState(() {
                  _dailyRepeat = value;
                  if (value) _selectedScheduleDates.clear();
                }),
              ),
            ],
          ),
        ),
        if (!_dailyRepeat) ...[
          const SizedBox(height: 12),
          _buildScheduleDateField(),
        ],
      ],
    );
  }

  Widget _buildScheduleDateField() {
    if (_isDailyPuja) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Schedule Dates & Times',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: CmsColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          _cmsClickable(
            onTap: _pickScheduleDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: CmsColors.bg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: CmsColors.border),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.event_available_outlined,
                    size: 16,
                    color: CmsColors.orange,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Add date & time',
                    style: TextStyle(fontSize: 13, color: CmsColors.textSecond),
                  ),
                ],
              ),
            ),
          ),
          if (_selectedScheduleDates.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _selectedScheduleDates.asMap().entries.map((e) {
                final date = e.value;
                return _Chip(
                  label: _formatDisplayDateTime(date),
                  onEdit: () => _editScheduleAt(e.key),
                  onRemove: () =>
                      setState(() => _selectedScheduleDates.removeAt(e.key)),
                );
              }).toList(),
            ),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Schedule Date & Time',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: CmsColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        _cmsClickable(
          onTap: _pickScheduleDate,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: CmsColors.bg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: CmsColors.border),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.event_available_outlined,
                  size: 16,
                  color: _selectedDate != null
                      ? CmsColors.orange
                      : CmsColors.textSecond,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _selectedDate != null
                        ? _formatDisplayDateTime(_selectedDate!)
                        : 'Select date & time',
                    style: TextStyle(
                      fontSize: 13,
                      color: _selectedDate != null
                          ? CmsColors.textPrimary
                          : CmsColors.textSecond,
                    ),
                  ),
                ),
                if (_selectedDate != null)
                  _cmsClickable(
                    onTap: () => setState(() => _selectedDate = null),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: CmsColors.textSecond,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  DateTime? _parseDateOnly(String s) {
    if (s.isEmpty) return null;
    final trimmed = s.trim();
    try {
      final parts = trimmed.split('-');
      if (parts.length == 3 && parts[0].length <= 2) {
        return DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }
      final parsed = DateTime.parse(trimmed);
      return DateTime(parsed.year, parsed.month, parsed.day);
    } catch (_) {
      return null;
    }
  }

  TimeOfDay _parseTime(String s) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(s.trim());
    if (match == null) return const TimeOfDay(hour: 0, minute: 0);
    return TimeOfDay(
      hour: int.parse(match.group(1)!),
      minute: int.parse(match.group(2)!),
    );
  }

  DateTime? _parseDate(String s) {
    if (s.isEmpty) return null;
    final trimmed = s.trim();
    try {
      final withTime = RegExp(
        r'^(\d{1,2})-(\d{1,2})-(\d{4}) (\d{1,2}):(\d{2})$',
      );
      final match = withTime.firstMatch(trimmed);
      if (match != null) {
        return DateTime(
          int.parse(match.group(3)!),
          int.parse(match.group(2)!),
          int.parse(match.group(1)!),
          int.parse(match.group(4)!),
          int.parse(match.group(5)!),
        );
      }
      return _parseDateOnly(trimmed);
    } catch (_) {
      return null;
    }
  }

  Future<void> _submit({required bool isDraft}) async {
    final blessingsPayload = <String>[
      if ((_blessingsRich ?? '').isNotEmpty) _blessingsRich!,
    ];

    final err = _validate();
    if (err != null) {
      Get.snackbar(
        'Validation',
        err,
        snackPosition: SnackPosition.TOP,
        backgroundColor: CmsColors.orangeDark,
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
      );
      return;
    }
    final status = isDraft ? 'Draft' : 'Pending';
    final schedulesApi = _schedulesApi();
    final dailyApi = _isDailyPuja && _dailyRepeat;
    bool ok;
    if (_isEdit) {
      ok = await widget.controller.updatePooja(
        widget.pooja!.id,
        pickedImage: _pickedImage,
        stepImagesByStep: _stepPickedImagesByStep(),
        widget.pooja!.copyWith(
          title: _titleCtrl.text.trim(),
          deities: _selectedDeityIds,
          category: _category,
          difficulty: _difficulty,
          duration: _durationCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          status: status,
          idealTime: List<String>.from(_idealTimes),
          imageUrl: _pickedImage != null ? null : _trimMediaUrl(_imageUrl),
          steps: _serializedSteps(),
          requiredItems: _items,
          purposeWhy: _purposeWhyRich ?? '',
          purposeBenefits: _purposeBenefits,
          deitySummaryAbout: _deitySummaryAboutRich ?? '',
          deitySummaryBlessings: _deitySummaryBlessings,
          preparationPersonal: _preparationPersonal,
          preparationSpace: _preparationSpace,
          preparationItems: _toList(_prepItemsCtrl.text),
          mantraPrimary: _mantraPrimaryRich ?? '',
          mantraRepetitions: _mantraRepetitionsCtrl.text.trim(),
          mantraAdditional: _mantraAdditional,
          mantraMeaning: _mantraMeaningRich ?? '',
          spiritualOfferingsMeaning: _offeringsMeaningEntries,
          spiritualActionsMeaning: _actionsMeaningEntries,
          spiritualOtherSymbolism: _otherSymbolismEntries,
          guidanceMindset: _guidanceMindset,
          guidanceAvoid: _guidanceAvoid,
          completionClosure: _completionClosure,
          completionIntegration: _completionIntegration,
          completionBenefits: _completionBenefits,
          blessings: blessingsPayload,
          festivalIds: _selectedFestivalIds,
          schedules: schedulesApi,
          daily: dailyApi,
        ),
      );
    } else {
      ok = await widget.controller.createPooja(
        pickedImage: _pickedImage,
        stepImagesByStep: _stepPickedImagesByStep(),
        title: _titleCtrl.text.trim(),
        deities: _selectedDeityIds,
        category: _category,
        difficulty: _difficulty,
        duration: _durationCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        status: status,
        idealTime: List<String>.from(_idealTimes),
        imageUrl: _pickedImage != null ? null : _trimMediaUrl(_imageUrl),
        steps: _serializedSteps(),
        requiredItems: _items,
        purposeWhy: _purposeWhyRich ?? '',
        purposeBenefits: _purposeBenefits,
        deitySummaryAbout: _deitySummaryAboutRich ?? '',
        deitySummaryBlessings: _deitySummaryBlessings,
        preparationPersonal: _preparationPersonal,
        preparationSpace: _preparationSpace,
        preparationItems: _toList(_prepItemsCtrl.text),
        mantraPrimary: _mantraPrimaryRich ?? '',
        mantraRepetitions: _mantraRepetitionsCtrl.text.trim(),
        mantraAdditional: _mantraAdditional,
        mantraMeaning: _mantraMeaningRich ?? '',
        spiritualOfferingsMeaning: _offeringsMeaningEntries,
        spiritualActionsMeaning: _actionsMeaningEntries,
        spiritualOtherSymbolism: _otherSymbolismEntries,
        guidanceMindset: _guidanceMindset,
        guidanceAvoid: _guidanceAvoid,
        completionClosure: _completionClosure,
        completionIntegration: _completionIntegration,
        completionBenefits: _completionBenefits,
        blessings: blessingsPayload,
        festivalIds: _selectedFestivalIds,
        schedules: schedulesApi,
        daily: dailyApi,
      );
    }
    if (ok) widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width >= 768;

    return Obx(() {
      final loading = widget.controller.isSubmitting;
      return SingleChildScrollView(
        padding: EdgeInsets.all(isWeb ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back + title
            Row(
              children: [
                _cmsClickable(
                  onTap: widget.onCancel,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: CmsColors.bg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: CmsColors.border),
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      size: 18,
                      color: CmsColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _isEdit ? 'Edit Puja' : 'Add New Puja',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: CmsColors.textPrimary,
                  ),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: loading
                      ? null
                      : () => setState(() => _applyGaneshaTemplate()),
                  icon: const Icon(Icons.auto_fix_high, size: 16),
                  label: const Text('Use Ganesha Template'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: CmsColors.orange.withOpacity(0.45)),
                    foregroundColor: CmsColors.orangeDark,
                  ).copyWith(mouseCursor: _cmsButtonClickCursor),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (isWeb)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _leftCol()),
                  const SizedBox(width: 20),
                  Expanded(child: _rightCol(loading)),
                ],
              )
            else ...[
              _leftCol(),
              const SizedBox(height: 16),
              _rightCol(loading),
            ],
          ],
        ),
      );
    });
  }

  Widget _leftCol() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      CmsFormCard(
        title: 'Ritual Overview',
        children: [
          CmsFormField(
            label: 'Puja Name *',
            hint: 'e.g. Ganesh Chaturthi Puja',
            controller: _titleCtrl,
          ),
          const SizedBox(height: 12),
          CmsFormField(
            label: 'Duration *',
            hint: 'e.g. 45 min',
            controller: _durationCtrl,
          ),
          const SizedBox(height: 12),
          const Text(
            'Ideal Time',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: CmsColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          _InputRow(
            ctrl: _idealTimeCtrl,
            hint: 'Add ideal time (e.g. Morning)',
            onAdd: () => setState(
              () => _addChipValue(_idealTimeCtrl, _idealTimes),
            ),
          ),
          if (_idealTimes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _idealTimes.asMap().entries.map(
                    (e) => _Chip(
                      label: e.value,
                      onEdit: () => setState(
                        () => _startEditChipText(
                          _idealTimeCtrl,
                          _idealTimes,
                          e.key,
                        ),
                      ),
                      onRemove: () =>
                          setState(() => _idealTimes.removeAt(e.key)),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Obx(() {
                  final deities = widget.controller.deities;
                  final isLoading = widget.controller.isLoadingDeities;
                  final loaded = widget.controller.deitiesLoaded;

                  return CmsMultiSelectField(
                    label: 'Deity *',
                    hintText: 'Select deities',
                    isLoading: isLoading && !loaded,
                    loadingText: 'Loading deities...',
                    emptyText: 'No deities found',
                    options: deities
                        .map(
                          (d) => CmsSelectOption(
                            value: d['id']!,
                            label: d['name']?.isNotEmpty == true
                                ? d['name']!
                                : d['id']!,
                          ),
                        )
                        .toList(),
                    selectedValues: _selectedDeityIds,
                    onChanged: (values) =>
                        setState(() => _selectedDeityIds = values),
                  );
                }),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CmsDropdownField(
                  label: 'Difficulty',
                  items: _diffs,
                  initialValue: _difficulty,
                  onChanged: (v) =>
                      setState(() => _difficulty = v ?? _diffs.first),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          CmsDropdownField(
            label: 'Category',
            items: _cats,
            initialValue: _category,
            onChanged: _onCategoryChanged,
          ),
          const SizedBox(height: 12),
          _buildDailyScheduleSection(),
          const SizedBox(height: 12),
          CmsFormField(
            label: 'Description',
            hint: 'Enter a brief description...',
            controller: _descCtrl,
            maxLines: 4,
          ),
          const SizedBox(height: 12),
          Obx(() {
            final festivals = _approvedFestivals;
            final dropdownValue = null;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Associate Festivals',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: CmsColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: DropdownButtonFormField<String>(
                          key: ValueKey(
                            'festival-dd-${_selectedFestivalIds.join('|')}',
                          ),
                          isDense: true,
                          isExpanded: true,
                          value: dropdownValue,
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: CmsColors.textSecond,
                            size: 20,
                          ),
                          dropdownColor: CmsColors.bg,
                          style: const TextStyle(
                            fontSize: 13,
                            color: CmsThemeColors.inputText,
                          ),
                          items: festivals
                              .map(
                                (f) => DropdownMenuItem<String>(
                                  value: f.id,
                                  child: Text(
                                    f.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: CmsThemeColors.inputText,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: festivals.isEmpty
                              ? null
                              : (v) => setState(() {
                                  if (v != null &&
                                      !_selectedFestivalIds.contains(v)) {
                                    _selectedFestivalIds.add(v);
                                  }
                                }),
                          decoration: InputDecoration(
                            hintText: festivals.isEmpty
                                ? 'No approved festivals available'
                                : 'Select festival',
                            hintStyle: const TextStyle(
                              fontSize: 13,
                              color: CmsThemeColors.inputHint,
                            ),
                            filled: true,
                            fillColor: CmsColors.bg,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: CmsColors.border,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: CmsColors.border,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: CmsColors.orange,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_selectedFestivalIds.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _selectedFestivalIds
                        .map(
                          (id) => _Chip(
                            label: _festivalLabelById(id),
                            onRemove: () =>
                                setState(() => _selectedFestivalIds.remove(id)),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            );
          }),
        ],
      ),
      const SizedBox(height: 16),
      CmsFormCard(
        title: 'Purpose of the Ritual',
        children: [
          CmsRichTextField(
            label: 'Purpose: Why',
            initialValue: _purposeWhyRich,
            onChanged: (v) => setState(() => _purposeWhyRich = v),
          ),
          const SizedBox(height: 12),
          const Text(
            'Purpose Benefits',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: CmsColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          _InputRow(
            ctrl: _purposeBenefitsCtrl,
            hint: 'Add purpose benefit',
            onAdd: () => setState(
              () => _addChipValue(_purposeBenefitsCtrl, _purposeBenefits),
            ),
          ),
          if (_purposeBenefits.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _purposeBenefits.asMap().entries.map(
                    (e) => _Chip(
                      label: e.value,
                      onEdit: () => setState(
                        () => _startEditChipText(
                          _purposeBenefitsCtrl,
                          _purposeBenefits,
                          e.key,
                        ),
                      ),
                      onRemove: () =>
                          setState(() => _purposeBenefits.removeAt(e.key)),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 12),
          CmsRichTextField(
            label: 'Deity Summary: About',
            initialValue: _deitySummaryAboutRich,
            onChanged: (v) => setState(() => _deitySummaryAboutRich = v),
          ),
          const SizedBox(height: 12),
          const Text(
            'Deity Summary: Blessings',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: CmsColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          _InputRow(
            ctrl: _deitySummaryBlessingsCtrl,
            hint: 'Add blessing',
            onAdd: () => setState(
              () => _addChipValue(
                _deitySummaryBlessingsCtrl,
                _deitySummaryBlessings,
              ),
            ),
          ),
          if (_deitySummaryBlessings.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _deitySummaryBlessings.asMap().entries.map(
                    (e) => _Chip(
                      label: e.value,
                      onEdit: () => setState(
                        () => _startEditChipText(
                          _deitySummaryBlessingsCtrl,
                          _deitySummaryBlessings,
                          e.key,
                        ),
                      ),
                      onRemove: () => setState(
                        () => _deitySummaryBlessings.removeAt(e.key),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
      const SizedBox(height: 16),
      CmsFormCard(
        title: 'Media',
        children: [
          CmsUploadBox(
            label: 'Thumbnail Image',
            icon: Icons.image_outlined,
            accept: '800 × 800 px, JPG, PNG up to 5MB',
            mediaType: PickMediaType.image,
            initialUrl: _imageUrl,
            onPicked: (f) => setState(() => _pickedImage = f),
            onRemoved: () => setState(() {
              if (_pickedImage != null) {
                _pickedImage = null;
              } else {
                _imageUrl = null;
              }
            }),
          ),
        ],
      ),
    ],
  );

  Widget _rightCol(bool loading) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Required items
      CmsFormCard(
        title: 'Preparation Items (Before You Begin)',
        children: [
          _InputRow(
            ctrl: _itemCtrl,
            hint: 'Add item (e.g. Incense, Flowers...)',
            onAdd: () {
              if (_itemCtrl.text.trim().isNotEmpty) {
                setState(() => _items.add(_itemCtrl.text.trim()));
                _itemCtrl.clear();
              }
            },
          ),
          if (_items.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _items.asMap().entries.map(
                    (e) => _Chip(
                      label: e.value,
                      onEdit: () => setState(
                        () => _startEditChipText(_itemCtrl, _items, e.key),
                      ),
                      onRemove: () => setState(() => _items.removeAt(e.key)),
                    ),
                  )
                  .toList(),
            ),
          ] else
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text(
                'No items added yet',
                style: TextStyle(fontSize: 12, color: CmsColors.textSecond),
              ),
            ),
        ],
      ),
      const SizedBox(height: 16),
      CmsFormCard(
        title: 'Personal & Space Preparation',
        children: [
          const Text(
            'Personal Preparation',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: CmsColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          _InputRow(
            ctrl: _prepPersonalCtrl,
            hint: 'Add personal preparation',
            onAdd: () => setState(
              () => _addChipValue(_prepPersonalCtrl, _preparationPersonal),
            ),
          ),
          if (_preparationPersonal.isNotEmpty) ...[
            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _preparationPersonal.asMap().entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: _LineChip(
                        label: e.value,
                        onEdit: () => setState(
                          () => _startEditChipText(
                            _prepPersonalCtrl,
                            _preparationPersonal,
                            e.key,
                          ),
                        ),
                        onRemove: () => setState(
                          () => _preparationPersonal.removeAt(e.key),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 12),
          const Text(
            'Space Preparation',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: CmsColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          _InputRow(
            ctrl: _prepSpaceCtrl,
            hint: 'Add space preparation',
            onAdd: () => setState(
              () => _addChipValue(_prepSpaceCtrl, _preparationSpace),
            ),
          ),
          if (_preparationSpace.isNotEmpty) ...[
            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _preparationSpace.asMap().entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: _LineChip(
                        label: e.value,
                        onEdit: () => setState(
                          () => _startEditChipText(
                            _prepSpaceCtrl,
                            _preparationSpace,
                            e.key,
                          ),
                        ),
                        onRemove: () => setState(
                          () => _preparationSpace.removeAt(e.key),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
      const SizedBox(height: 16),

      // Steps
      CmsFormCard(
        title: 'Step-by-Step Prayer Process',
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _editingStepIndex != null
                      ? 'Edit step'
                      : _stepEntries.isNotEmpty
                      ? 'Add another step'
                      : 'Add step',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: CmsColors.textSecond,
                  ),
                ),
              ),
              _cmsClickable(
                onTap: _toggleStepEditor,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: CmsColors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _showStepEditor ? Icons.remove : Icons.add,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          if (_showStepEditor) ...[
            const SizedBox(height: 10),
            CmsFormField(
              label: 'Step Title',
              hint: 'e.g. Invocation',
              controller: _stepTitleCtrl,
              focusNode: _stepTitleFocus,
              onFieldSubmitted: (_) => _saveStepEntry(),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 10),
            CmsFormField(
              label: 'Step Description',
              hint: 'Describe this step...',
              controller: _stepDescCtrl,
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            _StepMultiImagePicker(
              imageUrls: _stepImageUrls,
              pickedImages: _stepPickedImages,
              onPick: _pickStepImages,
              onRemoveUrl: _removeStepImageUrl,
              onRemovePicked: _removeStepPickedImage,
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 10,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  if (_editingStepIndex != null)
                    TextButton(
                      onPressed: _cancelStepEdit,
                      style: TextButton.styleFrom().copyWith(
                        mouseCursor: _cmsButtonClickCursor,
                      ),
                      child: const Text('Cancel'),
                    ),
                  OutlinedButton.icon(
                    onPressed: _saveStepEntry,
                    icon: Icon(
                      _editingStepIndex != null
                          ? Icons.save_outlined
                          : Icons.add,
                      size: 16,
                    ),
                    label: Text(
                      _editingStepIndex != null
                          ? 'Update Step'
                          : _stepEntries.isNotEmpty
                          ? 'Add another step'
                          : 'Add Step',
                    ),
                    style: OutlinedButton.styleFrom().copyWith(
                      mouseCursor: _cmsButtonClickCursor,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_stepEntries.isNotEmpty) ...[
            const SizedBox(height: 12),
            ..._stepEntries.asMap().entries.map(
              (e) => _StepRow(
                index: e.key + 1,
                text: e.value.description.trim().isEmpty
                    ? e.value.title
                    : '${e.value.title}\n${e.value.description}',
                imageUrls: e.value.imageUrls,
                pickedImages: e.value.pickedImages,
                isEditing: _editingStepIndex == e.key,
                onEdit: () => _startEditStep(e.key),
                onRemove: () => _removeStep(e.key),
              ),
            ),
          ] else
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text(
                'No steps added yet',
                style: TextStyle(fontSize: 12, color: CmsColors.textSecond),
              ),
            ),
        ],
      ),
      const SizedBox(height: 24),
      CmsFormCard(
        title: 'Mantras & Chanting',
        children: [
          CmsRichTextField(
            label: 'Mantra: Primary',
            initialValue: _mantraPrimaryRich,
            onChanged: (v) => setState(() => _mantraPrimaryRich = v),
          ),
          const SizedBox(height: 12),
          CmsFormField(
            label: 'Mantra: Repetitions',
            hint: 'e.g. 11 times',
            controller: _mantraRepetitionsCtrl,
          ),
          const SizedBox(height: 12),
          const Text(
            'Mantra: Additional',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: CmsColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          _InputRow(
            ctrl: _mantraAdditionalCtrl,
            hint: 'Add additional mantra',
            onAdd: () => setState(
              () => _addChipValue(_mantraAdditionalCtrl, _mantraAdditional),
            ),
          ),
          if (_mantraAdditional.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _mantraAdditional.asMap().entries.map(
                    (e) => _Chip(
                      label: e.value,
                      onEdit: () => setState(
                        () => _startEditChipText(
                          _mantraAdditionalCtrl,
                          _mantraAdditional,
                          e.key,
                        ),
                      ),
                      onRemove: () =>
                          setState(() => _mantraAdditional.removeAt(e.key)),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 12),
          CmsRichTextField(
            label: 'Mantra: Meaning',
            initialValue: _mantraMeaningRich,
            onChanged: (v) => setState(() => _mantraMeaningRich = v),
          ),
        ],
      ),
      const SizedBox(height: 16),
      CmsFormCard(
        title: 'Spiritual Significance of Key Actions',
        children: [
          _KeyValueEditor(
            heading: 'Offerings Meaning',
            showEditor: _showOfferingsEditor,
            editingIndex: _editingOfferingsIndex,
            onToggle: () => setState(() {
              if (_showOfferingsEditor) {
                _clearKeyValueEditor(
                  titleCtrl: _offeringsTitleCtrl,
                  descCtrl: _offeringsDescCtrl,
                  onCleared: () {
                    _editingOfferingsIndex = null;
                    _showOfferingsEditor = false;
                  },
                );
              } else {
                _editingOfferingsIndex = null;
                _showOfferingsEditor = true;
              }
            }),
            titleCtrl: _offeringsTitleCtrl,
            descCtrl: _offeringsDescCtrl,
            onAdd: () => setState(
              () => _addKeyValueEntry(
                titleCtrl: _offeringsTitleCtrl,
                descCtrl: _offeringsDescCtrl,
                target: _offeringsMeaningEntries,
                editingIndex: _editingOfferingsIndex,
                onAdded: () {
                  _editingOfferingsIndex = null;
                },
              ),
            ),
            entries: _offeringsMeaningEntries,
            onEdit: (i) => setState(
              () => _startEditKeyValueEntry(
                index: i,
                target: _offeringsMeaningEntries,
                titleCtrl: _offeringsTitleCtrl,
                descCtrl: _offeringsDescCtrl,
                onStarted: () {
                  _editingOfferingsIndex = i;
                  _showOfferingsEditor = true;
                },
              ),
            ),
            onRemove: (i) => setState(() {
              if (_editingOfferingsIndex == i) {
                _clearKeyValueEditor(
                  titleCtrl: _offeringsTitleCtrl,
                  descCtrl: _offeringsDescCtrl,
                  onCleared: () {
                    _editingOfferingsIndex = null;
                    _showOfferingsEditor = false;
                  },
                );
              } else if (_editingOfferingsIndex != null &&
                  i < _editingOfferingsIndex!) {
                _editingOfferingsIndex = _editingOfferingsIndex! - 1;
              }
              _offeringsMeaningEntries.removeAt(i);
            }),
          ),
          const SizedBox(height: 12),
          _KeyValueEditor(
            heading: 'Actions Meaning',
            showEditor: _showActionsEditor,
            editingIndex: _editingActionsIndex,
            onToggle: () => setState(() {
              if (_showActionsEditor) {
                _clearKeyValueEditor(
                  titleCtrl: _actionsTitleCtrl,
                  descCtrl: _actionsDescCtrl,
                  onCleared: () {
                    _editingActionsIndex = null;
                    _showActionsEditor = false;
                  },
                );
              } else {
                _editingActionsIndex = null;
                _showActionsEditor = true;
              }
            }),
            titleCtrl: _actionsTitleCtrl,
            descCtrl: _actionsDescCtrl,
            onAdd: () => setState(
              () => _addKeyValueEntry(
                titleCtrl: _actionsTitleCtrl,
                descCtrl: _actionsDescCtrl,
                target: _actionsMeaningEntries,
                editingIndex: _editingActionsIndex,
                onAdded: () {
                  _editingActionsIndex = null;
                },
              ),
            ),
            entries: _actionsMeaningEntries,
            onEdit: (i) => setState(
              () => _startEditKeyValueEntry(
                index: i,
                target: _actionsMeaningEntries,
                titleCtrl: _actionsTitleCtrl,
                descCtrl: _actionsDescCtrl,
                onStarted: () {
                  _editingActionsIndex = i;
                  _showActionsEditor = true;
                },
              ),
            ),
            onRemove: (i) => setState(() {
              if (_editingActionsIndex == i) {
                _clearKeyValueEditor(
                  titleCtrl: _actionsTitleCtrl,
                  descCtrl: _actionsDescCtrl,
                  onCleared: () {
                    _editingActionsIndex = null;
                    _showActionsEditor = false;
                  },
                );
              } else if (_editingActionsIndex != null &&
                  i < _editingActionsIndex!) {
                _editingActionsIndex = _editingActionsIndex! - 1;
              }
              _actionsMeaningEntries.removeAt(i);
            }),
          ),
          const SizedBox(height: 12),
          _KeyValueEditor(
            heading: 'Other Symbolism',
            showEditor: _showOtherSymbolismEditor,
            editingIndex: _editingOtherSymbolismIndex,
            onToggle: () => setState(() {
              if (_showOtherSymbolismEditor) {
                _clearKeyValueEditor(
                  titleCtrl: _symbolismTitleCtrl,
                  descCtrl: _symbolismDescCtrl,
                  onCleared: () {
                    _editingOtherSymbolismIndex = null;
                    _showOtherSymbolismEditor = false;
                  },
                );
              } else {
                _editingOtherSymbolismIndex = null;
                _showOtherSymbolismEditor = true;
              }
            }),
            titleCtrl: _symbolismTitleCtrl,
            descCtrl: _symbolismDescCtrl,
            onAdd: () => setState(
              () => _addKeyValueEntry(
                titleCtrl: _symbolismTitleCtrl,
                descCtrl: _symbolismDescCtrl,
                target: _otherSymbolismEntries,
                editingIndex: _editingOtherSymbolismIndex,
                onAdded: () {
                  _editingOtherSymbolismIndex = null;
                },
              ),
            ),
            entries: _otherSymbolismEntries,
            onEdit: (i) => setState(
              () => _startEditKeyValueEntry(
                index: i,
                target: _otherSymbolismEntries,
                titleCtrl: _symbolismTitleCtrl,
                descCtrl: _symbolismDescCtrl,
                onStarted: () {
                  _editingOtherSymbolismIndex = i;
                  _showOtherSymbolismEditor = true;
                },
              ),
            ),
            onRemove: (i) => setState(() {
              if (_editingOtherSymbolismIndex == i) {
                _clearKeyValueEditor(
                  titleCtrl: _symbolismTitleCtrl,
                  descCtrl: _symbolismDescCtrl,
                  onCleared: () {
                    _editingOtherSymbolismIndex = null;
                    _showOtherSymbolismEditor = false;
                  },
                );
              } else if (_editingOtherSymbolismIndex != null &&
                  i < _editingOtherSymbolismIndex!) {
                _editingOtherSymbolismIndex = _editingOtherSymbolismIndex! - 1;
              }
              _otherSymbolismEntries.removeAt(i);
            }),
          ),
        ],
      ),
      const SizedBox(height: 24),
      CmsFormCard(
        title: 'Devotional Guidance',
        children: [
          const Text(
            'What mindset to maintain',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: CmsColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          _InputRow(
            ctrl: _guidanceMindsetCtrl,
            hint: 'Add mindset',
            onAdd: () => setState(
              () => _addChipValue(_guidanceMindsetCtrl, _guidanceMindset),
            ),
          ),
          if (_guidanceMindset.isNotEmpty) ...[
            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _guidanceMindset.asMap().entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: _LineChip(
                        label: e.value,
                        onEdit: () => setState(
                          () => _startEditChipText(
                            _guidanceMindsetCtrl,
                            _guidanceMindset,
                            e.key,
                          ),
                        ),
                        onRemove: () =>
                            setState(() => _guidanceMindset.removeAt(e.key)),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 12),
          const Text(
            'What to avoid',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: CmsColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          _InputRow(
            ctrl: _guidanceAvoidCtrl,
            hint: 'Add avoid point',
            onAdd: () => setState(
              () => _addChipValue(_guidanceAvoidCtrl, _guidanceAvoid),
            ),
          ),
          if (_guidanceAvoid.isNotEmpty) ...[
            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _guidanceAvoid.asMap().entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: _LineChip(
                        label: e.value,
                        onEdit: () => setState(
                          () => _startEditChipText(
                            _guidanceAvoidCtrl,
                            _guidanceAvoid,
                            e.key,
                          ),
                        ),
                        onRemove: () =>
                            setState(() => _guidanceAvoid.removeAt(e.key)),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
      const SizedBox(height: 16),
      CmsFormCard(
        title: 'Completion & Integration',
        children: [
          const Text(
            'How to close the ritual',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: CmsColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          _InputRow(
            ctrl: _completionClosureCtrl,
            hint: 'Add closure point',
            onAdd: () => setState(
              () => _addChipValue(_completionClosureCtrl, _completionClosure),
            ),
          ),
          if (_completionClosure.isNotEmpty) ...[
            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _completionClosure.asMap().entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: _LineChip(
                        label: e.value,
                        onEdit: () => setState(
                          () => _startEditChipText(
                            _completionClosureCtrl,
                            _completionClosure,
                            e.key,
                          ),
                        ),
                        onRemove: () =>
                            setState(() => _completionClosure.removeAt(e.key)),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 12),
          const Text(
            'How to carry energy forward',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: CmsColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          _InputRow(
            ctrl: _completionIntegrationCtrl,
            hint: 'Add integration point',
            onAdd: () => setState(
              () => _addChipValue(
                _completionIntegrationCtrl,
                _completionIntegration,
              ),
            ),
          ),
          if (_completionIntegration.isNotEmpty) ...[
            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _completionIntegration.asMap().entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: _LineChip(
                        label: e.value,
                        onEdit: () => setState(
                          () => _startEditChipText(
                            _completionIntegrationCtrl,
                            _completionIntegration,
                            e.key,
                          ),
                        ),
                        onRemove: () => setState(
                          () => _completionIntegration.removeAt(e.key),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 12),
          const Text(
            'Divine boons and gifts',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: CmsColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          _InputRow(
            ctrl: _completionBenefitsCtrl,
            hint: 'Add boon / gift',
            onAdd: () => setState(
              () => _addChipValue(_completionBenefitsCtrl, _completionBenefits),
            ),
          ),
          if (_completionBenefits.isNotEmpty) ...[
            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _completionBenefits.asMap().entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: _LineChip(
                        label: e.value,
                        onEdit: () => setState(
                          () => _startEditChipText(
                            _completionBenefitsCtrl,
                            _completionBenefits,
                            e.key,
                          ),
                        ),
                        onRemove: () =>
                            setState(() => _completionBenefits.removeAt(e.key)),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
      const SizedBox(height: 16),
      CmsFormCard(
        title: 'Blessings from Sathya',
        children: [
          CmsRichTextField(
            label: 'Blessings',
            initialValue: _blessingsRich,
            onChanged: (v) => setState(() => _blessingsRich = v),
          ),
        ],
      ),
      const SizedBox(height: 24),

      // Action buttons
      Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: loading ? null : widget.onCancel,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: CmsColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ).copyWith(mouseCursor: _cmsButtonClickCursor),
              child: const Text(
                'Cancel',
                style: TextStyle(color: CmsColors.textSecond),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton(
              onPressed: loading ? null : () => _submit(isDraft: true),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: CmsColors.orange.withOpacity(0.5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ).copyWith(mouseCursor: _cmsButtonClickCursor),
              child: Text(
                'Save Draft',
                style: TextStyle(
                  color: loading ? CmsColors.textSecond : CmsColors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: loading ? null : () => _submit(isDraft: false),
              style: ElevatedButton.styleFrom(
                backgroundColor: CmsColors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ).copyWith(mouseCursor: _cmsButtonClickCursor),
              child: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _isEdit ? 'Save Changes' : 'Submit for Approval',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    ],
  );
}

// ════════════════════════════════════════════════════════════════
// SMALL HELPER WIDGETS
// ════════════════════════════════════════════════════════════════
class _StepDraft {
  const _StepDraft({
    required this.title,
    required this.description,
    this.imageUrls = const [],
    this.pickedImages = const [],
  });
  final String title;
  final String description;
  final List<String> imageUrls;
  final List<PickedFile> pickedImages;
}

class _KeyValueEditor extends StatefulWidget {
  const _KeyValueEditor({
    required this.heading,
    required this.showEditor,
    required this.onToggle,
    required this.titleCtrl,
    required this.descCtrl,
    required this.onAdd,
    required this.entries,
    required this.onRemove,
    this.onEdit,
    this.editingIndex,
  });

  final String heading;
  final bool showEditor;
  final VoidCallback onToggle;
  final TextEditingController titleCtrl;
  final TextEditingController descCtrl;
  final VoidCallback onAdd;
  final List<Map<String, String>> entries;
  final ValueChanged<int> onRemove;
  final ValueChanged<int>? onEdit;
  final int? editingIndex;

  @override
  State<_KeyValueEditor> createState() => _KeyValueEditorState();
}

class _KeyValueEditorState extends State<_KeyValueEditor> {
  final FocusNode _titleFocus = FocusNode();

  @override
  void dispose() {
    _titleFocus.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _KeyValueEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showEditor && !oldWidget.showEditor) {
      _focusTitleField();
    } else if (widget.showEditor &&
        widget.editingIndex != null &&
        widget.editingIndex != oldWidget.editingIndex) {
      _focusTitleField();
    }
  }

  void _focusTitleField() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _titleFocus.requestFocus();
        final text = widget.titleCtrl.text;
        widget.titleCtrl.selection = TextSelection.collapsed(offset: text.length);
      });
    });
  }

  void _handleAdd() {
    widget.onAdd();
    _focusTitleField();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              widget.heading,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: CmsColors.textSecond,
              ),
            ),
          ),
          _cmsClickable(
            onTap: widget.onToggle,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: CmsColors.orange,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                widget.showEditor ? Icons.remove : Icons.add,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
      if (widget.showEditor) ...[
        const SizedBox(height: 10),
        CmsFormField(
          label: '${widget.heading} Title',
          hint: 'Enter title',
          controller: widget.titleCtrl,
          focusNode: _titleFocus,
          onFieldSubmitted: (_) => _handleAdd(),
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: 10),
        CmsFormField(
          label: '${widget.heading} Description',
          hint: 'Enter description',
          controller: widget.descCtrl,
          maxLines: 3,
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton.icon(
            onPressed: _handleAdd,
            icon: Icon(
              widget.editingIndex != null ? Icons.save_outlined : Icons.add,
              size: 16,
            ),
            label: Text(widget.editingIndex != null ? 'Update' : 'Add'),
            style: OutlinedButton.styleFrom().copyWith(
              mouseCursor: _cmsButtonClickCursor,
            ),
          ),
        ),
      ],
      if (widget.entries.isNotEmpty) ...[
        const SizedBox(height: 10),
        ...widget.entries.asMap().entries.map(
          (e) => _StepRow(
            index: e.key + 1,
            text: (e.value['description'] ?? '').trim().isEmpty
                ? (e.value['title'] ?? '')
                : '${e.value['title'] ?? ''}\n${e.value['description'] ?? ''}',
            isEditing: widget.editingIndex == e.key,
            onEdit: widget.onEdit == null ? null : () => widget.onEdit!(e.key),
            onRemove: () => widget.onRemove(e.key),
          ),
        ),
      ] else
        const Padding(
          padding: EdgeInsets.only(top: 10),
          child: Text(
            'No entries added yet',
            style: TextStyle(fontSize: 12, color: CmsColors.textSecond),
          ),
        ),
    ],
  );
}

class _InputRow extends StatefulWidget {
  const _InputRow({
    required this.ctrl,
    required this.hint,
    required this.onAdd,
  });
  final TextEditingController ctrl;
  final String hint;
  final VoidCallback onAdd;

  @override
  State<_InputRow> createState() => _InputRowState();
}

class _InputRowState extends State<_InputRow> {
  final FocusNode _focus = FocusNode();
  String _previousText = '';

  @override
  void initState() {
    super.initState();
    _previousText = widget.ctrl.text;
    widget.ctrl.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.ctrl.removeListener(_onControllerChanged);
    _focus.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    final text = widget.ctrl.text;
    if (!_focus.hasFocus && text != _previousText && text.isNotEmpty) {
      _requestFocus();
    }
    _previousText = text;
  }

  void _requestFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focus.requestFocus();
      widget.ctrl.selection = TextSelection.collapsed(
        offset: widget.ctrl.text.length,
      );
    });
  }

  void _handleAdd() {
    widget.onAdd();
    _requestFocus();
  }

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: CmsColors.bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: CmsColors.border),
          ),
          child: TextField(
            controller: widget.ctrl,
            focusNode: _focus,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleAdd(),
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: widget.hint,
              border: InputBorder.none,
              hintStyle: const TextStyle(
                color: Color(0xFFAAAAAA),
                fontSize: 13,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
        ),
      ),
      const SizedBox(width: 8),
      _cmsClickable(
        onTap: _handleAdd,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: CmsColors.orange,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 18),
        ),
      ),
    ],
  );
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.onRemove,
    this.onEdit,
  });
  final String label;
  final VoidCallback onRemove;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(
      maxWidth: MediaQuery.of(context).size.width * 0.78,
    ),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: CmsColors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CmsColors.orange.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: CmsColors.orangeDark),
            ),
          ),
          if (onEdit != null) ...[
            const SizedBox(width: 5),
            _cmsClickable(
              onTap: onEdit!,
              child: const Icon(
                Icons.edit_outlined,
                size: 12,
                color: CmsColors.orangeDark,
              ),
            ),
          ],
          const SizedBox(width: 5),
          _cmsClickable(
            onTap: onRemove,
            child: const Icon(
              Icons.close,
              size: 12,
              color: CmsColors.orangeDark,
            ),
          ),
        ],
      ),
    ),
  );
}

class _LineChip extends StatelessWidget {
  const _LineChip({
    required this.label,
    required this.onRemove,
    this.onEdit,
  });
  final String label;
  final VoidCallback onRemove;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(
      maxWidth: MediaQuery.of(context).size.width * 0.78,
    ),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8EEE2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CmsColors.orange.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: CmsColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onEdit != null) ...[
            const SizedBox(width: 6),
            _cmsClickable(
              onTap: onEdit!,
              child: const Icon(
                Icons.edit_outlined,
                size: 13,
                color: CmsColors.textSecond,
              ),
            ),
          ],
          const SizedBox(width: 6),
          _cmsClickable(
            onTap: onRemove,
            child: const Icon(
              Icons.close,
              size: 13,
              color: CmsColors.textSecond,
            ),
          ),
        ],
      ),
    ),
  );
}

class _StepMultiImagePicker extends StatelessWidget {
  const _StepMultiImagePicker({
    required this.imageUrls,
    required this.pickedImages,
    required this.onPick,
    required this.onRemoveUrl,
    required this.onRemovePicked,
  });

  final List<String> imageUrls;
  final List<PickedFile> pickedImages;
  final Future<void> Function() onPick;
  final ValueChanged<int> onRemoveUrl;
  final ValueChanged<int> onRemovePicked;

  @override
  Widget build(BuildContext context) {
    final hasImages = imageUrls.isNotEmpty || pickedImages.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step Images',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: CmsColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          '800 × 800 px recommended',
          style: TextStyle(fontSize: 11, color: CmsColors.textSecond),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onPick,
          icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
          label: const Text('Upload Images'),
          style: OutlinedButton.styleFrom().copyWith(
            mouseCursor: _cmsButtonClickCursor,
          ),
        ),
        if (hasImages) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < imageUrls.length; i++)
                _StepImageThumb(
                  child: Image.network(
                    imageUrls[i],
                    width: 88,
                    height: 88,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _brokenThumb(),
                  ),
                  onRemove: () => onRemoveUrl(i),
                ),
              for (var i = 0; i < pickedImages.length; i++)
                _StepImageThumb(
                  child: Image.memory(
                    Uint8List.fromList(pickedImages[i].bytes),
                    width: 88,
                    height: 88,
                    fit: BoxFit.cover,
                  ),
                  onRemove: () => onRemovePicked(i),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _brokenThumb() {
    return Container(
      width: 88,
      height: 88,
      color: CmsColors.bg,
      alignment: Alignment.center,
      child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
    );
  }
}

class _StepImageThumb extends StatelessWidget {
  const _StepImageThumb({required this.child, required this.onRemove});

  final Widget child;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(borderRadius: BorderRadius.circular(8), child: child),
        Positioned(
          top: -6,
          right: -6,
          child: _cmsClickable(
            onTap: onRemove,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: Colors.black87,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 12, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.index,
    required this.text,
    required this.onRemove,
    this.onEdit,
    this.imageUrls = const [],
    this.pickedImages = const [],
    this.isEditing = false,
  });
  final int index;
  final String text;
  final VoidCallback onRemove;
  final VoidCallback? onEdit;
  final List<String> imageUrls;
  final List<PickedFile> pickedImages;
  final bool isEditing;

  Widget _imageStrip() {
    if (imageUrls.isEmpty && pickedImages.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 108,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final url in imageUrls)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  url,
                  width: 108,
                  height: 108,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 108,
                    height: 108,
                    color: CmsColors.bg,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.broken_image_outlined,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
          for (final file in pickedImages)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  Uint8List.fromList(file.bytes),
                  width: 108,
                  height: 108,
                  fit: BoxFit.cover,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final parts = text.split('\n');
    final title = parts.first.trim();
    final description = parts.length > 1
        ? parts.sublist(1).join('\n').trim()
        : '';
    final hasImages = imageUrls.isNotEmpty || pickedImages.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isEditing ? CmsColors.orange.withValues(alpha: 0.06) : null,
          borderRadius: BorderRadius.circular(10),
          border: isEditing
              ? Border.all(color: CmsColors.orange.withValues(alpha: 0.35))
              : null,
        ),
        child: Padding(
          padding: EdgeInsets.all(isEditing ? 10 : 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 22,
                height: 22,
                margin: const EdgeInsets.only(top: 1),
                decoration: const BoxDecoration(
                  color: CmsColors.orange,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$index',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: CmsColors.textPrimary,
                        ),
                        children: [
                          TextSpan(
                            text: title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                          ),
                          if (description.isNotEmpty) ...[
                            const TextSpan(text: '\n'),
                            TextSpan(text: description),
                          ],
                        ],
                      ),
                    ),
                    if (hasImages) ...[
                      const SizedBox(height: 10),
                      _imageStrip(),
                    ],
                  ],
                ),
              ),
              if (onEdit != null) ...[
                _cmsClickable(
                  onTap: onEdit!,
                  child: Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: isEditing ? CmsColors.orange : Colors.grey,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              _cmsClickable(
                onTap: onRemove,
                child: const Icon(Icons.close, size: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmBtn extends StatelessWidget {
  const _SmBtn(this.label, this.color, this.onTap);
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _cmsClickable(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}
