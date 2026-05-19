// Placeholder content for the top-level "Manage Rituals" sidebar tab.
//
// Note: the existing "Manage Pujas" tab is rendered by `CmsRitualsContent`
// (historical naming). This new screen is reserved for a real CMS rituals
// module (e.g. independent of pujas) and is intentionally a placeholder
// until the API is wired up — mirrors the placeholder style used by the
// Pooja Kit Orders / Replace Requests tabs.
import 'package:flutter/material.dart';
// lib/features/cms/presentation/contents/cms_manage_rituals_content.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/core/services/media_upload_service.dart';
import 'package:satya_devotte_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:satya_devotte_app/features/cms/models/ritual_model.dart';
import 'package:satya_devotte_app/features/cms/presentation/controllers/ritual_controller.dart';
import 'package:satya_devotte_app/features/cms/presentation/pages/cms_shell_page.dart';
import 'package:satya_devotte_app/features/cms/presentation/widgets/cms_shared_widgets.dart';
import 'package:satya_devotte_app/features/cms/presentation/widgets/cms_upload_box.dart';

class CmsManageRitualsContent extends StatefulWidget {
  const CmsManageRitualsContent({super.key});

  @override
  State<CmsManageRitualsContent> createState() =>
      _CmsManageRitualsContentState();
}

class _CmsManageRitualsContentState extends State<CmsManageRitualsContent> {
  final RitualController _controller = Get.find<RitualController>();
  bool _showAddForm = false;
  RitualModel? _editingRitual;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.loadRituals(showErrorSnackbar: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showAddForm) {
      return Container(
        color: CmsColors.bg,
        child: _RitualForm(
          ritual: _editingRitual,
          controller: _controller,
          onCancel: () => setState(() {
            _showAddForm = false;
            _editingRitual = null;
          }),
          onSaved: () {
            _controller.loadRituals();
            setState(() {
              _showAddForm = false;
              _editingRitual = null;
            });
          },
        ),
      );
    }
    return Container(
      color: CmsColors.bg,
      child: _RitualList(
        controller: _controller,
        onAdd: () => setState(() {
          _editingRitual = null;
          _showAddForm = true;
        }),
        onEdit: (r) => setState(() {
          _editingRitual = r;
          _showAddForm = true;
        }),
      ),
    );
  }
}

class _RitualList extends StatelessWidget {
  const _RitualList({
    required this.controller,
    required this.onAdd,
    required this.onEdit,
  });
  final RitualController controller;
  final VoidCallback onAdd;
  final ValueChanged<RitualModel> onEdit;

  static const _filters = ['All', 'Approved', 'Pending', 'Draft', 'Rejected'];

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width >= 768;

