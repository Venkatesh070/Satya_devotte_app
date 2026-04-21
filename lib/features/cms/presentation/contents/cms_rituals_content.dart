import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/features/cms/models/pooja_model.dart';
import 'package:satya_devotte_app/features/cms/presentation/controllers/pooja_controller.dart';
import 'package:satya_devotte_app/features/cms/presentation/pages/cms_shell_page.dart';
import 'package:satya_devotte_app/features/cms/presentation/widgets/cms_shared_widgets.dart';

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
  bool _showAddForm = false;
  PoojaModel? _editingPooja;

  @override
  void initState() {
    super.initState();
    // Always reload with correct filter when entering Manage Poojas.
    // This clears any stale data left by loadAllPoojas() from the Approvals tab.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.resetAndLoad();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showAddForm) {
      return _PoojaForm(
        pooja: _editingPooja,
        controller: _controller,
        onCancel: () => setState(() {
          _showAddForm = false;
          _editingPooja = null;
        }),
        onSaved: () {
          _controller.setFilter('All');
          _controller.loadPoojas();
          setState(() {
            _showAddForm = false;
            _editingPooja = null;
          });
        },
      );
    }
    return _PoojaList(
      controller: _controller,
      onAdd: () => setState(() {
        _editingPooja = null;
        _showAddForm = true;
      }),
      onEdit: (p) => setState(() {
        _editingPooja = p;
        _showAddForm = true;
      }),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// POOJA LIST
// ════════════════════════════════════════════════════════════════
class _PoojaList extends StatelessWidget {
  const _PoojaList({
    required this.controller,
    required this.onAdd,
    required this.onEdit,
  });
  final PoojaController controller;
  final VoidCallback onAdd;
  final ValueChanged<PoojaModel> onEdit;

  static const _filters = ['All', 'Published', 'Pending', 'Draft'];

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width >= 768;

    return Column(
      children: [
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
                  hint: 'Search poojas...',
                  onChanged: (_) {},
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
                    : GestureDetector(
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
                label: isWeb ? 'Add New Pooja' : 'Add',
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
            if (controller.isLoading) {
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
              return CmsEmptyState(
                icon: Icons.self_improvement,
                title: controller.filter == 'All'
                    ? 'No Poojas Yet'
                    : 'No ${controller.filter} Poojas',
                subtitle: controller.filter == 'All'
                    ? 'Add your first pooja to get started'
                    : 'No poojas with this status',
                actionLabel: controller.filter == 'All' ? 'Add Pooja' : null,
                onAction: controller.filter == 'All' ? onAdd : null,
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
                    if (ok == true) await controller.deletePooja(list[i].id);
                  },
                ),
              ),
            );
          }),
        ),
      ],
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
  });
  final PoojaModel pooja;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

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
                Row(
                  children: [
                    Text(
                      pooja.deity,
                      style: const TextStyle(
                        fontSize: 12,
                        color: CmsColors.textSecond,
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
                    if (pooja.audioUrl != null) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.music_note,
                        size: 12,
                        color: CmsColors.textSecond,
                      ),
                    ],
                    if (pooja.videoUrl != null) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.videocam,
                        size: 12,
                        color: CmsColors.textSecond,
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
  late final TextEditingController _durationCtrl;
  late final TextEditingController _descCtrl;
  final _stepCtrl = TextEditingController();
  final _itemCtrl = TextEditingController();

  late String _deity;
  late String _difficulty;
  late String _category;
  late List<String> _steps;
  late List<String> _items;
  String? _imageUrl;
  String? _audioUrl;
  String? _videoUrl;

  static const _deities = [
    'Lord Ganesha',
    'Goddess Lakshmi',
    'Lord Shiva',
    'Lord Hanuman',
    'Lord Vishnu',
    'Goddess Durga',
    'Lord Krishna',
    'Lord Rama',
    'Goddess Saraswati',
  ];
  static const _diffs = ['Beginner', 'Intermediate', 'Advanced'];
  static const _cats = [
    'Daily Pooja',
    'Festival',
    'Special Occasion',
    'Full Moon',
    'New Moon',
    'Fasting',
  ];

  bool get _isEdit => widget.pooja != null;

  @override
  void initState() {
    super.initState();
    final p = widget.pooja;
    _titleCtrl = TextEditingController(text: p?.title ?? '');
    _durationCtrl = TextEditingController(text: p?.duration ?? '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _deity = _deities.contains(p?.deity) ? p!.deity : _deities.first;
    _difficulty = _diffs.contains(p?.difficulty) ? p!.difficulty : _diffs.first;
    _category = _cats.contains(p?.category) ? p!.category : _cats.first;
    _steps = List.from(p?.steps ?? []);
    _items = List.from(p?.requiredItems ?? []);
    _imageUrl = p?.imageUrl;
    _audioUrl = p?.audioUrl;
    _videoUrl = p?.videoUrl;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _durationCtrl.dispose();
    _descCtrl.dispose();
    _stepCtrl.dispose();
    _itemCtrl.dispose();
    super.dispose();
  }

  String? _validate() {
    if (_titleCtrl.text.trim().isEmpty) return 'Pooja name is required';
    if (_descCtrl.text.trim().isEmpty) return 'Description is required';
    if (_durationCtrl.text.trim().isEmpty) return 'Duration is required';
    return null;
  }

  Future<void> _submit({required bool isDraft}) async {
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
    bool ok;
    if (_isEdit) {
      ok = await widget.controller.updatePooja(
        widget.pooja!.id,
        widget.pooja!.copyWith(
          title: _titleCtrl.text.trim(),
          deity: _deity,
          category: _category,
          difficulty: _difficulty,
          duration: _durationCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          status: status,
          imageUrl: _imageUrl,
          audioUrl: _audioUrl,
          videoUrl: _videoUrl,
          steps: _steps,
          requiredItems: _items,
        ),
      );
    } else {
      ok = await widget.controller.createPooja(
        title: _titleCtrl.text.trim(),
        deity: _deity,
        category: _category,
        difficulty: _difficulty,
        duration: _durationCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        status: status,
        imageUrl: _imageUrl,
        audioUrl: _audioUrl,
        videoUrl: _videoUrl,
        steps: _steps,
        requiredItems: _items,
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
                  _isEdit ? 'Edit Pooja' : 'Add New Pooja',
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

  Widget _leftCol() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      CmsFormCard(
        title: 'Basic Information',
        children: [
          CmsFormField(
            label: 'Pooja Name *',
            hint: 'e.g. Ganesh Chaturthi Pooja',
            controller: _titleCtrl,
          ),
          const SizedBox(height: 12),
          CmsFormField(
            label: 'Duration *',
            hint: 'e.g. 45 min',
            controller: _durationCtrl,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CmsDropdownField(
                  label: 'Deity',
                  items: _deities,
                  initialValue: _deity,
                  onChanged: (v) =>
                      setState(() => _deity = v ?? _deities.first),
                ),
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
            onChanged: (v) => setState(() => _category = v ?? _cats.first),
          ),
          const SizedBox(height: 12),
          CmsFormField(
            label: 'Description *',
            hint: 'Enter a brief description...',
            controller: _descCtrl,
            maxLines: 3,
          ),
        ],
      ),
      const SizedBox(height: 16),
      CmsFormCard(
        title: 'Media',
        children: [
          CmsMediaUploadBox(
            label: 'Upload Thumbnail Image',
            icon: Icons.image_outlined,
            accept: 'JPG, PNG up to 5MB',
            uploadedUrl: _imageUrl,
            onTap: () {},
          ),
          const SizedBox(height: 10),
          CmsMediaUploadBox(
            label: 'Upload Audio Mantra',
            icon: Icons.music_note_outlined,
            accept: 'MP3, AAC up to 20MB',
            uploadedUrl: _audioUrl,
            onTap: () {},
          ),
          const SizedBox(height: 10),
          CmsMediaUploadBox(
            label: 'Upload Ritual Video',
            icon: Icons.videocam_outlined,
            accept: 'MP4, MOV up to 200MB',
            uploadedUrl: _videoUrl,
            onTap: () {},
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
        title: 'Required Items',
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
              children: _items
                  .map(
                    (i) => _Chip(
                      label: i,
                      onRemove: () => setState(() => _items.remove(i)),
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

      // Steps
      CmsFormCard(
        title: 'Steps',
        children: [
          _InputRow(
            ctrl: _stepCtrl,
            hint: 'Describe this step...',
            onAdd: () {
              if (_stepCtrl.text.trim().isNotEmpty) {
                setState(() => _steps.add(_stepCtrl.text.trim()));
                _stepCtrl.clear();
              }
            },
          ),
          if (_steps.isNotEmpty) ...[
            const SizedBox(height: 12),
            ..._steps.asMap().entries.map(
              (e) => _StepRow(
                index: e.key + 1,
                text: e.value,
                onRemove: () => setState(() => _steps.removeAt(e.key)),
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
              ),
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
              ),
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
class _InputRow extends StatelessWidget {
  const _InputRow({
    required this.ctrl,
    required this.hint,
    required this.onAdd,
  });
  final TextEditingController ctrl;
  final String hint;
  final VoidCallback onAdd;

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
            controller: ctrl,
            onSubmitted: (_) => onAdd(),
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: hint,
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
      GestureDetector(
        onTap: onAdd,
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
  const _Chip({required this.label, required this.onRemove});
  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: CmsColors.orange.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: CmsColors.orange.withOpacity(0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: CmsColors.orangeDark),
        ),
        const SizedBox(width: 5),
        GestureDetector(
          onTap: onRemove,
          child: const Icon(Icons.close, size: 12, color: CmsColors.orangeDark),
        ),
      ],
    ),
  );
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.index,
    required this.text,
    required this.onRemove,
  });
  final int index;
  final String text;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
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
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: CmsColors.textPrimary),
          ),
        ),
        GestureDetector(
          onTap: onRemove,
          child: const Icon(Icons.close, size: 16, color: Colors.grey),
        ),
      ],
    ),
  );
}
