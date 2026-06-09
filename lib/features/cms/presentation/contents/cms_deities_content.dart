import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/core/services/media_upload_service.dart';
import 'package:satya_devotte_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:satya_devotte_app/features/cms/models/deity_model.dart';
import 'package:satya_devotte_app/features/cms/models/pooja_model.dart';
import 'package:satya_devotte_app/features/cms/presentation/controllers/deity_controller.dart';
import 'package:satya_devotte_app/features/cms/presentation/controllers/pooja_controller.dart';
import 'package:satya_devotte_app/features/cms/presentation/pages/cms_shell_page.dart';
import 'package:satya_devotte_app/features/cms/presentation/widgets/cms_shared_widgets.dart';
import 'package:satya_devotte_app/features/cms/presentation/widgets/cms_upload_box.dart';

class CmsDeitiesContent extends StatefulWidget {
  const CmsDeitiesContent({super.key});

  @override
  State<CmsDeitiesContent> createState() => _CmsDeitiesContentState();
}

class _CmsDeitiesContentState extends State<CmsDeitiesContent> {
  final DeityController _controller = Get.find<DeityController>();
  final AuthController _auth = Get.find<AuthController>();
  bool _showForm = false;
  _DeityItem? _editing;
  String _filter = 'All';
  String _query = '';
  bool _loading = false;
  String? _error;

