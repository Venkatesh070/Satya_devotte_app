// lib/features/cms/presentation/contents/cms_manage_rituals_content.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/core/services/media_upload_service.dart';
import 'package:satya_devotte_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:satya_devotte_app/features/cms/models/ritual_model.dart';
import 'package:satya_devotte_app/features/cms/presentation/controllers/ritual_controller.dart';
import 'package:satya_devotte_app/core/utils/cms_search_scheduler.dart';
import 'package:satya_devotte_app/features/cms/presentation/pages/cms_shell_page.dart';
import 'package:satya_devotte_app/features/cms/presentation/widgets/cms_shared_widgets.dart';
import 'package:satya_devotte_app/features/cms/presentation/widgets/cms_upload_box.dart';

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
      onEdit: (r) => setState(() {
        _editing = r;
        _showForm = true;
      }),
    );
  }
}

class _RitualList extends StatefulWidget {
  const _RitualList({
    required this.controller,
    required this.onAdd,
    required this.onEdit,
  });
  final RitualController controller;
  final VoidCallback onAdd;
  final ValueChanged<RitualModel> onEdit;

  @override
  State<_RitualList> createState() => _RitualListState();
}

class _RitualListState extends State<_RitualList> {
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

  RitualController get controller => widget.controller;
  VoidCallback get onAdd => widget.onAdd;
  ValueChanged<RitualModel> get onEdit => widget.onEdit;

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
                      child: Text(
                        f,
                        style: TextStyle(
                          color: isSel ? Colors.white : CmsColors.textSecond,
                          fontSize: 12,
                          fontWeight: isSel
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
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
                  onEdit: () => onEdit(list[i]),
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
  });
  final RitualModel ritual;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onApprove;
  final VoidCallback onReject;

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
                    if ((ritual.ritualDays ?? ritual.days.length) > 0) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${ritual.ritualDays ?? ritual.days.length} days',
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

  List<RitualDay> _days = [];
  List<RitualSection> _sections = [];

  PickedFile? _pickedImage;
  String? _imageUrl;
  bool _imageRemoved = false;

  bool get _isEdit => widget.ritual != null;