    return Column(
      children: [
        _ManageRitualsHeader(
          onAdd: onAdd,
          isWeb: isWeb,
          controller: controller,
        ),
        Container(
          color: CmsColors.white,
          padding: EdgeInsets.only(left: isWeb ? 24 : 16, bottom: 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Obx(
              () => Row(
                children: _filters.map((f) {
                  final isSel = controller.filter == f;
                  return GestureDetector(
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
            if (controller.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: CmsColors.orange),
              );
            }
            final list = controller.filteredRituals;
            if (list.isEmpty) {
              return CmsEmptyState(
                icon: Icons.local_fire_department_outlined,
                title: 'No Rituals Found',
                subtitle: 'Try adjusting your filters or add a new ritual.',
                actionLabel: controller.filter == 'All' ? 'Add Ritual' : null,
                onAction: controller.filter == 'All' ? onAdd : null,
              );
            }
            return ListView.separated(
              padding: EdgeInsets.all(isWeb ? 24 : 16),
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
            );
          }),
        ),
      ],
    );
  }
}

class _ManageRitualsHeader extends StatelessWidget {
  const _ManageRitualsHeader({
    required this.onAdd,
    required this.isWeb,
    required this.controller,
  });
  final VoidCallback onAdd;
  final bool isWeb;
  final RitualController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isWeb ? 24 : 16, vertical: 14),
      color: CmsColors.white,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Manage Rituals',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: CmsColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Add and update ritual entries for devotees.',
                  style: TextStyle(fontSize: 12, color: CmsColors.textSecond),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(
              Icons.refresh,
              size: 20,
              color: CmsColors.textSecond,
            ),
            onPressed: controller.loadRituals,
          ),
          const SizedBox(width: 8),
          CmsPrimaryButton(
            label: isWeb ? 'Add Ritual' : 'Add',
            icon: Icons.add,
            onTap: onAdd,
          ),
        ],
      ),
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
  late final TextEditingController _purposeCtrl;
  late final TextEditingController _startingDayCtrl;
  late final TextEditingController _durationCtrl;
  late final TextEditingController _bestTimeCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _currencyCtrl;
  String? _selectedDeityId;
  String _difficulty = 'BEGINNER';
  String _accessType = 'FREE';
  String _status = 'DRAFT';
  bool _isFeatured = false;

  List<RitualDay> _days = [];
  List<RitualSection> _sections = [];

  PickedFile? _pickedImage;
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    final r = widget.ritual;
    _titleCtrl = TextEditingController(text: r?.title ?? '');
    _slugCtrl = TextEditingController(text: r?.slug ?? '');
    _descCtrl = TextEditingController(text: r?.description ?? '');
    _purposeCtrl = TextEditingController(text: r?.purpose ?? '');
    _startingDayCtrl = TextEditingController(text: r?.startingDay ?? '');
    _durationCtrl = TextEditingController(text: r?.recommendedDuration ?? '');
    _bestTimeCtrl = TextEditingController(text: r?.bestDayTime ?? '');
    _priceCtrl = TextEditingController(text: (r?.price ?? 0).toString());
    _currencyCtrl = TextEditingController(text: r?.currency ?? 'ZAR');
    _selectedDeityId = r?.deity;
    _difficulty = r?.difficulty ?? 'BEGINNER';
    _accessType = r?.accessType ?? 'FREE';
    _status = r?.status ?? 'DRAFT';
    _isFeatured = r?.isFeatured ?? false;
    _days = List.from(r?.days ?? []);
    _sections = List.from(r?.sections ?? []);
    _imageUrl = r?.imageUrl;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDeityId == null) {
      Get.snackbar('Error', 'Please select a deity');
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

    final cleanDays = _days.map((d) {
      return d.copyWith(
        activities: d.activities.where((a) => a.trim().isNotEmpty).toList(),
      );
    }).toList();

    final ritualData = RitualModel(
      id: widget.ritual?.id ?? '',
      title: _titleCtrl.text.trim(),
      slug: _slugCtrl.text.trim().isEmpty ? null : _slugCtrl.text.trim(),
      deity: _selectedDeityId!,
      description: _descCtrl.text.trim(),
      days: cleanDays,
      sections: _sections,
      purpose: _purposeCtrl.text.trim(),
      startingDay: _startingDayCtrl.text.trim(),
      recommendedDuration: _durationCtrl.text.trim(),
      bestDayTime: _bestTimeCtrl.text.trim(),
      accessType: _accessType,
      price: num.tryParse(_priceCtrl.text) ?? 0,
      currency: _currencyCtrl.text.trim(),
      difficulty: _difficulty,
      isFeatured: _isFeatured,
      status: _status,
      imageUrl: _pickedImage == null ? _imageUrl : null,
    );

    final success = widget.ritual == null
        ? await widget.controller.createRitual(
            title: ritualData.title,
            deity: ritualData.deity,
            description: ritualData.description ?? '',
            days: ritualData.days,
            sections: ritualData.sections,
            purpose: ritualData.purpose,
            startingDay: ritualData.startingDay,
            recommendedDuration: ritualData.recommendedDuration,
            bestDayTime: ritualData.bestDayTime,
            accessType: ritualData.accessType,
            price: ritualData.price,
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
    return Scaffold(
      backgroundColor: CmsColors.bg,
      appBar: AppBar(
        title: Text(widget.ritual == null ? 'Add Ritual' : 'Edit Ritual'),
        backgroundColor: CmsColors.white,
        foregroundColor: CmsColors.textPrimary,
        elevation: 0,
        actions: [
          Obx(
            () => widget.controller.isSubmitting
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : TextButton(
                    onPressed: _submit,
                    child: const Text(
                      'SAVE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: CmsColors.orange,
                      ),
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            CmsUploadBox(
              label: 'Ritual Image',
              icon: Icons.image_outlined,
              accept: 'JPG, PNG up to 5MB',
              mediaType: PickMediaType.image,
              initialUrl: _imageUrl,
              onPicked: (f) => setState(() => _pickedImage = f),
              onRemoved: () => setState(() {
                _pickedImage = null;
                _imageUrl = null;
              }),
            ),
            const SizedBox(height: 20),
            _buildField(
              'Ritual Title*',
              _titleCtrl,
              'e.g. 7-Day Financial Prosperity Ritual',
            ),
            const SizedBox(height: 16),
            _buildField(
              'Slug (optional)',
              _slugCtrl,
              'e.g. 7-day-prosperity-ritual',
            ),
            const SizedBox(height: 16),
            _buildDeityDropdown(),
            const SizedBox(height: 16),
            _buildField(
              'Description',
              _descCtrl,
              'General overview...',
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            _buildField(
              'Purpose',
              _purposeCtrl,
              'Why is this performed?',
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    'Starting Day',
                    _startingDayCtrl,
                    'e.g. Monday',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField('Duration', _durationCtrl, 'e.g. 7 Days'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildField('Best Day/Time', _bestTimeCtrl, 'e.g. Friday mornings'),
            const SizedBox(height: 16),
            _buildDifficultyAccessStatus(),
            if (_accessType == 'PAID') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildField('Price', _priceCtrl, '0.00')),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildField('Currency', _currencyCtrl, 'ZAR'),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            _buildFeaturedToggle(),
            const SizedBox(height: 24),
            _buildDaysSection(),
            const SizedBox(height: 24),
            _buildExtraSections(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController ctrl,
    String hint, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: CmsColors.border),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeityDropdown() {
    return Obx(() {
      final deities = widget.controller.deities;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Associated Deity*',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _selectedDeityId,
            items: deities
                .map(
                  (d) =>
                      DropdownMenuItem(value: d['id'], child: Text(d['name']!)),
                )
                .toList(),
            onChanged: (v) => setState(() => _selectedDeityId = v),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: CmsColors.border),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildDifficultyAccessStatus() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Difficulty',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  DropdownButtonFormField<String>(
                    value: _difficulty,
                    items: ['BEGINNER', 'INTERMEDIATE', 'ADVANCED']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setState(() => _difficulty = v!),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Access',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  DropdownButtonFormField<String>(
                    value: _accessType,
                    items: ['FREE', 'PAID']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setState(() => _accessType = v!),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Status',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            DropdownButtonFormField<String>(
              value: _status,
              items: [
                'DRAFT',
                'PENDING',
                'APPROVED',
                'REJECTED',
              ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => setState(() => _status = v!),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeaturedToggle() {
    return Row(
      children: [
        const Text(
          'Featured Ritual',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        Switch(
          value: _isFeatured,
          onChanged: (v) => setState(() => _isFeatured = v),
          activeColor: CmsColors.orange,
        ),
      ],
    );
  }

  Widget _buildDaysSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: CmsColors.textPrimary,
                ),
                children: [
                  TextSpan(text: 'Daily Instructions'),
                  TextSpan(
                    text: ' *',
                    style: TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: _addDay,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Day'),
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
            onRemove: () => setState(() => _days.removeAt(e.key)),
            onUpdate: (updated) => setState(() => _days[e.key] = updated),
          ),
        ),
      ],
    );
  }

  void _addDay() {
    setState(() {
      _days.add(
        RitualDay(
          dayNumber: _days.length + 1,
          title: 'Day ${_days.length + 1}',
          activities: [''],
        ),
      );
    });
  }

  Widget _buildExtraSections() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Extra Sections',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: _addSection,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Section'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._sections.asMap().entries.map(
          (e) => _SectionTile(
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
      _sections.add(const RitualSection(title: 'New Section', content: ''));
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
                  decoration: const InputDecoration(hintText: 'Day Title'),
                  onChanged: (v) => onUpdate(day.copyWith(title: v)),
                ),
              ),
              IconButton(
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
          TextFormField(
            initialValue: day.activities.join('\n'),
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Instructions (one per line)',
            ),
            onChanged: (v) => onUpdate(
              day.copyWith(
                activities: v
                    .split('\n')
                    .where((s) => s.trim().isNotEmpty)
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: day.mantra,
                  decoration: const InputDecoration(
                    hintText: 'Mantra (optional)',
                  ),
                  onChanged: (v) => onUpdate(day.copyWith(mantra: v)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  initialValue: day.affirmation,
                  decoration: const InputDecoration(
                    hintText: 'Affirmation (optional)',
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

extension on RitualDay {
  RitualDay copyWith({
    String? title,
    List<String>? activities,
    String? mantra,
    String? affirmation,
  }) {
    return RitualDay(
      dayNumber: dayNumber,
      title: title ?? this.title,
      activities: activities ?? this.activities,
      mantra: mantra ?? this.mantra,
      affirmation: affirmation ?? this.affirmation,
    );
  }
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CmsColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: section.title,
                  decoration: const InputDecoration(hintText: 'Section Title'),
                  onChanged: (v) => onUpdate(
                    RitualSection(title: v, content: section.content),
                  ),
                ),
              ),
              IconButton(
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
          TextFormField(
            initialValue: section.content,
            maxLines: 4,
            decoration: const InputDecoration(hintText: 'Section Content'),
            onChanged: (v) =>
                onUpdate(RitualSection(title: section.title, content: v)),
          ),
        ],
      ),
    );
  }
}

Widget _SmBtn(String label, Color color, VoidCallback onTap) => GestureDetector(
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
