// lib/features/cms/presentation/contents/cms_festivals_content.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/core/services/media_upload_service.dart';
import 'package:satya_devotte_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:satya_devotte_app/core/models/festival_model.dart';
import 'package:satya_devotte_app/features/cms/presentation/controllers/pooja_controller.dart';
import 'package:satya_devotte_app/features/cms/presentation/controllers/festival_controller.dart';
import 'package:satya_devotte_app/features/cms/presentation/pages/cms_shell_page.dart';
import 'package:satya_devotte_app/features/cms/presentation/widgets/cms_shared_widgets.dart';
import 'package:satya_devotte_app/features/cms/presentation/widgets/cms_upload_box.dart';

class CmsFestivalsContent extends StatefulWidget {
  const CmsFestivalsContent({super.key});

  @override
  State<CmsFestivalsContent> createState() => _CmsFestivalsContentState();
}

class _CmsFestivalsContentState extends State<CmsFestivalsContent> {
  late final FestivalController _ctrl;
  bool _showForm = false;
  FestivalModel? _editing;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<FestivalController>();
  }

  @override
  Widget build(BuildContext context) {
    if (_showForm) {
      return _FestivalForm(
        festival: _editing,
        ctrl: _ctrl,
        onCancel: () => setState(() {
          _showForm = false;
          _editing = null;
        }),
        onSaved: () {
          _ctrl.loadFestivals();
          setState(() {
            _showForm = false;
            _editing = null;
          });
        },
      );
    }
    return _FestivalList(
      ctrl: _ctrl,
      onAdd: () => setState(() {
        _editing = null;
        _showForm = true;
      }),
      onEdit: (f) => setState(() {
        _editing = f;
        _showForm = true;
      }),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// FESTIVAL LIST
// ════════════════════════════════════════════════════════════════
class _FestivalList extends StatelessWidget {
  const _FestivalList({
    required this.ctrl,
    required this.onAdd,
    required this.onEdit,
  });

  final FestivalController ctrl;
  final VoidCallback onAdd;
  final ValueChanged<FestivalModel> onEdit;

  static const _months = [
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
  static const _filters = ['All', 'Approved', 'Pending', 'Queued', 'Rejected'];

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width >= 768;

    return Column(
      children: [
        // ── SuperAdmin banner ─────────────────────────────────────
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
                    'Super Admin — Seeing all festivals. Pending festivals show Approve & Reject buttons.',
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
                  hint: 'Search festivals...',
                  onChanged: (_) {},
                ),
              ),
              const SizedBox(width: 12),
              Obx(
                () => ctrl.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: CmsColors.orange,
                        ),
                      )
                    : GestureDetector(
                        onTap: ctrl.loadFestivals,
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
                label: isWeb ? 'Add Festival' : 'Add',
                icon: Icons.add,
                onTap: onAdd,
              ),
            ],
          ),
        ),

        // ── Status filter tabs ────────────────────────────────────
        Container(
          color: CmsColors.white,
          padding: EdgeInsets.only(left: isWeb ? 24 : 16, bottom: 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Obx(
              () => Row(
                children: _filters.map((f) {
                  final isSel = ctrl.filter == f;
                  return GestureDetector(
                    onTap: () => ctrl.setFilter(f),
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
                          if (f == 'Pending' && ctrl.pendingCount > 0) ...[
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
                                '${ctrl.pendingCount}',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                          if (f == 'Queued' && ctrl.queuedCount > 0) ...[
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
                                '${ctrl.queuedCount}',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
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

        // ── Month picker — hidden for superadmin ─────────────────
        if (!Get.find<AuthController>().isSuperAdmin)
          Container(
            color: CmsColors.white,
            padding: EdgeInsets.only(
              left: isWeb ? 24 : 16,
              right: 16,
              bottom: 14,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Month',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: CmsColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Obx(
                    () => Row(
                      children: List.generate(12, (i) {
                        final isSel = ctrl.selectedMonth == i + 1;
                        return GestureDetector(
                          onTap: () => ctrl.setMonth(i + 1),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: isSel ? CmsColors.orange : CmsColors.bg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSel
                                    ? CmsColors.orange
                                    : CmsColors.border,
                              ),
                            ),
                            child: Text(
                              _months[i],
                              style: TextStyle(
                                color: isSel
                                    ? Colors.white
                                    : CmsColors.textSecond,
                                fontSize: 12,
                                fontWeight: isSel
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),

        const Divider(height: 1, color: CmsColors.border),

        // ── Content ───────────────────────────────────────────────
        Expanded(
          child: Obx(() {
            if (ctrl.isLoading) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: CmsColors.orange),
                    SizedBox(height: 14),
                    Text(
                      'Loading festivals...',
                      style: TextStyle(
                        color: CmsColors.textSecond,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }

            if (ctrl.error != null && ctrl.festivals.isEmpty) {
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
                      onTap: ctrl.loadFestivals,
                    ),
                  ],
                ),
              );
            }

            final list = ctrl.festivalsByMonth;

            if (list.isEmpty) {
              return CmsEmptyState(
                icon: Icons.celebration_outlined,
                title: 'No Festivals in ${_months[ctrl.selectedMonth - 1]}',
                subtitle: 'Add a festival or select a different month',
                actionLabel: 'Add Festival',
                onAction: onAdd,
              );
            }

            return RefreshIndicator(
              color: CmsColors.orange,
              onRefresh: ctrl.loadFestivals,
              child: ListView.separated(
                padding: EdgeInsets.all(isWeb ? 24 : 16),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) => _FestivalCard(
                  festival: list[i],
                  onEdit: () => onEdit(list[i]),
                  onDelete: () async {
                    final ok = await showCmsDeleteDialog(
                      ctx,
                      itemName: list[i].title,
                    );
                    if (ok == true) {
                      await ctrl.deleteFestival(list[i].id);
                      ctrl.loadFestivals();
                    }
                  },
                  onApprove: () => _approveDialog(ctx, list[i], ctrl),
                  onQueue: () => ctrl.queueFestival(list[i].id),
                  onReject: () => _rejectDialog(ctx, list[i], ctrl),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  void _approveDialog(
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
          crossAxisAlignment: CrossAxisAlignment.start,
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
              'This will publish the festival to all users.',
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
// FESTIVAL CARD
// ════════════════════════════════════════════════════════════════
class _FestivalCard extends StatelessWidget {
  const _FestivalCard({
    required this.festival,
    required this.onEdit,
    required this.onDelete,
    required this.onApprove,
    required this.onQueue,
    required this.onReject,
  });

  final FestivalModel festival;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onApprove;
  final VoidCallback onQueue;
  final VoidCallback onReject;

  Color get _statusColor {
    switch (festival.status) {
      case 'Approved':
        return Colors.green;
      case 'Pending':
        return CmsColors.orange;
      case 'Queued':
        return CmsColors.orangeDark;
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSuperAdmin = Get.find<AuthController>().isSuperAdmin;
    final isCreatorSuperAdmin =
        isSuperAdmin &&
        festival.createdBy == Get.find<AuthController>().currentUserId;

    // FIX: FestivalModel does not have a createdBy field.
    // All users can edit their own festivals; superadmin can edit all.
    // To restore owner-only edit, add createdBy to FestivalModel and
    // replace `true` below with:
    //   festival.createdBy == Get.find<AuthController>().currentUserId
    const canEdit = true;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CmsColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _statusColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          // Date badge
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: CmsColors.orange.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  festival.displayDay,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: CmsColors.orange,
                  ),
                ),
                Text(
                  festival.displayMonth,
                  style: const TextStyle(
                    fontSize: 10,
                    color: CmsColors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Info
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
                if (festival.locationDisplay.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    festival.locationDisplay,
                    style: const TextStyle(
                      fontSize: 12,
                      color: CmsColors.textSecond,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        festival.status,
                        style: TextStyle(
                          fontSize: 10,
                          color: _statusColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: CmsColors.bg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        festival.category,
                        style: const TextStyle(
                          fontSize: 10,
                          color: CmsColors.textSecond,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (festival.isGlobal)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Global',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Actions
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (canEdit)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CmsActionIcon(
                      icon: Icons.edit_outlined,
                      color: Colors.blue,
                      onTap: onEdit,
                    ),
                    const SizedBox(width: 6),
                    CmsActionIcon(
                      icon: Icons.delete_outline,
                      color: Colors.red,
                      onTap: onDelete,
                    ),
                  ],
                ),
              if (isSuperAdmin &&
                  (festival.status == 'Pending' ||
                      festival.status == 'Queued')) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isCreatorSuperAdmin) ...[
                      if (festival.status == 'Pending')
                        _SmBtn('Queued', CmsColors.orange, onQueue),
                      if (festival.status == 'Pending')
                        const SizedBox(width: 6),
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

class _SmBtn extends StatelessWidget {
  const _SmBtn(this.label, this.color, this.onTap);
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
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

// ════════════════════════════════════════════════════════════════
// ADD / EDIT FESTIVAL FORM
// ════════════════════════════════════════════════════════════════
class _FestivalForm extends StatefulWidget {
  const _FestivalForm({
    this.festival,
    required this.ctrl,
    required this.onCancel,
    required this.onSaved,
  });
  final FestivalModel? festival;
  final FestivalController ctrl;
  final VoidCallback onCancel;
  final VoidCallback onSaved;

  @override
  State<_FestivalForm> createState() => _FestivalFormState();
}

class _FestivalFormState extends State<_FestivalForm> {
  // ── Text controllers ──────────────────────────────────────────
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _locationCityCtrl;
  late final TextEditingController _locationStateCtrl;
  late final TextEditingController _locationCountryCtrl;
  late final TextEditingController _notifyDaysCtrl;

  // ── FIX: properly declared state fields ───────────────────────
  PickedFile? _pickedImage;
  String? _existingImageUrl;

  // ── Rituals ───────────────────────────────────────────────────
  final List<String> _selectedRitualIds = [];
  final List<String> _selectedRitualNames = [];

  // ── Form values ───────────────────────────────────────────────
  DateTime? _date;
  DateTime? _endDate;
  late String _category;
  late bool _isGlobal;
  late bool _notifyUsers;

  static const _categories = ['MAJOR', 'MINOR', 'FASTING', 'ECLIPSE'];

  bool get _isEdit => widget.festival != null;

  @override
  void initState() {
    super.initState();
    final f = widget.festival;

    _titleCtrl = TextEditingController(text: f?.title ?? '');
    _descCtrl = TextEditingController(text: f?.description ?? '');
    _locationCityCtrl = TextEditingController(text: f?.locationCity ?? '');
    _locationStateCtrl = TextEditingController(text: f?.locationState ?? '');
    _locationCountryCtrl = TextEditingController(
      text: f?.locationCountry ?? 'India',
    );
    _notifyDaysCtrl = TextEditingController(
      text: (f?.notificationDaysBefore ?? 0).toString(),
    );

    _existingImageUrl = f?.imageUrl;

    _category = _categories.contains(f?.category) ? f!.category : 'MAJOR';
    _isGlobal = f?.isGlobal ?? false;
    _notifyUsers = f?.notifyUsers ?? false;

    _date = _parseDate(f?.date);
    _endDate = _parseDate(f?.endDate);

    if (f?.rituals != null && f!.rituals!.isNotEmpty) {
      _selectedRitualNames.addAll(f.rituals!.split(', '));
    }
  }

  DateTime? _parseDate(String? s) {
    if (s == null || s.isEmpty) return null;
    try {
      final p = s.split('-');
      if (p.length == 3 && p[0].length == 2) {
        return DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
      }
      return DateTime.parse(s);
    } catch (_) {
      return null;
    }
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.year}';

  Future<void> _pickDate(bool isEnd) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isEnd ? _endDate : _date) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: CmsColors.orange,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isEnd) {
          _endDate = picked;
        } else {
          _date = picked;
        }
      });
    }
  }

  String? _validate() {
    if (_titleCtrl.text.trim().isEmpty) return 'Festival title is required';
    if (_date == null) return 'Start date is required';
    return null;
  }

  Map<String, dynamic> _buildBody() {
    final body = <String, dynamic>{
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'date': _formatDate(_date!),
      'category': _category,
      'isGlobal': _isGlobal,
      'location': {
        'city': _locationCityCtrl.text.trim(),
        'state': _locationStateCtrl.text.trim(),
        'country': _locationCountryCtrl.text.trim().isEmpty
            ? 'India'
            : _locationCountryCtrl.text.trim(),
      },
      'notifyUsers': _notifyUsers,
      'notificationDaysBefore': int.tryParse(_notifyDaysCtrl.text) ?? 0,
    };

    if (_endDate != null) body['endDate'] = _formatDate(_endDate!);
    if (_selectedRitualIds.isNotEmpty) body['rituals'] = _selectedRitualIds;

    return body;
  }

  Future<void> _submit() async {
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

    final body = _buildBody();
    bool ok;

    if (_isEdit) {
      ok = await widget.ctrl.updateFestival(
        widget.festival!.id,
        body,
        image: _pickedImage,
      );
    } else {
      ok = await widget.ctrl.createFestival(body, image: _pickedImage);
    }

    if (ok) widget.onSaved();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCityCtrl.dispose();
    _locationStateCtrl.dispose();
    _locationCountryCtrl.dispose();
    _notifyDaysCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width >= 768;

    return Obx(() {
      final loading = widget.ctrl.isSubmitting;
      return SingleChildScrollView(
        padding: EdgeInsets.all(isWeb ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
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
                  _isEdit ? 'Edit Festival' : 'Add Festival',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: CmsColors.textPrimary,
                  ),
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

  Widget _leftCol() => CmsFormCard(
    title: 'Festival Details',
    children: [
      CmsFormField(
        label: 'Festival Title *',
        hint: 'e.g. Maha Shivratri',
        controller: _titleCtrl,
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: _DatePickerField(
              label: 'Start Date *',
              value: _date,
              onTap: () => _pickDate(false),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _DatePickerField(
              label: 'End Date (optional)',
              value: _endDate,
              onTap: () => _pickDate(true),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      CmsDropdownField(
        label: 'Category',
        items: _categories,
        initialValue: _category,
        onChanged: (v) => setState(() => _category = v ?? 'MAJOR'),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: CmsFormField(
              label: 'City',
              hint: 'e.g. Hyderabad',
              controller: _locationCityCtrl,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CmsFormField(
              label: 'State',
              hint: 'e.g. Telangana',
              controller: _locationStateCtrl,
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      CmsFormField(
        label: 'Country',
        hint: 'India',
        controller: _locationCountryCtrl,
      ),
      const SizedBox(height: 12),
      CmsFormField(
        label: 'Description',
        hint: 'Brief description of the festival...',
        controller: _descCtrl,
        maxLines: 3,
      ),
      const SizedBox(height: 12),
      _PoojaPickerField(
        selectedIds: _selectedRitualIds,
        selectedNames: _selectedRitualNames,
        onChanged: () => setState(() {}),
      ),
    ],
  );

  Widget _rightCol(bool loading) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      CmsFormCard(
        title: 'Settings',
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Global Festival',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: CmsColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Visible to all users',
                      style: TextStyle(
                        fontSize: 11,
                        color: CmsColors.textSecond,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isGlobal,
                activeColor: CmsColors.orange,
                onChanged: (v) => setState(() => _isGlobal = v),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Send Notification',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: CmsColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Push notification to users',
                      style: TextStyle(
                        fontSize: 11,
                        color: CmsColors.textSecond,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _notifyUsers,
                activeColor: CmsColors.orange,
                onChanged: (v) => setState(() => _notifyUsers = v),
              ),
            ],
          ),
          if (_notifyUsers) ...[
            const SizedBox(height: 12),
            CmsFormField(
              label: 'Days Before Festival to Notify',
              hint: 'e.g. 3',
              controller: _notifyDaysCtrl,
            ),
          ],
        ],
      ),
      const SizedBox(height: 16),

      CmsFormCard(
        title: 'Festival Image',
        children: [
          CmsUploadBox(
            label: 'Festival Image',
            icon: Icons.image_outlined,
            accept: 'JPG, PNG up to 5MB',
            mediaType: PickMediaType.image,
            initialUrl: _existingImageUrl,
            onPicked: (f) => setState(() => _pickedImage = f),
            onRemoved: () => setState(() {
              _pickedImage = null;
              _existingImageUrl = null;
            }),
          ),
        ],
      ),
      const SizedBox(height: 16),

      if (_isEdit) ...[
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFFE082)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFFF9A825), size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Updating will move this festival back to Pending.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF5D4037)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],

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
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(color: CmsColors.textSecond),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: CmsColors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
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
                      _isEdit ? 'Save Changes' : 'Submit for Review',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    ],
  );
}

// ── Date picker field ─────────────────────────────────────────────
class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.label,
    required this.value,
    required this.onTap,
  });
  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  String get _display {
    if (value == null) return 'Select date';
    return '${value!.day.toString().padLeft(2, '0')}-'
        '${value!.month.toString().padLeft(2, '0')}-'
        '${value!.year}';
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: CmsColors.textPrimary,
        ),
      ),
      const SizedBox(height: 6),
      GestureDetector(
        onTap: onTap,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: CmsColors.bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: value != null ? CmsColors.orange : CmsColors.border,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 15,
                color: value != null
                    ? CmsColors.orange
                    : const Color(0xFFAAAAAA),
              ),
              const SizedBox(width: 8),
              Text(
                _display,
                style: TextStyle(
                  fontSize: 13,
                  color: value != null
                      ? CmsColors.textPrimary
                      : const Color(0xFFAAAAAA),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

// ════════════════════════════════════════════════════════════════
// POOJA PICKER FIELD
// ════════════════════════════════════════════════════════════════
class _PoojaPickerField extends StatelessWidget {
  const _PoojaPickerField({
    required this.selectedIds,
    required this.selectedNames,
    required this.onChanged,
  });

  final List<String> selectedIds;
  final List<String> selectedNames;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Associated Rituals / Poojas (optional)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: CmsColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        if (selectedNames.isNotEmpty) ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: selectedNames
                .asMap()
                .entries
                .map(
                  (e) => Chip(
                    label: Text(e.value, style: const TextStyle(fontSize: 12)),
                    backgroundColor: CmsColors.orange.withOpacity(0.1),
                    side: BorderSide(color: CmsColors.orange.withOpacity(0.3)),
                    deleteIconColor: CmsColors.orange,
                    onDeleted: () {
                      selectedIds.removeAt(e.key);
                      selectedNames.removeAt(e.key);
                      onChanged();
                    },
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
        ],
        GestureDetector(
          onTap: () => _showPoojaSelector(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: CmsColors.bg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: CmsColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.add_circle_outline,
                  size: 16,
                  color: CmsColors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  selectedIds.isEmpty
                      ? 'Select poojas for this festival...'
                      : 'Add another pooja',
                  style: const TextStyle(
                    fontSize: 13,
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

  void _showPoojaSelector(BuildContext context) {
    final poojaCtrl = Get.find<PoojaController>();
    final poojas = poojaCtrl.poojas
        .where((p) => !selectedIds.contains(p.id))
        .toList();

    if (poojas.isEmpty) {
      Get.snackbar(
        'No Poojas',
        'No more poojas to add',
        snackPosition: SnackPosition.TOP,
        backgroundColor: CmsColors.orange,
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: CmsColors.border,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'Select Pooja',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: CmsColors.textPrimary,
              ),
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: poojas.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final p = poojas[i];
                return ListTile(
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: CmsColors.orange.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.self_improvement,
                      color: CmsColors.orange,
                      size: 18,
                    ),
                  ),
                  title: Text(
                    p.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    p.deity,
                    style: const TextStyle(
                      fontSize: 11,
                      color: CmsColors.textSecond,
                    ),
                  ),
                  onTap: () {
                    selectedIds.add(p.id);
                    selectedNames.add(p.title);
                    onChanged();
                    Navigator.pop(ctx);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
