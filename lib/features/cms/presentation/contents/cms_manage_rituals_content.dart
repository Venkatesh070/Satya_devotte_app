// lib/features/cms/presentation/contents/cms_manage_rituals_content.dart
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/core/services/media_upload_service.dart';
import 'package:satya_devotte_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:satya_devotte_app/features/cms/models/ritual_model.dart';
import 'package:satya_devotte_app/features/cms/presentation/controllers/ritual_controller.dart';
import 'package:satya_devotte_app/core/utils/cms_search_scheduler.dart';
import 'package:satya_devotte_app/features/cms/presentation/pages/cms_shell_page.dart';
import 'package:satya_devotte_app/features/cms/presentation/widgets/cms_shared_widgets.dart';
import 'package:satya_devotte_app/features/cms/presentation/widgets/cms_rich_text_field.dart';
import 'package:satya_devotte_app/features/cms/presentation/widgets/cms_upload_box.dart';
import 'package:satya_devotte_app/core/utils/rich_text_util.dart';

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

class CmsManageRitualsContent extends StatefulWidget {
  const CmsManageRitualsContent({super.key});

  @override
  State<CmsManageRitualsContent> createState() =>
      _CmsManageRitualsContentState();
}

class _CmsManageRitualsContentState extends State<CmsManageRitualsContent> {
  late final RitualController _controller;
  bool _showForm = false;
  RitualModel? _editing;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<RitualController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller.clearSearch();
      _controller.loadRituals(showErrorSnackbar: false);
    });
  }

  void _closeForm() => setState(() {
    _showForm = false;
    _editing = null;
  });

  @override
  Widget build(BuildContext context) {
    if (_showForm) {
      return _RitualForm(
        ritual: _editing,
        controller: _controller,
        onCancel: _closeForm,
        onSaved: () {
          _closeForm();
          _controller.loadRituals();
        },
      );
    }
    return _RitualList(
      controller: _controller,
      onAdd: () => setState(() {
        _editing = null;
        _showForm = true;
      }),
      onOpenForm: (ritual) => setState(() {
        _editing = ritual;
        _showForm = true;
      }),
    );
  }
}

class _RitualList extends StatefulWidget {
  const _RitualList({
    required this.controller,
    required this.onAdd,
    required this.onOpenForm,
  });
  final RitualController controller;
  final VoidCallback onAdd;
  final ValueChanged<RitualModel> onOpenForm;

  @override
  State<_RitualList> createState() => _RitualListState();
}

class _RitualListState extends State<_RitualList> {
  late final CmsSearchScheduler _searchScheduler;
  final _searchController = TextEditingController();
  String? _openingEditId;

  @override
  void initState() {
    super.initState();
    _searchScheduler = CmsSearchScheduler(
      onSearch: widget.controller.setSearch,
    );
  }