  final List<_DeityItem> _all = <_DeityItem>[];

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadDeities);
  }

  Future<void> _loadDeities({bool force = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final status = _filter == 'All' ? null : _filter.toUpperCase();
    await _controller.loadDeities(
      page: 1,
      limit: 10,
      status: status,
      force: force,
    );
    if (!mounted) return;
    setState(() {
      _all
        ..clear()
        ..addAll(_controller.deities);
      _error = _controller.error;
      _loading = false;
    });
  }

  List<_DeityItem> get _filtered {
    final q = _query.trim().toLowerCase();
    return _all.where((d) {
      final byStatus = _filter == 'All' || d.status == _filter;
      final byText =
          q.isEmpty ||
          d.name.toLowerCase().contains(q) ||
          d.title.toLowerCase().contains(q);
      return byStatus && byText;
    }).toList();
  }

  Future<void> _save(
    Map<String, dynamic> payload, {
    PickedFile? image,
  }) async {
    final ok = _editing != null
        ? await _controller.updateDeity(
            _editing!.id,
            payload,
            image: image,
          )
        : await _controller.createDeity(
            payload,
            image: image,
          );

    if (!ok) return;

    await _loadDeities(force: true);
    if (!mounted) return;
    setState(() {
      _showForm = false;
      _editing = null;
    });
  }

  Future<void> _openEdit(_DeityItem deity) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final full = await _controller.getDeityById(deity.id);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _editing = full ?? deity;
      _showForm = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showForm) {
      return Container(
        color: CmsColors.bg,
        child: _DeityForm(
          initial: _editing,
          onCancel: () => setState(() {
            _showForm = false;
            _editing = null;
          }),
          onSave: _save,
        ),
      );
    }

    final isWeb = MediaQuery.of(context).size.width >= 768;
    const filters = [
      'All',
      'Approved',
      'Pending',
      'Queued',
      'Draft',
      'Rejected',
    ];
    final list = _filtered;

    return Container(
      color: CmsColors.bg,
      child: Column(
        children: [
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
                    hint: 'Search deities...',
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                const SizedBox(width: 12),
                Obx(
                  () => _controller.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: CmsColors.orange,
                          ),
                        )
                      : GestureDetector(
                          onTap: () => _loadDeities(force: true),
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
                  label: isWeb ? 'Add New Deity' : 'Add',
                  icon: Icons.add,
                  onTap: () => setState(() {
                    _editing = null;
                    _showForm = true;
                  }),
                ),
              ],
            ),
          ),
          Container(
            color: CmsColors.white,
            padding: EdgeInsets.only(left: isWeb ? 24 : 16, bottom: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: filters.map((f) {
                  final sel = _filter == f;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _filter = f);
                      _loadDeities(force: true);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: sel
                            ? CmsColors.orange
                            : CmsColors.bg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: sel
                              ? CmsColors.orange
                              : CmsColors.border,
                        ),
                      ),
                      child: Text(
                        f,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: sel
                              ? Colors.white
                              : CmsColors.textSecond,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: CmsColors.orange),
                  )
                : (_error != null)
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _error!,
                          style: TextStyle(
                            color: CmsColors.textSecond,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => _loadDeities(force: true),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : list.isEmpty
                ? Center(
                    child: Text(
                      'No deities found.',
                      style: TextStyle(
                        color: CmsColors.textSecond,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(isWeb ? 24 : 16),
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final d = list[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: CmsColors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: CmsColors.border,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child:
                                  d.imageUrl != null &&
                                      d.imageUrl!.trim().isNotEmpty
                                  ? Image.network(
                                      d.imageUrl!,
                                      width: 52,
                                      height: 52,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 52,
                                        height: 52,
                                        color: CmsColors.bg,
                                        child: const Icon(
                                          Icons.auto_awesome,
                                          color: CmsColors.orange,
                                        ),
                                      ),
                                    )
                                  : Container(
                                      width: 52,
                                      height: 52,
                                      color: CmsColors.bg,
                                      child: const Icon(
                                        Icons.auto_awesome,
                                        color: CmsColors.orange,
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    d.name,
                                    style: TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w600,
                                      color: CmsColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    d.id,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: CmsColors.textSecond,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      CmsStatusBadge(status: d.status),
                                      if (d.title.trim().isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: CmsColors.bg,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            d.title,
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
                            const SizedBox(width: 8),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CmsActionIcon(
                                      icon: Icons.edit_outlined,
                                      color: Colors.blue,
                                      onTap: () => _openEdit(d),
                                      tooltip: 'Edit',
                                    ),
                                    const SizedBox(width: 6),
                                    CmsActionIcon(
                                      icon: Icons.delete_outline,
                                      color: Colors.red,
                                      onTap: () async {
                                        final confirm =
                                            await showCmsDeleteDialog(
                                              context,
                                              itemName: d.name,
                                            );
                                        if (confirm == true) {
                                          final ok = await _controller
                                              .deleteDeity(d.id);
                                          if (ok) {
                                            _loadDeities(force: true);
                                          }
                                        }
                                      },
                                      tooltip: 'Delete',
                                    ),
                                  ],
                                ),
                                if (_auth.isSuperAdmin &&
                                    (d.status == 'Pending' ||
                                        d.status == 'Queued')) ...[
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      _SmBtn('Queued', Colors.orange, () async {
                                        final ok = await _controller.queueDeity(
                                          d.id,
                                        );
                                        if (ok) {
                                          _loadDeities(force: true);
                                        }
                                      }),
                                      _SmBtn(
                                        d.status == 'Queued'
                                            ? 'Publish Now'
                                            : 'Approve',
                                        Colors.green,
                                        () async {
                                          final ok = await _controller
                                              .approveDeity(d.id);
                                          if (ok) {
                                            _loadDeities(force: true);
                                          }
                                        },
                                      ),
                                      _SmBtn('Reject', Colors.red, () async {
                                        final ok = await _controller
                                            .rejectDeity(d.id);
                                        if (ok) {
                                          _loadDeities(force: true);
                                        }
                                      }),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
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
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

typedef _DeitySaveCallback =
    Future<void> Function(Map<String, dynamic> payload, {PickedFile? image});

class _DeityForm extends StatefulWidget {
  const _DeityForm({
    required this.initial,
    required this.onCancel,
    required this.onSave,
  });
  final _DeityItem? initial;
  final VoidCallback onCancel;
  final _DeitySaveCallback onSave;

  @override
  State<_DeityForm> createState() => _DeityFormState();
}

class _DeityFormState extends State<_DeityForm> {
  bool _isSaving = false;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _alternateNamesCtrl;
  late final TextEditingController _rolesCtrl;
  late final TextEditingController _lineageParentsCtrl;
  late final TextEditingController _lineageConsortCtrl;
  late final TextEditingController _lineageChildrenCtrl;
  late final TextEditingController _lineageVehicleCtrl;
  late final TextEditingController _lineageAbodeCtrl;
  late final TextEditingController _appearanceTitleCtrl;
  late final TextEditingController _appearanceDescCtrl;
  late final TextEditingController _spiritualTitleCtrl;
  late final TextEditingController _spiritualDescCtrl;
  late final TextEditingController _connectingHowToPrayCtrl;
  late final TextEditingController _connectingWhatPleasesCtrl;
  late final TextEditingController _connectingDispleasesCtrl;
  late final TextEditingController _connectingIdealTimeCtrl;
  late final TextEditingController _chantingMantraCtrl;
  late final TextEditingController _chantingRepetitionsCtrl;
  late final TextEditingController _chantingBenefitsCtrl;
  late final TextEditingController _chantingAssociatedColorsCtrl;
  late final TextEditingController _homePlacementCtrl;
  late final TextEditingController _homeOfferingsCtrl;
  late final TextEditingController _homeDoCtrl;
  late final TextEditingController _homeDontCtrl;
  late final TextEditingController _devotionalSignCtrl;
  late final TextEditingController _devotionalNotesCtrl;
  late final TextEditingController _storiesTitleCtrl;
  late final TextEditingController _storiesDescCtrl;
  String _status = 'PENDING';
  late final TextEditingController _imageUrlsCtrl;
  final List<Map<String, String>> _lineageFormsEntries =
      <Map<String, String>>[];
  final List<Map<String, String>> _appearanceEntries = <Map<String, String>>[];
  final List<Map<String, String>> _spiritualEntries = <Map<String, String>>[];
  final List<Map<String, String>> _storiesEntries = <Map<String, String>>[];
  final List<String> _alternateNames = <String>[];
  final List<String> _roles = <String>[];
  final List<String> _ritualIds = <String>[];
  final List<String> _whatPleases = <String>[];
  final List<String> _displeases = <String>[];
  final List<String> _chantBenefits = <String>[];
  final List<String> _preferredDays = <String>[];
  final List<String> _associatedColors = <String>[];
  final List<String> _homeOfferings = <String>[];
  final List<String> _homeDos = <String>[];
  final List<String> _homeDonts = <String>[];
  final List<PoojaModel> _poojaOptions = <PoojaModel>[];
  bool _isLoadingPoojas = false;
  static const List<String> _weekDays = <String>[
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];
  bool _showLineageFormsEditor = false;
  bool _showAppearanceEditor = false;
  bool _showSpiritualEditor = false;
  bool _showStoriesEditor = false;
  late final TextEditingController _lineageFormsTitleCtrl;
  late final TextEditingController _lineageFormsDescCtrl;
  PickedFile? _pickedImage;
  String? _deityColor;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _status = (initial?.status ?? 'Pending').toUpperCase();
    _deityColor = initial?.deityColor.trim().isEmpty == true
        ? null
        : initial?.deityColor;
    _nameCtrl = TextEditingController(text: initial?.name ?? '');
    _descCtrl = TextEditingController(text: initial?.description ?? '');
    _alternateNamesCtrl = TextEditingController();
    _rolesCtrl = TextEditingController();
    _lineageParentsCtrl = TextEditingController(
      text: initial == null ? '' : initial.lineageParents.join(', '),
    );
    _lineageConsortCtrl = TextEditingController(
      text: initial?.lineageConsort ?? '',
    );
    _lineageChildrenCtrl = TextEditingController(
      text: initial == null ? '' : initial.lineageChildren.join(', '),
    );
    _lineageVehicleCtrl = TextEditingController(
      text: initial?.lineageVehicle ?? '',
    );
    _lineageAbodeCtrl = TextEditingController(
      text: initial?.lineageAbode ?? '',
    );
    _appearanceTitleCtrl = TextEditingController();
    _appearanceDescCtrl = TextEditingController();
    _spiritualTitleCtrl = TextEditingController();
    _spiritualDescCtrl = TextEditingController();
    _connectingHowToPrayCtrl = TextEditingController(
      text: initial?.connectingHowToPray ?? '',
    );
    _connectingWhatPleasesCtrl = TextEditingController();
    _connectingDispleasesCtrl = TextEditingController();
    _connectingIdealTimeCtrl = TextEditingController(
      text: initial?.connectingIdealTime ?? '',
    );
    _chantingMantraCtrl = TextEditingController(
      text: initial?.chantingMantra ?? '',
    );
    _chantingRepetitionsCtrl = TextEditingController(
      text: initial?.chantingRepetitions ?? '',
    );
    _chantingBenefitsCtrl = TextEditingController();
    _chantingAssociatedColorsCtrl = TextEditingController();
    _homePlacementCtrl = TextEditingController(
      text: initial?.homePlacement ?? '',
    );
    _homeOfferingsCtrl = TextEditingController();
    _homeDoCtrl = TextEditingController();
    _homeDontCtrl = TextEditingController();
    _devotionalSignCtrl = TextEditingController(
      text: initial?.devotionalSignOfConnection ?? '',
    );
    _devotionalNotesCtrl = TextEditingController(
      text: initial?.devotionalNotes ?? '',
    );
    _storiesTitleCtrl = TextEditingController();
    _storiesDescCtrl = TextEditingController();
    _imageUrlsCtrl = TextEditingController(text: initial?.imageUrl ?? '');
    _lineageFormsTitleCtrl = TextEditingController();
    _lineageFormsDescCtrl = TextEditingController();
    if (initial != null) {
      _alternateNames.addAll(initial.alternateNames);
      _roles.addAll(initial.roles);
      _ritualIds.addAll(initial.rituals);
      _appearanceEntries.addAll(initial.appearance);
      _spiritualEntries.addAll(initial.spiritualSignificance);
      _whatPleases.addAll(initial.connectingWhatPleases);
      _displeases.addAll(initial.connectingDispleases);
      _chantBenefits.addAll(initial.chantingBenefits);
      _preferredDays.addAll(initial.chantingPreferredDays);
      _associatedColors.addAll(initial.chantingAssociatedColors);
      _homeOfferings.addAll(initial.homeOfferings);
      _homeDos.addAll(initial.homeDo);
      _homeDonts.addAll(initial.homeDont);
      _storiesEntries.addAll(initial.stories);
      _lineageFormsEntries.addAll(
        initial.structure.isNotEmpty
            ? initial.structure
            : (initial.lineageForms.isNotEmpty
                  ? initial.lineageForms
                  : initial.lineageParents
                        .map((p) => {'title': p, 'description': ''})
                        .toList()),
      );
    }
    Future.microtask(_loadRitualOptions);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _alternateNamesCtrl.dispose();
    _rolesCtrl.dispose();
    _lineageParentsCtrl.dispose();
    _lineageConsortCtrl.dispose();
    _lineageChildrenCtrl.dispose();
    _lineageVehicleCtrl.dispose();
    _lineageAbodeCtrl.dispose();
    _appearanceTitleCtrl.dispose();
    _appearanceDescCtrl.dispose();
    _spiritualTitleCtrl.dispose();
    _spiritualDescCtrl.dispose();
    _connectingHowToPrayCtrl.dispose();
    _connectingWhatPleasesCtrl.dispose();
    _connectingDispleasesCtrl.dispose();
    _connectingIdealTimeCtrl.dispose();
    _chantingMantraCtrl.dispose();
    _chantingRepetitionsCtrl.dispose();
    _chantingBenefitsCtrl.dispose();
    _chantingAssociatedColorsCtrl.dispose();
    _homePlacementCtrl.dispose();
    _homeOfferingsCtrl.dispose();
    _homeDoCtrl.dispose();
    _homeDontCtrl.dispose();
    _devotionalSignCtrl.dispose();
    _devotionalNotesCtrl.dispose();
    _storiesTitleCtrl.dispose();
    _storiesDescCtrl.dispose();
    _imageUrlsCtrl.dispose();
    _lineageFormsTitleCtrl.dispose();
    _lineageFormsDescCtrl.dispose();
    super.dispose();
  }

  List<String> _csv(String value) =>
      value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  void _addChipValue(TextEditingController ctrl, List<String> target) {
    final value = ctrl.text.trim();
    if (value.isEmpty) return;
    setState(() {
      if (!target.contains(value)) target.add(value);
      ctrl.clear();
    });
  }

  List<String> _valuesWithPending(
    TextEditingController ctrl,
    List<String> values,
  ) {
    final pending = ctrl.text.trim();
    if (pending.isEmpty) return List<String>.from(values);
    if (values.contains(pending)) return List<String>.from(values);
    return <String>[...values, pending];
  }

  Future<void> _loadRitualOptions() async {
    try {
      final poojaController = Get.find<PoojaController>();
      if (poojaController.poojas.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          _poojaOptions
            ..clear()
            ..addAll(poojaController.poojas);
        });
        return;
      }
      setState(() => _isLoadingPoojas = true);
      await poojaController.loadPoojas();
      if (!mounted) return;
      setState(() {
        _poojaOptions
          ..clear()
          ..addAll(poojaController.poojas);
        _isLoadingPoojas = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingPoojas = false);
    }
  }

  String _ritualTitleForId(String id) {
    for (final pooja in _poojaOptions) {
      if (pooja.id == id) return pooja.title;
    }
    final cached = widget.initial?.ritualTitles[id];
    if (cached != null && cached.isNotEmpty) return cached;
    return id;
  }

  void _addKeyValueEntry({
    required TextEditingController titleCtrl,
    required TextEditingController descCtrl,
    required List<Map<String, String>> target,
  }) {
    final title = titleCtrl.text.trim();
    final description = descCtrl.text.trim();
    if (title.isEmpty && description.isEmpty) return;
    if (title.isEmpty) {
      showCmsSnackbar(
        title: 'Validation',
        message: 'Title is required',
        isError: true,
      );
      return;
    }
    setState(() {
      target.add({'title': title, 'description': description});
      titleCtrl.clear();
      descCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width >= 768;
    final detailsCard = CmsFormCard(
      title: 'Deity Overview',
      children: [
        CmsFormField(
          label: 'Deity Name *',
          hint: 'e.g. Lord Ganesha',
          controller: _nameCtrl,
        ),
        const SizedBox(height: 12),
        CmsFormField(
          label: 'Description',
          hint: 'e.g. Remover of obstacles',
          controller: _descCtrl,
          maxLines: 3,
        ),
        const SizedBox(height: 12),
        _DeityColorField(
          value: _deityColor,
          onChanged: (color) => setState(() => _deityColor = color),
        ),
        const SizedBox(height: 12),
        _ChipListEditor(
          label: 'Alternate Names',
          hint: 'e.g. Ganapati, Vinayaka',
          controller: _alternateNamesCtrl,
          values: _alternateNames,
          onAdd: () => _addChipValue(_alternateNamesCtrl, _alternateNames),
          onRemove: (index) => setState(() => _alternateNames.removeAt(index)),
        ),
        const SizedBox(height: 12),
        _ChipListEditor(
          label: 'Roles',
          hint: 'e.g. wisdom, prosperity',
          controller: _rolesCtrl,
          values: _roles,
          onAdd: () => _addChipValue(_rolesCtrl, _roles),
          onRemove: (index) => setState(() => _roles.removeAt(index)),
        ),
        const SizedBox(height: 12),
        _MultiSelectPickerField(
          fieldLabel: 'Associate Pujas',
          hintText: _isLoadingPoojas ? 'Loading poojas...' : 'Select Pujas',
          options: _poojaOptions
              .map((p) => _MultiSelectOption(value: p.id, label: p.title))
              .toList(),
          selectedValues: _ritualIds,
          onChanged: (values) => setState(() {
            _ritualIds
              ..clear()
              ..addAll(values);
          }),
        ),
        const SizedBox(height: 10),
        if (_ritualIds.isEmpty)
          Text(
            'No entries added yet',
            style: TextStyle(
              fontSize: 12,
              color: CmsColors.textSecond,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _ritualIds
                .asMap()
                .entries
                .map(
                  (entry) => _CompactChip(
                    label: _ritualTitleForId(entry.value),
                    onRemove: () =>
                        setState(() => _ritualIds.removeAt(entry.key)),
                  ),
                )
                .toList(),
          ),
      ],
    );
    final metaCard = CmsFormCard(
      title: 'Divine Structure & Lineage',
      children: [
        _KeyValueEditor(
          heading: 'Family / Divine Associations / Seating / Iconography',
          showEditor: _showLineageFormsEditor,
          onToggle: () => setState(
            () => _showLineageFormsEditor = !_showLineageFormsEditor,
          ),
          titleCtrl: _lineageFormsTitleCtrl,
          descCtrl: _lineageFormsDescCtrl,
          onAdd: () => _addKeyValueEntry(
            titleCtrl: _lineageFormsTitleCtrl,
            descCtrl: _lineageFormsDescCtrl,
            target: _lineageFormsEntries,
          ),
          entries: _lineageFormsEntries,
          onRemove: (index) =>
              setState(() => _lineageFormsEntries.removeAt(index)),
        ),
      ],
    );
    final sectionsCard = CmsFormCard(
      title: 'Appearance & Symbolism',
      children: [
        _KeyValueEditor(
          heading: 'Appearance & Symbolism',
          showEditor: _showAppearanceEditor,
          onToggle: () =>
              setState(() => _showAppearanceEditor = !_showAppearanceEditor),
          titleCtrl: _appearanceTitleCtrl,
          descCtrl: _appearanceDescCtrl,
          onAdd: () => _addKeyValueEntry(
            titleCtrl: _appearanceTitleCtrl,
            descCtrl: _appearanceDescCtrl,
            target: _appearanceEntries,
          ),
          entries: _appearanceEntries,
          onRemove: (index) =>
              setState(() => _appearanceEntries.removeAt(index)),
        ),
      ],
    );
    final spiritualCard = CmsFormCard(
      title: 'Spiritual Significance',
      children: [
        _KeyValueEditor(
          heading: 'Spiritual Significance',
          showEditor: _showSpiritualEditor,
          onToggle: () =>
              setState(() => _showSpiritualEditor = !_showSpiritualEditor),
          titleCtrl: _spiritualTitleCtrl,
          descCtrl: _spiritualDescCtrl,
          onAdd: () => _addKeyValueEntry(
            titleCtrl: _spiritualTitleCtrl,
            descCtrl: _spiritualDescCtrl,
            target: _spiritualEntries,
          ),
          entries: _spiritualEntries,
          onRemove: (index) =>
              setState(() => _spiritualEntries.removeAt(index)),
        ),
      ],
    );
    final connectingCard = CmsFormCard(
      title: 'Connecting with Deity',
      children: [
        CmsFormField(
          label: 'How to Invoke / Call Upon This Deity',
          hint: 'Enter prayer guidance',
          controller: _connectingHowToPrayCtrl,
          maxLines: 3,
        ),
        const SizedBox(height: 12),
        _ChipListEditor(
          label: 'What Pleases / Appeases This Deity',
          hint: 'e.g. Sincerity, discipline, devotion',
          controller: _connectingWhatPleasesCtrl,
          values: _whatPleases,
          onAdd: () => _addChipValue(_connectingWhatPleasesCtrl, _whatPleases),
          onRemove: (index) => setState(() => _whatPleases.removeAt(index)),
        ),
        const SizedBox(height: 12),
        _ChipListEditor(
          label: 'What May Displease / Trigger This Deity',
          hint: 'e.g. Arrogance, disrespect',
          controller: _connectingDispleasesCtrl,
          values: _displeases,
          onAdd: () => _addChipValue(_connectingDispleasesCtrl, _displeases),
          onRemove: (index) => setState(() => _displeases.removeAt(index)),
        ),
        const SizedBox(height: 12),
        CmsFormField(
          label: 'Ideal Time',
          hint: 'e.g. Morning',
          controller: _connectingIdealTimeCtrl,
        ),
      ],
    );
    final chantingCard = CmsFormCard(
      title: 'Prayer & Chanting',
      children: [
        CmsFormField(
          label: 'Recommended Mantra / Chant ',
          hint: 'Enter mantra',
          controller: _chantingMantraCtrl,
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        CmsFormField(
          label: 'Repetitions',
          hint: 'e.g. 108',
          controller: _chantingRepetitionsCtrl,
        ),
        const SizedBox(height: 12),
        _ChipListEditor(
          label: 'Benefits',
          hint: 'e.g. focus, calmness',
          controller: _chantingBenefitsCtrl,
          values: _chantBenefits,
          onAdd: () => _addChipValue(_chantingBenefitsCtrl, _chantBenefits),
          onRemove: (index) => setState(() => _chantBenefits.removeAt(index)),
        ),
        const SizedBox(height: 12),
        _MultiSelectPickerField(
          fieldLabel: 'Preferred Days',
          hintText: 'Select preferred days',
          options: _weekDays
              .map((d) => _MultiSelectOption(value: d, label: d))
              .toList(),
          selectedValues: _preferredDays,
          onChanged: (values) => setState(() {
            _preferredDays
              ..clear()
              ..addAll(values);
          }),
        ),
        const SizedBox(height: 10),
        if (_preferredDays.isEmpty)
          Text(
            'No entries added yet',
            style: TextStyle(
              fontSize: 12,
              color: CmsColors.textSecond,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _preferredDays
                .asMap()
                .entries
                .map(
                  (entry) => _CompactChip(
                    label: entry.value,
                    onRemove: () =>
                        setState(() => _preferredDays.removeAt(entry.key)),
                  ),
                )
                .toList(),
          ),
        const SizedBox(height: 12),
        _ChipListEditor(
          label: 'Associated Colors',
          hint: 'e.g. Green, Yellow',
          controller: _chantingAssociatedColorsCtrl,
          values: _associatedColors,
          onAdd: () =>
              _addChipValue(_chantingAssociatedColorsCtrl, _associatedColors),
          onRemove: (index) =>
              setState(() => _associatedColors.removeAt(index)),
        ),
      ],
    );
    final homePracticeCard = CmsFormCard(
      title: 'Home Practice Guidance ',
      children: [
        CmsFormField(
          label: 'Murthi / Image Placement in the Home ',
          hint: 'Where to place deity/image at home',
          controller: _homePlacementCtrl,
        ),
        const SizedBox(height: 12),
        _ChipListEditor(
          label: 'Suggested Offerings (Prasad)',
          hint: 'e.g. flowers, fruits',
          controller: _homeOfferingsCtrl,
          values: _homeOfferings,
          onAdd: () => _addChipValue(_homeOfferingsCtrl, _homeOfferings),
          onRemove: (index) => setState(() => _homeOfferings.removeAt(index)),
        ),
        const SizedBox(height: 12),
        _ChipListEditor(
          label: 'Do',
          hint: 'e.g. keep clean, light lamp',
          controller: _homeDoCtrl,
          values: _homeDos,
          onAdd: () => _addChipValue(_homeDoCtrl, _homeDos),
          onRemove: (index) => setState(() => _homeDos.removeAt(index)),
        ),
        const SizedBox(height: 12),
        _ChipListEditor(
          label: 'Don\'t',
          hint: 'e.g. avoid clutter',
          controller: _homeDontCtrl,
          values: _homeDonts,
          onAdd: () => _addChipValue(_homeDontCtrl, _homeDonts),
          onRemove: (index) => setState(() => _homeDonts.removeAt(index)),
        ),
      ],
    );
    final devotionalCard = CmsFormCard(
      title: 'Devotional Experience',
      children: [
        CmsFormField(
          label: 'Sign of Connection',
          hint: 'Describe signs of connection',
          controller: _devotionalSignCtrl,
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        CmsFormField(
          label: 'Notes',
          hint: 'Personal reflection notes',
          controller: _devotionalNotesCtrl,
          maxLines: 3,
        ),
      ],
    );
    final storiesCard = CmsFormCard(
      title: 'Stories',
      children: [
        _KeyValueEditor(
          heading: 'Stories',
          showEditor: _showStoriesEditor,
          onToggle: () =>
              setState(() => _showStoriesEditor = !_showStoriesEditor),
          titleCtrl: _storiesTitleCtrl,
          descCtrl: _storiesDescCtrl,
          onAdd: () => _addKeyValueEntry(
            titleCtrl: _storiesTitleCtrl,
            descCtrl: _storiesDescCtrl,
            target: _storiesEntries,
          ),
          entries: _storiesEntries,
          onRemove: (index) => setState(() => _storiesEntries.removeAt(index)),
        ),
      ],
    );
    final mediaCard = CmsFormCard(
      title: 'Media',
      children: [
        CmsUploadBox(
          label: 'Thumbnail Image',
          icon: Icons.image_outlined,
          accept: 'JPG, PNG up to 5MB',
          mediaType: PickMediaType.image,
          initialUrl: widget.initial?.imageUrl,
          onPicked: (file) => setState(() => _pickedImage = file),
          onRemoved: () => setState(() {
            _pickedImage = null;
            _imageUrlsCtrl.clear();
          }),
        ),
      ],
    );

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
                  child: Icon(
                    Icons.arrow_back,
                    size: 18,
                    color: CmsColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                widget.initial == null ? 'Add New Deity' : 'Edit Deity',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: CmsColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isWeb)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      detailsCard,
                      const SizedBox(height: 16),
                      mediaCard,
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      metaCard,
                      const SizedBox(height: 16),
                      sectionsCard,
                      const SizedBox(height: 16),
                      spiritualCard,
                      const SizedBox(height: 16),
                      connectingCard,
                      const SizedBox(height: 16),
                      chantingCard,
                      const SizedBox(height: 16),
                      homePracticeCard,
                      const SizedBox(height: 16),
                      devotionalCard,
                      const SizedBox(height: 16),
                      storiesCard,
                    ],
                  ),
                ),
              ],
            )
          else ...[
            detailsCard,
            const SizedBox(height: 16),
            metaCard,
            const SizedBox(height: 16),
            sectionsCard,
            const SizedBox(height: 16),
            spiritualCard,
            const SizedBox(height: 16),
            connectingCard,
            const SizedBox(height: 16),
            chantingCard,
            const SizedBox(height: 16),
            homePracticeCard,
            const SizedBox(height: 16),
            devotionalCard,
            const SizedBox(height: 16),
            storiesCard,
            const SizedBox(height: 16),
            mediaCard,
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSaving ? null : widget.onCancel,
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _submitDeity,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CmsColors.orange,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: CmsColors.orange.withOpacity(0.6),
                    disabledForegroundColor: Colors.white,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Text('Save Deity'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _submitDeity() async {
    if (_isSaving) return;
    if (_pickedImage != null &&
        _pickedImage!.bytes.length > CmsUploadBox.defaultMaxImageBytes) {
      CmsUploadBox.showFileTooLargeError(
        actualBytes: _pickedImage!.bytes.length,
        maxBytes: CmsUploadBox.defaultMaxImageBytes,
        label: 'Thumbnail image',
      );
      return;
    }
    if (_nameCtrl.text.trim().isEmpty) {
      showCmsSnackbar(
        title: 'Validation',
        message: 'Deity name is required',
        isError: true,
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      await widget.onSave(
        {
                      'name': _nameCtrl.text.trim(),
                      'deity_color': _deityColor?.trim() ?? '',
                      'alternate_names': _valuesWithPending(
                        _alternateNamesCtrl,
                        _alternateNames,
                      ),
                      'description': _descCtrl.text.trim(),
                      'roles': _valuesWithPending(_rolesCtrl, _roles),
                      'lineage': {
                        'parents': _csv(_lineageParentsCtrl.text),
                        'consort': _lineageConsortCtrl.text.trim(),
                        'children': _csv(_lineageChildrenCtrl.text),
                        'vehicle': _lineageVehicleCtrl.text.trim(),
                        'abode': _lineageAbodeCtrl.text.trim(),
                      },
                      'structure': _lineageFormsEntries,
                      'appearance': _appearanceEntries,
                      'spiritual_significance': _spiritualEntries,
                      'connecting': {
                        'how_to_pray': _connectingHowToPrayCtrl.text.trim(),
                        'what_pleases': _valuesWithPending(
                          _connectingWhatPleasesCtrl,
                          _whatPleases,
                        ),
                        'displeases': _valuesWithPending(
                          _connectingDispleasesCtrl,
                          _displeases,
                        ),
                        'ideal_time': _csv(_connectingIdealTimeCtrl.text),
                      },
                      'chanting': {
                        'mantra': _chantingMantraCtrl.text.trim(),
                        'repetitions': _chantingRepetitionsCtrl.text.trim(),
                        'benefits': _valuesWithPending(
                          _chantingBenefitsCtrl,
                          _chantBenefits,
                        ),
                        'preferred_days': List<String>.from(_preferredDays),
                        'associated_colors': _valuesWithPending(
                          _chantingAssociatedColorsCtrl,
                          _associatedColors,
                        ),
                      },
                      'home_practice': {
                        'placement': _homePlacementCtrl.text.trim(),
                        'offerings': _valuesWithPending(
                          _homeOfferingsCtrl,
                          _homeOfferings,
                        ),
                        'do_and_dont': {
                          'do': _valuesWithPending(_homeDoCtrl, _homeDos),
                          'dont': _valuesWithPending(_homeDontCtrl, _homeDonts),
                        },
                      },
                      'devotional_experience': {
                        'sign_of_connection':
                            _devotionalSignCtrl.text.trim(),
                        'notes': _devotionalNotesCtrl.text.trim(),
                      },
                      'stories': _storiesEntries,
                      'pujas': List<String>.from(_ritualIds),
                      'media': {
                        'images': _csv(_imageUrlsCtrl.text),
                      },
                      'status': _status,
                    },
        image: _pickedImage,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _KeyValueEditor extends StatelessWidget {
  const _KeyValueEditor({
    required this.heading,
    required this.showEditor,
    required this.onToggle,
    required this.titleCtrl,
    required this.descCtrl,
    required this.onAdd,
    required this.entries,
    required this.onRemove,
  });

  final String heading;
  final bool showEditor;
  final VoidCallback onToggle;
  final TextEditingController titleCtrl;
  final TextEditingController descCtrl;
  final VoidCallback onAdd;
  final List<Map<String, String>> entries;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                heading,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: CmsColors.textSecond,
                ),
              ),
            ),
            Tooltip(
              message: showEditor ? 'Hide entry form' : 'Show entry form',
              child: GestureDetector(
                onTap: onToggle,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: CmsColors.bg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: CmsColors.border),
                  ),
                  child: Icon(
                    showEditor
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: CmsColors.textSecond,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (showEditor) ...[
          const SizedBox(height: 10),
          CmsFormField(
            label: '$heading Title',
            hint: 'Enter title',
            controller: titleCtrl,
          ),
          const SizedBox(height: 10),
          CmsFormField(
            label: '$heading Description',
            hint: 'Enter description',
            controller: descCtrl,
            maxLines: 3,
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: onAdd,
              style: ElevatedButton.styleFrom(
                backgroundColor: CmsColors.orange,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Add entry'),
            ),
          ),
        ],
        if (entries.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'No entries added yet',
              style: TextStyle(
                fontSize: 12,
                color: CmsColors.textSecond,
              ),
            ),
          )
        else ...[
          const SizedBox(height: 8),
          ...entries.asMap().entries.map((entry) {
            final title = (entry.value['title'] ?? '').trim();
            final description = (entry.value['description'] ?? '').trim();
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: CmsColors.bg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: CmsColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      description.isEmpty ? title : '$title\n$description',
                      style: const TextStyle(
                        fontSize: 12,
                        color: CmsThemeColors.inputText,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => onRemove(entry.key),
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: CmsColors.textSecond,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }
}

class _ChipListEditor extends StatelessWidget {
  const _ChipListEditor({
    required this.label,
    required this.hint,
    required this.controller,
    required this.values,
    required this.onAdd,
    required this.onRemove,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final List<String> values;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: CmsColors.textSecond,
          ),
        ),
        const SizedBox(height: 8),
        _InputRow(ctrl: controller, hint: hint, onAdd: onAdd),
        if (values.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              'No entries added yet',
              style: TextStyle(
                fontSize: 12,
                color: CmsColors.textSecond,
              ),
            ),
          )
        else ...[
          const SizedBox(height: 10),
          ...values.asMap().entries.map(
            (entry) => _LineChip(
              label: entry.value,
              onRemove: () => onRemove(entry.key),
            ),
          ),
        ],
      ],
    );
  }
}

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
  Widget build(BuildContext context) {
    return Row(
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
              cursorColor: CmsColors.orange,
              style: const TextStyle(
                fontSize: 13,
                color: CmsThemeColors.inputText,
              ),
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                hintStyle: const TextStyle(
                  color: CmsThemeColors.inputHint,
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
}

class _LineChip extends StatelessWidget {
  const _LineChip({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: CmsColors.bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CmsColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: CmsThemeColors.inputText,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close,
              size: 16,
              color: CmsColors.textSecond,
            ),
          ),
        ],
      ),
    );
  }
}

class _MultiSelectOption {
  const _MultiSelectOption({required this.value, required this.label});
  final String value;
  final String label;
}

class _MultiSelectPickerField extends StatelessWidget {
  const _MultiSelectPickerField({
    required this.fieldLabel,
    required this.hintText,
    required this.options,
    required this.selectedValues,
    required this.onChanged,
  });

  final String fieldLabel;
  final String hintText;
  final List<_MultiSelectOption> options;
  final List<String> selectedValues;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = selectedValues.isEmpty
        ? hintText
        : '${selectedValues.length} selected';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          fieldLabel,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: CmsColors.textSecond,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final current = List<String>.from(selectedValues);
            final picked = await showModalBottomSheet<List<String>>(
              context: context,
              isScrollControlled: true,
              builder: (ctx) {
                final temp = List<String>.from(current);
                return StatefulBuilder(
                  builder: (context, setInnerState) {
                    return SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Select options',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: CmsColors.textPrimary,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(temp),
                                  child: const Text('Done'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Flexible(
                              child: ListView(
                                shrinkWrap: true,
                                children: options.map((o) {
                                  final checked = temp.contains(o.value);
                                  return CheckboxListTile(
                                    dense: true,
                                    value: checked,
                                    title: Text(
                                      o.label,
                                      style: const TextStyle(
                                        color: CmsThemeColors.inputText,
                                      ),
                                    ),
                                    onChanged: (v) {
                                      setInnerState(() {
                                        if (v == true) {
                                          if (!temp.contains(o.value))
                                            temp.add(o.value);
                                        } else {
                                          temp.remove(o.value);
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
            if (picked != null) onChanged(picked);
          },
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: CmsColors.bg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: CmsColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      color: selectedValues.isEmpty
                          ? CmsThemeColors.inputHint
                          : CmsThemeColors.inputText,
                      fontSize: 13,
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: CmsColors.textSecond,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CompactChip extends StatelessWidget {
  const _CompactChip({required this.label, required this.onRemove});
  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: CmsColors.bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CmsColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: CmsThemeColors.inputText,
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close,
              size: 14,
              color: CmsColors.textSecond,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Deity color (single color picker) ──────────────────────────────
const List<Color> _presetDeityColors = <Color>[
  Color(0xFFE53935),
  Color(0xFFFF9933),
  Color(0xFFFDD835),
  Color(0xFF43A047),
  Color(0xFF1E88E5),
  Color(0xFF8E24AA),
  Color(0xFFE91E63),
  Color(0xFF795548),
  Color(0xFFFFFFFF),
  Color(0xFF212121),
];

const Map<String, Color> _namedDeityColors = <String, Color>{
  'red': Color(0xFFE53935),
  'orange': Color(0xFFFF9933),
  'saffron': Color(0xFFFF9933),
  'yellow': Color(0xFFFDD835),
  'green': Color(0xFF43A047),
  'blue': Color(0xFF1E88E5),
  'purple': Color(0xFF8E24AA),
  'pink': Color(0xFFE91E63),
  'brown': Color(0xFF795548),
  'white': Color(0xFFFFFFFF),
  'black': Color(0xFF212121),
  'gold': Color(0xFFFFD700),
};

Color? _tryParseDeityColor(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;

  var hex = trimmed;
  if (hex.startsWith('#')) hex = hex.substring(1);
  if (RegExp(r'^[0-9A-Fa-f]{6}$').hasMatch(hex)) {
    final parsed = int.tryParse('FF$hex', radix: 16);
    if (parsed != null) return Color(parsed);
  }
  if (RegExp(r'^[0-9A-Fa-f]{8}$').hasMatch(hex)) {
    final parsed = int.tryParse(hex, radix: 16);
    if (parsed != null) return Color(parsed);
  }

  return _namedDeityColors[trimmed.toLowerCase()];
}

String _colorToHex(Color color) {
  final r = (color.r * 255).round();
  final g = (color.g * 255).round();
  final b = (color.b * 255).round();
  return '#${r.toRadixString(16).padLeft(2, '0')}'
      '${g.toRadixString(16).padLeft(2, '0')}'
      '${b.toRadixString(16).padLeft(2, '0')}'
      .toUpperCase();
}

class _DeityColorField extends StatelessWidget {
  const _DeityColorField({
    required this.value,
    required this.onChanged,
  });

  final String? value;
  final ValueChanged<String?> onChanged;

  Future<void> _openPicker(BuildContext context) async {
    final initial = value != null ? _tryParseDeityColor(value!) : null;
    final picked = await showDialog<Color>(
      context: context,
      builder: (ctx) => _CmsColorPickerDialog(initialColor: initial),
    );
    if (picked != null) onChanged(_colorToHex(picked));
  }

  @override
  Widget build(BuildContext context) {
    final parsed = value != null ? _tryParseDeityColor(value!) : null;
    final hasColor = value != null && value!.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Deity Color',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: CmsColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => _openPicker(context),
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: CmsColors.bg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: CmsColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: parsed ?? CmsColors.bg,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: hasColor ? Colors.black12 : CmsColors.border,
                    ),
                  ),
                  child: hasColor
                      ? null
                      : const Icon(
                          Icons.palette_outlined,
                          size: 14,
                          color: CmsColors.textSecond,
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hasColor ? value! : 'Select deity color',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: hasColor
                          ? CmsThemeColors.inputText
                          : CmsThemeColors.inputHint,
                    ),
                  ),
                ),
                if (hasColor)
                  GestureDetector(
                    onTap: () => onChanged(null),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: CmsColors.textSecond,
                      ),
                    ),
                  ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: CmsColors.textSecond,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CmsColorPickerDialog extends StatefulWidget {
  const _CmsColorPickerDialog({this.initialColor});

  final Color? initialColor;

  @override
  State<_CmsColorPickerDialog> createState() => _CmsColorPickerDialogState();
}

class _CmsColorPickerDialogState extends State<_CmsColorPickerDialog> {
  late Color _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialColor ?? const Color(0xFFFF9933);
  }

  void _setColor(Color color) => setState(() => _selected = color);

  void _updateHsl({double? hue, double? saturation, double? lightness}) {
    final hsl = HSLColor.fromColor(_selected);
    setState(() {
      _selected = hsl
          .withHue(hue ?? hsl.hue)
          .withSaturation(saturation ?? hsl.saturation)
          .withLightness(lightness ?? hsl.lightness)
          .toColor();
    });
  }

  @override
  Widget build(BuildContext context) {
    final hsl = HSLColor.fromColor(_selected);

    return AlertDialog(
      backgroundColor: CmsColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: const Text(
        'Select deity color',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: CmsColors.textPrimary,
        ),
      ),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: _selected,
                  shape: BoxShape.circle,
                  border: Border.all(color: CmsColors.border, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                _colorToHex(_selected),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: CmsColors.textSecond,
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Quick picks',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: CmsColors.textSecond,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _presetDeityColors.map((color) {
                final selected = _colorToHex(color) == _colorToHex(_selected);
                return GestureDetector(
                  onTap: () => _setColor(color),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? CmsColors.orange : CmsColors.border,
                        width: selected ? 2 : 1,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            const Text(
              'Hue',
              style: TextStyle(fontSize: 12, color: CmsColors.textSecond),
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: CmsColors.orange,
                thumbColor: CmsColors.orange,
                overlayColor: CmsColors.orange.withOpacity(0.12),
              ),
              child: Slider(
                value: hsl.hue,
                min: 0,
                max: 360,
                onChanged: (v) => _updateHsl(hue: v),
              ),
            ),
            const Text(
              'Saturation',
              style: TextStyle(fontSize: 12, color: CmsColors.textSecond),
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: CmsColors.orange,
                thumbColor: CmsColors.orange,
                overlayColor: CmsColors.orange.withOpacity(0.12),
              ),
              child: Slider(
                value: hsl.saturation,
                min: 0,
                max: 1,
                onChanged: (v) => _updateHsl(saturation: v),
              ),
            ),
            const Text(
              'Lightness',
              style: TextStyle(fontSize: 12, color: CmsColors.textSecond),
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: CmsColors.orange,
                thumbColor: CmsColors.orange,
                overlayColor: CmsColors.orange.withOpacity(0.12),
              ),
              child: Slider(
                value: hsl.lightness,
                min: 0,
                max: 1,
                onChanged: (v) => _updateHsl(lightness: v),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_selected),
          style: ElevatedButton.styleFrom(
            backgroundColor: CmsColors.orange,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          child: const Text('Select'),
        ),
      ],
    );
  }
}

typedef _DeityItem = DeityModel;