  static List<RitualSection> _defaultSections() => [
    const RitualSection(
      key: 'overview',
      label: 'Overview',
      contents: [
        RitualSectionContent(
          title: 'What you will need',
          description: '',
          imageUrl: '',
        ),
      ],
    ),
    const RitualSection(
      key: 'preparation',
      label: 'Preparation',
      contents: [
        RitualSectionContent(
          title: 'Space setup',
          description: '',
          imageUrl: '',
        ),
      ],
    ),
  ];

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
    final dayCount = r?.ritualDays ?? r?.days.length ?? 0;
    _ritualDaysCtrl = TextEditingController(
      text: dayCount > 0 ? dayCount.toString() : '',
    );
    _bestTimeCtrl = TextEditingController(text: r?.bestDayTime ?? '');
    _selectedDeityIds = List<String>.from(r?.deities ?? const []);
    _difficulty = r?.difficulty ?? 'BEGINNER';
    _status = r?.status ?? 'PENDING';
    _isFeatured = r?.isFeatured ?? false;
    _days = List.from(r?.days ?? []);
    _sections = r != null && r.sections.isNotEmpty
        ? List.from(r.sections)
        : _defaultSections();
    _imageUrl = r?.imageUrl;
    _titleCtrl.addListener(_syncSlugFromTitle);
    Future.microtask(widget.controller.loadDeities);
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
    super.dispose();
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDeityIds.isEmpty) {
      showCmsSnackbar(
        title: 'Validation Error',
        message: 'Please select at least one deity',
        isError: true,
      );
      return;
    }
    if (_days.isEmpty) {
      showCmsSnackbar(
        title: 'Validation Error',
        message: 'Please add at least one ritual day before submitting.',
        isError: true,
      );
      return;
    }

    final ritualDays = int.tryParse(_ritualDaysCtrl.text.trim());
    final cleanDays = _days.asMap().entries.map((e) {
      final d = e.value;
      return d.copyWith(
        dayNumber: e.key + 1,
        activities: d.activities.where((a) => a.trim().isNotEmpty).toList(),
      );
    }).toList();

    final cleanSections = _sections
        .where((s) => s.label.trim().isNotEmpty)
        .map(
          (s) => s.copyWith(
            contents: s.contents
                .where(
                  (c) =>
                      c.title.trim().isNotEmpty ||
                      c.description.trim().isNotEmpty,
                )
                .toList(),
          ),
        )
        .where((s) => s.contents.isNotEmpty)
        .toList();

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
      ritualDays: ritualDays ?? cleanDays.length,
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
            ritualDays: ritualData.ritualDays,
            bestDayTime: ritualData.bestDayTime,
            accessType: ritualData.accessType,
            price: ritualData.price,
            currency: ritualData.currency,
            difficulty: ritualData.difficulty,
            isFeatured: ritualData.isFeatured,
            status: ritualData.status,
            image: _pickedImage,
          )
        : await widget.controller.updateRitual(
            widget.ritual!.id,
            ritualData,
            image: _pickedImage,
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
                    Expanded(child: _buildBasicDetailsCard()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildCoverImageCard()),
                  ],
                )
              else ...[
                _buildBasicDetailsCard(),
                const SizedBox(height: 16),
                _buildCoverImageCard(),
              ],
              const SizedBox(height: 16),
              _buildScheduleCard(),
              const SizedBox(height: 16),
              _buildAccessCard(),
              const SizedBox(height: 16),
              _buildSectionsCard(),
              const SizedBox(height: 16),
              _buildDaysSection(),
              const SizedBox(height: 24),
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
                              _isEdit ? 'Save Changes' : 'Create Ritual',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      );
    });
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

  Widget _buildAccessCard() {
    return CmsFormCard(
      title: 'Access & publishing',
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Access type',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: CmsColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    initialValue: 'Free',
                    readOnly: true,
                    enableInteractiveSelection: false,
                    style: const TextStyle(
                      fontSize: 13,
                      color: CmsColors.textSecond,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: CmsColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: CmsColors.border),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: CmsColors.border),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CmsDropdownField(
                label: 'Status',
                items: const ['DRAFT', 'PENDING', 'APPROVED', 'REJECTED'],
                initialValue: _status,
                onChanged: (v) {
                  if (v != null) setState(() => _status = v);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildFeaturedToggle(),
      ],
    );
  }

  Widget _buildDeityDropdown() {
    return Obx(() {
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
                label: d['name']?.isNotEmpty == true ? d['name']! : d['id']!,
              ),
            )
            .toList(),
        selectedValues: _selectedDeityIds,
        onChanged: (values) => setState(() => _selectedDeityIds = values),
      );
    });
  }

  Widget _buildFeaturedToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  'Featured',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: CmsColors.textPrimary,
                  ),
                ),
                Text(
                  'Highlight on home featured rituals.',
                  style: TextStyle(fontSize: 11, color: CmsColors.textSecond),
                ),
              ],
            ),
          ),
          Switch(
            value: _isFeatured,
            onChanged: (v) => setState(() => _isFeatured = v),
            activeThumbColor: CmsColors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildDaysSection() {
    return CmsFormCard(
      title: 'Daily program',
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              onPressed: _addDay,
              style: TextButton.styleFrom().copyWith(
                mouseCursor: _cmsButtonClickCursor,
              ),
              icon: const Icon(Icons.add, size: 18, color: CmsColors.orange),
              label: const Text(
                'Add day',
                style: TextStyle(
                  color: CmsColors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        if (_days.isEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
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
                    'At least one day is required to create a ritual.',
                    style: TextStyle(fontSize: 12, color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        ..._days.asMap().entries.map(
          (e) => _DayTile(
            index: e.key,
            day: e.value,
            onRemove: () => setState(() {
              _days.removeAt(e.key);
              _ritualDaysCtrl.text = _days.length.toString();
            }),
            onUpdate: (updated) => setState(() => _days[e.key] = updated),
          ),
        ),
      ],
    );
  }

  void _addDay() {
    setState(() {
      final n = _days.length + 1;
      _days.add(
        RitualDay(
          dayNumber: n,
          title: 'Day $n — ',
          activities: [''],
          mantra: '',
          affirmation: '',
        ),
      );
      _ritualDaysCtrl.text = n.toString();
    });
  }

  Widget _buildSectionsCard() {
    return CmsFormCard(
      title: 'Content sections',
      children: [
        const Text(
          'Structured blocks such as Overview and Preparation. Each section '
          'has a label and one or more content items.',
          style: TextStyle(fontSize: 12, color: CmsColors.textSecond),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              onPressed: _addSection,
              style: TextButton.styleFrom().copyWith(
                mouseCursor: _cmsButtonClickCursor,
              ),
              icon: const Icon(Icons.add, size: 18, color: CmsColors.orange),
              label: const Text(
                'Add section',
                style: TextStyle(
                  color: CmsColors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        ..._sections.asMap().entries.map(
          (e) => _SectionEditorTile(
            index: e.key,
            section: e.value,
            onRemove: () => setState(() => _sections.removeAt(e.key)),
            onUpdate: (updated) => setState(() => _sections[e.key] = updated),
          ),
        ),
      ],
    );
  }

  void _addSection() {
    setState(() {
      final n = _sections.length + 1;
      _sections.add(
        RitualSection(
          key: '',
          label: 'Section $n',
          contents: const [RitualSectionContent()],
        ),
      );
    });
  }
}

class _DayTile extends StatelessWidget {
  const _DayTile({
    required this.index,
    required this.day,
    required this.onRemove,
    required this.onUpdate,
  });
  final int index;
  final RitualDay day;
  final VoidCallback onRemove;
  final ValueChanged<RitualDay> onUpdate;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CmsColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: CmsColors.orange,
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(fontSize: 11, color: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  initialValue: day.title,
                  style: const TextStyle(fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Day 1 — Invocation',
                    filled: true,
                    fillColor: CmsColors.bg,
                  ),
                  onChanged: (v) => onUpdate(day.copyWith(title: v)),
                ),
              ),
              IconButton(
                style: IconButton.styleFrom().copyWith(
                  mouseCursor: _cmsButtonClickCursor,
                ),
                icon: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: Colors.red,
                ),
                onPressed: onRemove,
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Activities (one per line)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 4),
          TextFormField(
            initialValue: day.activities.join('\n'),
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Light the lamp\nChant opening mantra',
              filled: true,
              fillColor: CmsColors.bg,
            ),
            onChanged: (v) => onUpdate(
              day.copyWith(
                activities: v.split('\n').map((s) => s.trim()).toList(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: day.mantra,
                  style: const TextStyle(fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Mantra (optional)',
                    filled: true,
                    fillColor: CmsColors.bg,
                  ),
                  onChanged: (v) => onUpdate(day.copyWith(mantra: v)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  initialValue: day.affirmation,
                  style: const TextStyle(fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Affirmation (optional)',
                    filled: true,
                    fillColor: CmsColors.bg,
                  ),
                  onChanged: (v) => onUpdate(day.copyWith(affirmation: v)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionEditorTile extends StatelessWidget {
  const _SectionEditorTile({
    required this.index,
    required this.section,
    required this.onRemove,
    required this.onUpdate,
  });

  final int index;
  final RitualSection section;
  final VoidCallback onRemove;
  final ValueChanged<RitualSection> onUpdate;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CmsColors.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CmsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: CmsColors.orange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Section ${index + 1}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: CmsColors.orange,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                style: IconButton.styleFrom().copyWith(
                  mouseCursor: _cmsButtonClickCursor,
                ),
                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                onPressed: onRemove,
              ),
            ],
          ),
          const SizedBox(height: 8),
          _RitualLabeled(
            label: 'Section label',
            child: TextFormField(
              initialValue: section.label,
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Overview',
                filled: true,
                fillColor: CmsColors.white,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  borderSide: BorderSide(color: CmsColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  borderSide: BorderSide(color: CmsColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  borderSide: BorderSide(color: CmsColors.orange),
                ),
              ),
              onChanged: (v) => onUpdate(
                section.copyWith(label: v, key: ''),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...section.contents.asMap().entries.map((e) {
            final content = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: CmsColors.border),
                ),
                child: Column(
                  children: [
                    _RitualLabeled(
                      label: 'Content title',
                      child: TextFormField(
                        initialValue: content.title,
                        style: const TextStyle(fontSize: 13),
                        decoration: const InputDecoration(
                          hintText: 'What you will need',
                          filled: true,
                          fillColor: CmsColors.bg,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                            borderSide: BorderSide(color: CmsColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                            borderSide: BorderSide(color: CmsColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                            borderSide: BorderSide(color: CmsColors.orange),
                          ),
                        ),
                        onChanged: (v) {
                          final list = List<RitualSectionContent>.from(
                            section.contents,
                          );
                          list[e.key] = content.copyWith(title: v);
                          onUpdate(section.copyWith(contents: list));
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    _RitualLabeled(
                      label: 'Description',
                      child: TextFormField(
                        initialValue: content.description,
                        maxLines: 3,
                        style: const TextStyle(fontSize: 13),
                        decoration: const InputDecoration(
                          hintText: 'Lamp, ghee, flowers, coins, red cloth.',
                          filled: true,
                          fillColor: CmsColors.bg,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                            borderSide: BorderSide(color: CmsColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                            borderSide: BorderSide(color: CmsColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                            borderSide: BorderSide(color: CmsColors.orange),
                          ),
                        ),
                        onChanged: (v) {
                          final list = List<RitualSectionContent>.from(
                            section.contents,
                          );
                          list[e.key] = content.copyWith(description: v);
                          onUpdate(section.copyWith(contents: list));
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          TextButton.icon(
            onPressed: () {
              final list = List<RitualSectionContent>.from(section.contents)
                ..add(const RitualSectionContent());
              onUpdate(section.copyWith(contents: list));
            },
            style: TextButton.styleFrom().copyWith(
              mouseCursor: _cmsButtonClickCursor,
            ),
            icon: const Icon(Icons.add, size: 16, color: CmsColors.orange),
            label: const Text(
              'Add content item',
              style: TextStyle(color: CmsColors.orange, fontSize: 12),
            ),
          ),
        ],
      ),
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

class _RitualLabeled extends StatelessWidget {
  const _RitualLabeled({required this.label, required this.child});

  final String label;
  final Widget child;

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
          child,
        ],
      );
}