  @override
  void dispose() {
    _searchScheduler.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onFilterTap(String f) {
    _searchController.clear();
    _searchScheduler.cancelPending();
    controller.setFilter(f);
  }

  RitualController get controller => widget.controller;
  VoidCallback get onAdd => widget.onAdd;
  ValueChanged<RitualModel> get onOpenForm => widget.onOpenForm;

  Future<void> _openEdit(RitualModel summary) async {
    final id = summary.id.trim();
    if (id.isEmpty) {
      showCmsSnackbar(
        title: 'Cannot edit',
        message: 'This ritual has no id. Refresh the list and try again.',
        isError: true,
      );
      onOpenForm(summary);
      return;
    }

    setState(() => _openingEditId = id);
    try {
      final full = await controller.getRitualById(id);
      if (!mounted) return;
      onOpenForm(full);
    } catch (_) {
      if (!mounted) return;
      showCmsSnackbar(
        title: 'Load failed',
        message:
            'Could not load full ritual details. Opening summary data instead.',
        isError: true,
      );
      onOpenForm(summary);
    } finally {
      if (mounted) setState(() => _openingEditId = null);
    }
  }

  static const _filters = ['All', 'Approved', 'Pending', 'Draft', 'Rejected'];

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 768;

    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 24 : 16,
            vertical: 14,
          ),
          color: CmsColors.white,
          child: Row(
            children: [
              if (isTablet) ...[
                const Text(
                  'Rituals',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: CmsColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 20),
              ],
              Expanded(
                child: CmsSearchBar(
                  hint: 'Search rituals...',
                  controller: _searchController,
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
                        onTap: controller.loadRituals,
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
                label: isTablet ? '+ Add Ritual' : 'Add',
                onTap: onAdd,
              ),
            ],
          ),
        ),
        Container(
          color: CmsColors.white,
          padding: EdgeInsets.only(left: isTablet ? 24 : 16, bottom: 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Obx(
              () => Row(
                children: _filters.map((f) {
                  final isSel = controller.filter == f;
                  return _cmsClickable(
                    onTap: () => _onFilterTap(f),
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
                                  ? const Color(0xFFFCF7EF)
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
                                    ? Colors.white.withOpacity(0.85)
                                    : CmsColors.orange,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${controller.pendingCount}',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: isSel
                                      ? CmsColors.orange
                                      : const Color(0xFFFCF7EF),
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
        Expanded(
          child: Obx(() {
            if (controller.isLoading && controller.rituals.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: CmsColors.orange),
              );
            }
            final list = controller.filteredRituals;
            if (list.isEmpty) {
              return CmsEmptyState(
                icon: Icons.local_fire_department_outlined,
                title: (controller.filter == 'All' && controller.search.isEmpty)
                    ? 'No Rituals Yet'
                    : 'No matching rituals',
                subtitle:
                    'Rituals you create will appear here. Tap "+ Add Ritual" '
                    'to create your first ritual.',
                actionLabel:
                    (controller.filter == 'All' && controller.search.isEmpty)
                    ? 'Add Ritual'
                    : null,
                onAction:
                    (controller.filter == 'All' && controller.search.isEmpty)
                    ? onAdd
                    : null,
              );
            }
            return RefreshIndicator(
              color: CmsColors.orange,
              onRefresh: () => controller.loadRituals(),
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(isTablet ? 24 : 16),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) => _RitualCard(
                  ritual: list[i],
                  isEditLoading: _openingEditId == list[i].id,
                  onEdit: () => _openEdit(list[i]),
                  onDelete: () async {
                    final ok = await showCmsDeleteDialog(
                      ctx,
                      itemName: list[i].title,
                    );
                    if (ok == true) await controller.deleteRitual(list[i].id);
                  },
                  onApprove: () => controller.approveRitual(list[i].id),
                  onReject: () =>
                      controller.rejectRitual(list[i].id, 'Rejected by admin'),
                ),
              ),
            );
          }),
        ),
        Obx(
          () => Padding(
            padding: EdgeInsets.fromLTRB(
              isTablet ? 24 : 16,
              0,
              isTablet ? 24 : 16,
              16,
            ),
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
}

class _RitualCard extends StatelessWidget {
  const _RitualCard({
    required this.ritual,
    required this.onEdit,
    required this.onDelete,
    required this.onApprove,
    required this.onReject,
    this.isEditLoading = false,
  });
  final RitualModel ritual;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final bool isEditLoading;

  @override
  Widget build(BuildContext context) {
    final isSA = Get.find<AuthController>().isSuperAdmin;
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
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: ritual.imageUrl != null && ritual.imageUrl!.isNotEmpty
                ? Image.network(
                    ritual.imageUrl!,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _Icon(),
                  )
                : _Icon(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ritual.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: CmsColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                if (ritual.category != null && ritual.category!.isNotEmpty)
                  Text(
                    ritual.category!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: CmsColors.textSecond,
                    ),
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    CmsStatusBadge(status: ritual.status),
                    const SizedBox(width: 8),
                    Text(
                      ritual.difficulty,
                      style: const TextStyle(
                        fontSize: 11,
                        color: CmsColors.textSecond,
                      ),
                    ),
                    if ((ritual.ritualDay ?? ritual.days.length) > 0) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${ritual.ritualDay ?? ritual.days.length} days',
                        style: const TextStyle(
                          fontSize: 11,
                          color: CmsColors.textSecond,
                        ),
                      ),
                    ],
                    if (ritual.isFeatured) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.star, size: 12, color: CmsColors.orange),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  isEditLoading
                      ? const SizedBox(
                          width: 28,
                          height: 28,
                          child: Padding(
                            padding: EdgeInsets.all(6),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.blue,
                            ),
                          ),
                        )
                      : CmsActionIcon(
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
              if (isSA &&
                  (ritual.status == 'PENDING' || ritual.status == 'DRAFT')) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    _SmBtn('Reject', Colors.red, onReject),
                    const SizedBox(width: 6),
                    _SmBtn('Approve', Colors.green, onApprove),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _Icon() => Container(
    width: 52,
    height: 52,
    decoration: BoxDecoration(
      color: CmsColors.orange.withOpacity(0.1),
      borderRadius: BorderRadius.circular(10),
    ),
    child: const Icon(
      Icons.local_fire_department,
      color: CmsColors.orange,
      size: 24,
    ),
  );
}

class _RitualForm extends StatefulWidget {
  const _RitualForm({
    this.ritual,
    required this.controller,
    required this.onCancel,
    required this.onSaved,
  });
  final RitualModel? ritual;
  final RitualController controller;
  final VoidCallback onCancel;
  final VoidCallback onSaved;

  @override
  State<_RitualForm> createState() => _RitualFormState();
}

class _RitualFormState extends State<_RitualForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _slugCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _purposeCtrl;
  late final TextEditingController _startingDayCtrl;
  late final TextEditingController _ritualDaysCtrl;
  late final TextEditingController _bestTimeCtrl;
  List<String> _selectedDeityIds = [];
  String _difficulty = 'BEGINNER';
  static const String _accessType = 'FREE';
  String _status = 'PENDING';
  bool _isFeatured = false;

  late List<_DayDraft> _dayEntries;
  final _dayTitleCtrl = TextEditingController();
  String? _dayDescRich;
  int _dayEditorEpoch = 0;
  final _dayTitleFocus = FocusNode();
  final List<String> _dayImageUrls = [];
  final List<PickedFile> _dayPickedImages = [];
  bool _showDayEditor = false;
  int? _editingDayIndex;

  late List<_SectionDraft> _sectionEntries;
  bool _showSectionEditor = false;
  int? _editingSectionIndex;
  final _sectionLabelCtrl = TextEditingController();
  final _sectionLabelFocus = FocusNode();
  String? _sectionDescRich;
  int _sectionEditorEpoch = 0;

  PickedFile? _pickedImage;
  String? _imageUrl;
  bool _imageRemoved = false;

  bool get _isEdit => widget.ritual != null;

  static List<_SectionDraft> _defaultSectionEntries() => [
    const _SectionDraft(label: 'Overview'),
    const _SectionDraft(label: 'Preparation'),
  ];

  static List<_SectionDraft> _sectionEntriesFromModel(
    List<RitualSection> sections,
  ) => sections
      .map((s) => _SectionDraft(label: s.label, description: s.description))
      .toList();

  static List<RitualSection> _sectionsToModel(List<_SectionDraft> entries) =>
      entries
          .where(
            (s) => s.label.trim().isNotEmpty || s.description.trim().isNotEmpty,
          )
          .map(
            (s) => RitualSection(
              key: '',
              label: s.label.trim().isEmpty
                  ? 'Untitled section'
                  : s.label.trim(),
              description: s.description,
            ),
          )
          .toList();

  @override
  void initState() {
    super.initState();
    final r = widget.ritual;
    _titleCtrl = TextEditingController(text: r?.title ?? '');
    _slugCtrl = TextEditingController(text: r?.slug ?? '');
    _descCtrl = TextEditingController(text: r?.description ?? '');
    _categoryCtrl = TextEditingController(text: r?.category ?? '');
    _purposeCtrl = TextEditingController(text: r?.purpose ?? '');
    _startingDayCtrl = TextEditingController(text: r?.startingDay ?? '');
    final dayCount = r?.ritualDay ?? r?.days.length ?? 0;
    _ritualDaysCtrl = TextEditingController(
      text: dayCount > 0 ? dayCount.toString() : '',
    );
    _bestTimeCtrl = TextEditingController(text: r?.bestDayTime ?? '');
    _selectedDeityIds = List<String>.from(r?.deities ?? const []);
    _difficulty = r?.difficulty ?? 'BEGINNER';
    _status = r?.status ?? 'PENDING';
    _isFeatured = r?.isFeatured ?? false;
    _dayEntries = (r?.days ?? [])
        .map(
          (d) => _DayDraft(
            title: d.title,
            description: d.description,
            imageUrls: List<String>.from(d.images),
          ),
        )
        .toList();
    _sectionEntries = r != null && r.sections.isNotEmpty
        ? _sectionEntriesFromModel(r.sections)
        : _defaultSectionEntries();
    _imageUrl = r?.imageUrl;
    _titleCtrl.addListener(_syncSlugFromTitle);
    Future.microtask(widget.controller.loadDeities);
    if (_dayEntries.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openNewDayEditor();
      });
    }
  }

  @override
  void dispose() {
    _titleCtrl.removeListener(_syncSlugFromTitle);
    _titleCtrl.dispose();
    _slugCtrl.dispose();
    _categoryCtrl.dispose();
    _descCtrl.dispose();
    _purposeCtrl.dispose();
    _startingDayCtrl.dispose();
    _ritualDaysCtrl.dispose();
    _bestTimeCtrl.dispose();
    _dayTitleCtrl.dispose();
    _dayTitleFocus.dispose();
    _sectionLabelCtrl.dispose();
    _sectionLabelFocus.dispose();
    super.dispose();
  }

  List<List<PickedFile>> _dayPickedImagesByDay() => _dayEntries
      .map((day) => List<PickedFile>.from(day.pickedImages))
      .toList();

  Future<void> _pickDayImages() async {
    final files = await Get.find<MediaUploadService>().pickImages();
    if (files.isEmpty) return;
    setState(() => _dayPickedImages.addAll(files));
  }

  void _removeDayPickedImage(int index) {
    setState(() => _dayPickedImages.removeAt(index));
  }

  void _removeDayImageUrl(int index) {
    setState(() => _dayImageUrls.removeAt(index));
  }

  void _clearDayEditorFields() {
    _dayTitleCtrl.clear();
    _dayDescRich = null;
    _dayImageUrls.clear();
    _dayPickedImages.clear();
    _editingDayIndex = null;
    _dayEditorEpoch++;
  }

  void _focusDayTitleField() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _dayTitleFocus.requestFocus();
        final text = _dayTitleCtrl.text;
        _dayTitleCtrl.selection = TextSelection.collapsed(offset: text.length);
      });
    });
  }

  void _openNewDayEditor() {
    setState(() {
      _clearDayEditorFields();
      _showDayEditor = true;
    });
    _focusDayTitleField();
  }

  void _closeDayEditor() {
    setState(() {
      _clearDayEditorFields();
      _showDayEditor = false;
    });
  }

  void _startEditDay(int index) {
    final day = _dayEntries[index];
    setState(() {
      _editingDayIndex = index;
      _showDayEditor = true;
      _dayTitleCtrl.text = day.title;
      _dayDescRich = day.description.trim().isEmpty ? null : day.description;
      _dayEditorEpoch++;
      _dayImageUrls
        ..clear()
        ..addAll(day.imageUrls);
      _dayPickedImages
        ..clear()
        ..addAll(day.pickedImages);
    });
    _focusDayTitleField();
  }

  void _cancelDayEdit() => _closeDayEditor();

  void _removeDay(int index) {
    setState(() {
      if (_editingDayIndex == index) {
        _clearDayEditorFields();
        _showDayEditor = false;
      } else if (_editingDayIndex != null && index < _editingDayIndex!) {
        _editingDayIndex = _editingDayIndex! - 1;
      }
      final next = List<_DayDraft>.from(_dayEntries);
      next.removeAt(index);
      _dayEntries = next;
      _ritualDaysCtrl.text = _dayEntries.length.toString();
    });
  }

  void _saveDayEntry() {
    final title = _dayTitleCtrl.text.trim();
    final description = (_dayDescRich ?? '').trim();
    if (title.isEmpty &&
        description.isEmpty &&
        _dayImageUrls.isEmpty &&
        _dayPickedImages.isEmpty) {
      return;
    }
    final editingIndex = _editingDayIndex;
    final draft = _DayDraft(
      title: title.isEmpty ? 'Untitled Day' : title,
      description: description,
      imageUrls: List<String>.from(_dayImageUrls),
      pickedImages: List<PickedFile>.from(_dayPickedImages),
    );
    setState(() {
      if (editingIndex != null) {
        final next = List<_DayDraft>.from(_dayEntries);
        next[editingIndex] = draft;
        _dayEntries = next;
      } else {
        _dayEntries = [..._dayEntries, draft];
      }
      _ritualDaysCtrl.text = _dayEntries.length.toString();
      _clearDayEditorFields();
      _showDayEditor = false;
    });
  }

  void _openNewSectionEditor() {
    setState(() {
      _clearSectionEditorFields();
      _showSectionEditor = true;
    });
    _focusSectionLabelField();
  }

  void _closeSectionEditor() {
    setState(() {
      _clearSectionEditorFields();
      _showSectionEditor = false;
    });
  }

  void _clearSectionEditorFields() {
    _sectionLabelCtrl.clear();
    _sectionDescRich = null;
    _editingSectionIndex = null;
    _sectionEditorEpoch++;
  }

  void _focusSectionLabelField() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _sectionLabelFocus.requestFocus();
        final text = _sectionLabelCtrl.text;
        _sectionLabelCtrl.selection = TextSelection.collapsed(
          offset: text.length,
        );
      });
    });
  }

  void _startEditSection(int index) {
    final section = _sectionEntries[index];
    setState(() {
      _editingSectionIndex = index;
      _showSectionEditor = true;
      _sectionLabelCtrl.text = section.label;
      _sectionDescRich = section.description.trim().isEmpty
          ? null
          : section.description;
      _sectionEditorEpoch++;
    });
    _focusSectionLabelField();
  }

  void _cancelSectionEdit() => _closeSectionEditor();

  void _removeSection(int index) {
    setState(() {
      if (_editingSectionIndex == index) {
        _clearSectionEditorFields();
        _showSectionEditor = false;
      } else if (_editingSectionIndex != null &&
          index < _editingSectionIndex!) {
        _editingSectionIndex = _editingSectionIndex! - 1;
      }
      final next = List<_SectionDraft>.from(_sectionEntries);
      next.removeAt(index);
      _sectionEntries = next;
    });
  }

  void _saveSectionEntry() {
    final label = _sectionLabelCtrl.text.trim();
    final description = (_sectionDescRich ?? '').trim();
    if (label.isEmpty && description.isEmpty) return;
    final editingIndex = _editingSectionIndex;
    final draft = _SectionDraft(
      label: label.isEmpty ? 'Untitled section' : label,
      description: description,
    );
    setState(() {
      if (editingIndex != null) {
        final next = List<_SectionDraft>.from(_sectionEntries);
        next[editingIndex] = draft;
        _sectionEntries = next;
      } else {
        _sectionEntries = [..._sectionEntries, draft];
      }
      _clearSectionEditorFields();
      _showSectionEditor = false;
    });
  }

  void _flushPendingSectionEntry() {
    if (!_showSectionEditor) return;
    final label = _sectionLabelCtrl.text.trim();
    final description = (_sectionDescRich ?? '').trim();
    if (label.isEmpty && description.isEmpty) return;
    _saveSectionEntry();
  }

  void _syncSlugFromTitle() {
    if (_slugCtrl.text.trim().isNotEmpty && widget.ritual != null) return;
    final slug = _titleCtrl.text
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    if (_slugCtrl.text != slug) {
      _slugCtrl.text = slug;
    }
  }

  void _flushPendingDayEntry() {
    if (!_showDayEditor) return;
    final title = _dayTitleCtrl.text.trim();
    final description = (_dayDescRich ?? '').trim();
    if (title.isEmpty &&
        description.isEmpty &&
        _dayImageUrls.isEmpty &&
        _dayPickedImages.isEmpty) {
      return;
    }
    _saveDayEntry();
  }

  Future<void> _submit() async {
    _flushPendingDayEntry();
    _flushPendingSectionEntry();
    if (!_formKey.currentState!.validate()) return;
    if (_dayEntries.isEmpty) {
      showCmsSnackbar(
        title: 'Validation Error',
        message: 'Please add at least one ritual day before submitting.',
        isError: true,
      );
      return;
    }

    final ritualDays = int.tryParse(_ritualDaysCtrl.text.trim());
    final cleanDays = _dayEntries.asMap().entries.map((e) {
      final d = e.value;
      return RitualDay(
        stepNumber: e.key + 1,
        title: d.title,
        description: d.description,
        images: d.imageUrls,
      );
    }).toList();
    final stepImagesByDay = _dayPickedImagesByDay();

    final cleanSections = _sectionsToModel(_sectionEntries);

    final ritualData = RitualModel(
      id: widget.ritual?.id ?? '',
      title: _titleCtrl.text.trim(),
      slug: _slugCtrl.text.trim().isEmpty ? null : _slugCtrl.text.trim(),
      deities: _selectedDeityIds,
      description: _descCtrl.text.trim(),
      category: _categoryCtrl.text.trim(),
      days: cleanDays,
      sections: cleanSections,
      purpose: _purposeCtrl.text.trim(),
      startingDay: _startingDayCtrl.text.trim(),
      ritualDay: ritualDays ?? cleanDays.length,
      bestDayTime: _bestTimeCtrl.text.trim(),
      accessType: _accessType,
      price: 0,
      currency: 'ZAR',
      difficulty: _difficulty,
      isFeatured: _isFeatured,
      status: _status,
      imageUrl: _pickedImage != null
          ? null
          : (_imageRemoved ? null : _imageUrl),
    );

    final success = widget.ritual == null
        ? await widget.controller.createRitual(
            title: ritualData.title,
            slug: ritualData.slug,
            deities: ritualData.deities,
            description: ritualData.description ?? '',
            days: ritualData.days,
            sections: ritualData.sections,
            category: ritualData.category,
            purpose: ritualData.purpose,
            startingDay: ritualData.startingDay,
            ritualDays: ritualData.ritualDay,
            bestDayTime: ritualData.bestDayTime,
            accessType: ritualData.accessType,
            price: ritualData.price,
            currency: ritualData.currency,
            difficulty: ritualData.difficulty,
            isFeatured: ritualData.isFeatured,
            status: ritualData.status,
            image: _pickedImage,
            stepImagesByDay: stepImagesByDay,
          )
        : await widget.controller.updateRitual(
            widget.ritual!.id,
            ritualData,
            image: _pickedImage,
            stepImagesByDay: stepImagesByDay,
          );

    if (success) widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width >= 768;
    return Obx(() {
      final loading = widget.controller.isSubmitting;
      return Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isWeb ? 24 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _formHeader(),
              const SizedBox(height: 20),
              if (isWeb)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildLeftColumn()),
                    const SizedBox(width: 20),
                    Expanded(child: _buildRightColumn()),
                  ],
                )
              else ...[
                _buildLeftColumn(),
                const SizedBox(height: 16),
                _buildRightColumn(),
              ],
              const SizedBox(height: 20),
              _buildDaysSection(),
              const SizedBox(height: 16),
              _buildSectionsCard(),
              const SizedBox(height: 24),
              _buildFormActions(loading),
              const SizedBox(height: 24),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildLeftColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [_buildBasicDetailsCard()],
    );
  }

  Widget _buildRightColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCoverImageCard(),
        const SizedBox(height: 16),
        _buildScheduleCard(),
      ],
    );
  }

  Widget _buildFormActions(bool loading) {
    return Row(
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
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: loading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: CmsColors.orange,
              foregroundColor: const Color(0xFFFCF7EF),
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
                      color: Color(0xFFFCF7EF),
                    ),
                  )
                : Text(
                    _isEdit ? 'Save Changes' : 'Create Ritual',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _formHeader() => Row(
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
        _isEdit ? 'Edit Ritual' : 'Add Ritual',
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: CmsColors.textPrimary,
        ),
      ),
    ],
  );

  Widget _buildBasicDetailsCard() {
    return CmsFormCard(
      title: 'Basic details',
      children: [
        const Text(
          'How this ritual appears in the app listing.',
          style: TextStyle(fontSize: 11, color: CmsColors.textSecond),
        ),
        const SizedBox(height: 12),
        CmsFormField(
          label: 'Title *',
          hint: 'e.g. 7-Day Lakshmi Abundance Ritual',
          controller: _titleCtrl,
        ),
        const SizedBox(height: 12),
        // CmsFormField(
        //   label: 'Slug *',
        //   hint: 'e.g. 7-day-lakshmi-abundance-ritual',
        //   controller: _slugCtrl,
        // ),
        const SizedBox(height: 12),
        CmsFormField(
          label: 'Description',
          hint: 'Enter description...',
          controller: _descCtrl,
          maxLines: 4,
        ),
        const SizedBox(height: 12),
        _buildDeityDropdown(),
        const SizedBox(height: 12),
        CmsFormField(
          label: 'Category',
          hint: 'e.g. Wealth & Prosperity',
          controller: _categoryCtrl,
        ),
        const SizedBox(height: 12),
        CmsFormField(
          label: 'Purpose',
          hint: 'Enter purpose...',
          controller: _purposeCtrl,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildCoverImageCard() {
    return CmsFormCard(
      title: 'Cover image',
      children: [
        const Text(
          'Shown on the ritual card in the app. Use a wide landscape photo.',
          style: TextStyle(fontSize: 11, color: CmsColors.textSecond),
        ),
        const SizedBox(height: 12),
        CmsUploadBox(
          label: _isEdit ? 'Ritual image' : 'Ritual image *',
          icon: Icons.image_outlined,
          accept: '1920 × 1080 px, JPG, PNG up to 5MB',
          mediaType: PickMediaType.image,
          initialUrl: _imageUrl,
          onPicked: (f) => setState(() {
            _pickedImage = f;
            _imageRemoved = false;
          }),
          onRemoved: () => setState(() {
            _pickedImage = null;
            _imageUrl = null;
            _imageRemoved = true;
          }),
        ),
      ],
    );
  }

  Widget _buildScheduleCard() {
    return CmsFormCard(
      title: 'Schedule & difficulty',
      children: [
        const Text(
          'How long the ritual runs and when devotees should perform it.',
          style: TextStyle(fontSize: 11, color: CmsColors.textSecond),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CmsFormField(
                label: 'Ritual days',
                hint: '7',
                controller: _ritualDaysCtrl,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CmsFormField(
                label: 'Starting day',
                hint: 'Friday',
                controller: _startingDayCtrl,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        CmsFormField(
          label: 'Best day / time',
          hint: 'Friday morning after sunrise',
          controller: _bestTimeCtrl,
        ),
        const SizedBox(height: 12),
        CmsDropdownField(
          label: 'Difficulty',
          items: const ['BEGINNER', 'INTERMEDIATE', 'ADVANCED'],
          initialValue: _difficulty,
          onChanged: (v) {
            if (v != null) setState(() => _difficulty = v);
          },
        ),
      ],
    );
  }

  Widget _buildDeityDropdown() {
    return Obx(() {
      final deities = widget.controller.deities;
      final isLoading = widget.controller.isLoadingDeities;
      final loaded = widget.controller.deitiesLoaded;

      return CmsMultiSelectField(
        label: 'Deity (optional)',
        hintText: 'Select deities',
        isLoading: isLoading && !loaded,
        loadingText: 'Loading deities...',
        emptyText: 'No deities found',
        options: deities
            .map(
              (d) => CmsSelectOption(
                value: d['id']!,
                label: d['name']?.isNotEmpty == true ? d['name']! : d['id']!,
              ),
            )
            .toList(),
        selectedValues: _selectedDeityIds,
        onChanged: (values) => setState(() => _selectedDeityIds = values),
      );
    });
  }

  Widget _buildDayEditorFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CmsFormField(
          label: 'Title for this day',
          hint: 'e.g. Day 1 — Light the lamp',
          controller: _dayTitleCtrl,
          focusNode: _dayTitleFocus,
          onFieldSubmitted: (_) => _saveDayEntry(),
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: 10),
        CmsRichTextField(
          key: ValueKey(
            'day-desc-${_editingDayIndex ?? 'new'}-$_dayEditorEpoch',
          ),
          label: 'What to do on this day',
          initialValue: _dayDescRich,
          onChanged: (v) => _dayDescRich = v,
        ),
        const SizedBox(height: 10),
        _DayMultiImagePicker(
          imageUrls: _dayImageUrls,
          pickedImages: _dayPickedImages,
          onPick: _pickDayImages,
          onRemoveUrl: _removeDayImageUrl,
          onRemovePicked: _removeDayPickedImage,
        ),
      ],
    );
  }

  static String _truncateDayPreview(String text) {
    final plain = documentFromValue(
      text,
    ).toPlainText().replaceAll(RegExp(r'\s+'), ' ').trim();
    if (plain.isEmpty) return '';
    if (plain.length <= 48) return plain;
    return '${plain.substring(0, 48)}…';
  }

  Widget _buildDaysSection() {
    return CmsFormCard(
      title: 'Daily program',
      children: [
        const _RitualHelpBanner(
          icon: Icons.event_note_outlined,
          title: 'What is this?',
          body:
              'List each day of the ritual in order. Devotees follow these steps '
              'one day at a time — for example “Day 1: Invocation”, '
              '“Day 2: Offerings”.',
        ),
        const SizedBox(height: 14),
        if (_dayEntries.isNotEmpty) ...[
          _RitualCountChip(
            count: _dayEntries.length,
            label: _dayEntries.length == 1 ? 'day added' : 'days added',
          ),
          const SizedBox(height: 12),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            final stackVertically = constraints.maxWidth < 560;
            final leftRail = _buildDaysRail();
            final workspace = _buildDayWorkspace();

            if (stackVertically) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  leftRail,
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: CmsColors.border),
                  const SizedBox(height: 14),
                  workspace,
                ],
              );
            }

            return _RitualSplitLayout(
              leftWidth: 220,
              left: leftRail,
              right: workspace,
            );
          },
        ),
        if (_dayEntries.isEmpty && !_showDayEditor)
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.red),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'At least one day is required before you can save the ritual.',
                    style: TextStyle(fontSize: 12, color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDaysRail() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _RitualRailHeading(
          title: 'Days',
          hint: 'Select a day to edit, or add a new one',
        ),
        if (_dayEntries.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: _RitualEmptyHint(text: 'No days yet'),
          )
        else
          ..._dayEntries.asMap().entries.map((e) {
            final hasImages =
                e.value.imageUrls.isNotEmpty || e.value.pickedImages.isNotEmpty;
            final descPreview = e.value.description.trim().isEmpty
                ? ''
                : _truncateDayPreview(e.value.description);
            return _RitualRailTile(
              key: ValueKey(
                'day-rail-${e.key}-${e.value.title}-${e.value.description}',
              ),
              index: e.key + 1,
              title: e.value.title.isEmpty ? 'Untitled Day' : e.value.title,
              subtitle: descPreview.isNotEmpty
                  ? descPreview
                  : (hasImages ? 'Has images' : 'No description'),
              isSelected: _showDayEditor && _editingDayIndex == e.key,
              onTap: () => _startEditDay(e.key),
              onRemove: () => _removeDay(e.key),
            );
          }),
        const SizedBox(height: 8),
        _RitualPrimaryAddButton(
          label: _dayEntries.isEmpty ? 'Add first day' : 'Add day',
          onPressed: _openNewDayEditor,
          compact: true,
        ),
      ],
    );
  }

  Widget _buildDayWorkspace() {
    final editingDayNumber = _editingDayIndex != null
        ? _editingDayIndex! + 1
        : _dayEntries.length + 1;

    if (!_showDayEditor) {
      return _RitualWorkspaceHint(
        icon: Icons.event_note_outlined,
        text: _dayEntries.isEmpty
            ? 'Click “Add first day” on the left to start the daily program.'
            : 'Select a day on the left to edit, or add a new one.',
      );
    }

    return _RitualEditorPanel(
      title: _editingDayIndex != null
          ? 'Edit day $editingDayNumber'
          : 'Add day $editingDayNumber',
      subtitle: 'Enter the title, instructions, and optional images.',
      onCancel: _cancelDayEdit,
      onSave: _saveDayEntry,
      saveLabel: _editingDayIndex != null ? 'Save day' : 'Add this day',
      child: _buildDayEditorFields(),
    );
  }

  Widget _buildSectionsCard() {
    return CmsFormCard(
      title: 'Content sections (optional)',
      children: [
        const _RitualHelpBanner(
          icon: Icons.view_agenda_outlined,
          title: 'What is this?',
          body:
              'Extra information under headings — e.g. “Overview” or '
              '“Preparation”. Each section has a heading and description.',
        ),
        const SizedBox(height: 14),
        if (_sectionEntries.isNotEmpty) ...[
          _RitualCountChip(
            count: _sectionEntries.length,
            label: _sectionEntries.length == 1 ? 'section' : 'sections',
          ),
          const SizedBox(height: 12),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            final stackVertically = constraints.maxWidth < 560;
            final leftRail = _buildSectionsRail();
            final workspace = _buildSectionWorkspace();

            if (stackVertically) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  leftRail,
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: CmsColors.border),
                  const SizedBox(height: 14),
                  workspace,
                ],
              );
            }

            return _RitualSplitLayout(
              leftWidth: 220,
              left: leftRail,
              right: workspace,
            );
          },
        ),
      ],
    );
  }

  Widget _buildSectionsRail() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _RitualRailHeading(
          title: 'Sections',
          hint: 'Select a section to edit, or add a new one',
        ),
        if (_sectionEntries.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: _RitualEmptyHint(text: 'No sections yet'),
          )
        else
          ..._sectionEntries.asMap().entries.map((e) {
            final descPreview = e.value.description.trim().isEmpty
                ? ''
                : _truncateDayPreview(e.value.description);
            return _RitualRailTile(
              key: ValueKey('section-rail-${e.key}-${e.value.label}'),
              index: e.key + 1,
              title: e.value.label.isEmpty ? 'Untitled section' : e.value.label,
              subtitle: descPreview.isNotEmpty ? descPreview : 'No description',
              isSelected: _showSectionEditor && _editingSectionIndex == e.key,
              onTap: () => _startEditSection(e.key),
              onRemove: () => _removeSection(e.key),
            );
          }),
        const SizedBox(height: 8),
        _RitualPrimaryAddButton(
          label: _sectionEntries.isEmpty ? 'Add first section' : 'Add section',
          onPressed: _openNewSectionEditor,
          compact: true,
        ),
      ],
    );
  }

  Widget _buildSectionEditorFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CmsFormField(
          label: 'Section heading',
          hint: 'e.g. Overview, Preparation, After the ritual',
          controller: _sectionLabelCtrl,
          focusNode: _sectionLabelFocus,
          onFieldSubmitted: (_) => _saveSectionEntry(),
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: 10),
        CmsRichTextField(
          key: ValueKey(
            'section-desc-${_editingSectionIndex ?? 'new'}-$_sectionEditorEpoch',
          ),
          label: 'Section description',
          initialValue: _sectionDescRich,
          onChanged: (v) => _sectionDescRich = v,
        ),
      ],
    );
  }

  Widget _buildSectionWorkspace() {
    final editingNumber = _editingSectionIndex != null
        ? _editingSectionIndex! + 1
        : _sectionEntries.length + 1;

    if (!_showSectionEditor) {
      return _RitualWorkspaceHint(
        icon: Icons.view_agenda_outlined,
        text: _sectionEntries.isEmpty
            ? 'Click “Add first section” on the left to add optional content.'
            : 'Select a section on the left to edit, or add a new one.',
      );
    }

    return _RitualEditorPanel(
      title: _editingSectionIndex != null
          ? 'Edit section $editingNumber'
          : 'Add section $editingNumber',
      subtitle: 'Enter a heading and description for this section.',
      onCancel: _cancelSectionEdit,
      onSave: _saveSectionEntry,
      saveLabel: _editingSectionIndex != null ? 'Save section' : 'Add section',
      child: _buildSectionEditorFields(),
    );
  }
}

class _SectionDraft {
  const _SectionDraft({required this.label, this.description = ''});

  final String label;
  final String description;

  _SectionDraft copyWith({String? label, String? description}) {
    return _SectionDraft(
      label: label ?? this.label,
      description: description ?? this.description,
    );
  }
}

class _RitualSplitLayout extends StatelessWidget {
  const _RitualSplitLayout({
    required this.leftWidth,
    required this.left,
    required this.right,
  });

  final double leftWidth;
  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: leftWidth, child: left),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: VerticalDivider(
            width: 1,
            thickness: 1,
            color: CmsColors.border,
          ),
        ),
        Expanded(child: right),
      ],
    );
  }
}

class _RitualRailHeading extends StatelessWidget {
  const _RitualRailHeading({required this.title, required this.hint});

  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: CmsColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            hint,
            style: const TextStyle(fontSize: 11, color: CmsColors.textSecond),
          ),
        ],
      ),
    );
  }
}

class _RitualRailTile extends StatelessWidget {
  const _RitualRailTile({
    super.key,
    required this.index,
    required this.title,
    this.subtitle,
    required this.isSelected,
    required this.onTap,
    this.onRename,
    this.onRemove,
  });

  final int index;
  final String title;
  final String? subtitle;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onRename;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? CmsColors.orange.withValues(alpha: 0.1)
                  : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? CmsColors.orange.withValues(alpha: 0.45)
                    : CmsColors.border,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.only(top: 1),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? CmsColors.orange
                        : CmsColors.orange.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$index',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? const Color(0xFFFCF7EF)
                          : CmsColors.orange,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: CmsColors.textPrimary,
                        ),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            color: CmsColors.textSecond,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (onRename != null)
                  IconButton(
                    onPressed: onRename,
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    color: CmsColors.textSecond,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                    tooltip: 'Rename',
                    style: IconButton.styleFrom().copyWith(
                      mouseCursor: _cmsButtonClickCursor,
                    ),
                  ),
                if (onRemove != null)
                  IconButton(
                    onPressed: onRemove,
                    icon: const Icon(Icons.delete_outline, size: 16),
                    color: Colors.red.shade400,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                    tooltip: 'Remove',
                    style: IconButton.styleFrom().copyWith(
                      mouseCursor: _cmsButtonClickCursor,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RitualWorkspaceHint extends StatelessWidget {
  const _RitualWorkspaceHint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: CmsColors.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CmsColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28, color: CmsColors.textSecond),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              height: 1.45,
              color: CmsColors.textSecond,
            ),
          ),
        ],
      ),
    );
  }
}

class _RitualHelpBanner extends StatelessWidget {
  const _RitualHelpBanner({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CmsColors.orange.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CmsColors.orange.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: CmsColors.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: CmsColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.45,
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
}

class _RitualCountChip extends StatelessWidget {
  const _RitualCountChip({required this.count, required this.label});

  final int count;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: CmsColors.bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CmsColors.border),
      ),
      child: Text(
        '$count $label',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: CmsColors.textSecond,
        ),
      ),
    );
  }
}

class _RitualEmptyHint extends StatelessWidget {
  const _RitualEmptyHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, color: CmsColors.textSecond),
      ),
    );
  }
}

class _RitualEditorPanel extends StatelessWidget {
  const _RitualEditorPanel({
    required this.title,
    required this.subtitle,
    required this.onCancel,
    required this.onSave,
    required this.saveLabel,
    required this.child,
  });

  final String title;
  final String subtitle;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final String saveLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CmsColors.orange.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: CmsColors.orange,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: CmsColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: CmsColors.textSecond,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
          const SizedBox(height: 14),
          Row(
            children: [
              TextButton(
                onPressed: onCancel,
                style: TextButton.styleFrom().copyWith(
                  mouseCursor: _cmsButtonClickCursor,
                ),
                child: const Text('Cancel'),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: onSave,
                icon: const Icon(Icons.check, size: 16),
                label: Text(saveLabel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CmsColors.orange,
                  foregroundColor: const Color(0xFFFCF7EF),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ).copyWith(mouseCursor: _cmsButtonClickCursor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RitualPrimaryAddButton extends StatelessWidget {
  const _RitualPrimaryAddButton({
    required this.label,
    required this.onPressed,
    this.compact = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.add, size: 18, color: CmsColors.orange),
        label: Text(
          label,
          style: const TextStyle(
            color: CmsColors.orange,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(
            vertical: compact ? 10 : 14,
            horizontal: 16,
          ),
          side: BorderSide(color: CmsColors.orange.withValues(alpha: 0.45)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ).copyWith(mouseCursor: _cmsButtonClickCursor),
      ),
    );
  }
}

class _DayDraft {
  const _DayDraft({
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

class _DayMultiImagePicker extends StatelessWidget {
  const _DayMultiImagePicker({
    this.imagesLabel = 'Day Images',
    required this.imageUrls,
    required this.pickedImages,
    required this.onPick,
    required this.onRemoveUrl,
    required this.onRemovePicked,
  });

  final String imagesLabel;
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
        Text(
          imagesLabel,
          style: const TextStyle(
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
                _DayImageThumb(
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
                _DayImageThumb(
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

class _DayImageThumb extends StatelessWidget {
  const _DayImageThumb({required this.child, required this.onRemove});

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
              child: const Icon(
                Icons.close,
                size: 12,
                color: Color(0xFFFCF7EF),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

Widget _SmBtn(String label, Color color, VoidCallback onTap) => _cmsClickable(
  onTap: onTap,
  child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
    ),
  ),
);
