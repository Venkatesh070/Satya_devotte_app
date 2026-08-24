import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/core/services/media_upload_service.dart';
import 'package:satya_devotte_app/core/utils/cms_search_scheduler.dart';
import 'package:satya_devotte_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:satya_devotte_app/features/cms/models/deity_model.dart';
import 'package:satya_devotte_app/features/cms/models/pooja_model.dart';
import 'package:satya_devotte_app/features/cms/presentation/controllers/deity_controller.dart';
import 'package:satya_devotte_app/features/cms/presentation/controllers/pooja_controller.dart';
import 'package:satya_devotte_app/features/cms/presentation/pages/cms_shell_page.dart';
import 'package:satya_devotte_app/features/cms/presentation/widgets/cms_rich_text_field.dart';
import 'package:satya_devotte_app/features/cms/presentation/widgets/cms_shared_widgets.dart';
import 'package:satya_devotte_app/features/cms/presentation/widgets/cms_upload_box.dart';
import 'package:satya_devotte_app/shared/widgets/rich_text_display.dart';

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

Widget _cmsClickableInk({
  required VoidCallback? onTap,
  required Widget child,
  BorderRadius? borderRadius,
}) {
  return MouseRegion(
    cursor: onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
    child: InkWell(onTap: onTap, borderRadius: borderRadius, child: child),
  );
}

const _cmsButtonClickCursor = WidgetStatePropertyAll<MouseCursor>(
  SystemMouseCursors.click,
);

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
  late final CmsSearchScheduler _searchScheduler;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchScheduler = CmsSearchScheduler(onSearch: _controller.setSearch);
    _controller.clearSearch();
    Future.microtask(_loadDeities);
  }

  @override
  void dispose() {
    _searchScheduler.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearchField() {
    _searchController.clear();
    _searchScheduler.cancelPending();
  }

  Future<void> _loadDeities({bool force = false}) async {
    final status = _filter == 'All' ? null : _filter.toUpperCase();
    await _controller.loadDeities(
      status: status,
      force: force,
    );
  }

  String _associatedPujasLabel(DeityModel deity) {
    if (deity.rituals.isEmpty && deity.ritualTitles.isEmpty) {
      return 'No associated pujas';
    }
    final names = <String>[];
    if (deity.rituals.isNotEmpty) {
      for (final id in deity.rituals) {
        final title = deity.ritualTitles[id]?.trim() ?? '';
        if (title.isNotEmpty) names.add(title);
      }
    }
    if (names.isEmpty) {
      names.addAll(
        deity.ritualTitles.values
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty),
      );
    }
    if (names.isEmpty) {
      final count = deity.rituals.length;
      return '$count associated puja${count == 1 ? '' : 's'}';
    }
    return names.join(', ');
  }


  Future<void> _save(Map<String, dynamic> payload, {PickedFile? image}) async {
    final ok = _editing != null
        ? await _controller.updateDeity(_editing!.id, payload, image: image)
        : await _controller.createDeity(payload, image: image);

    if (!ok) return;

    await _loadDeities(force: true);
    if (!mounted) return;
    setState(() {
      _showForm = false;
      _editing = null;
    });
  }

  Future<void> _openEdit(_DeityItem deity) async {
    if (Get.isRegistered<PoojaController>()) {
      Get.find<PoojaController>().fetchApprovedPoojasForSelector();
    }
    final full = await _controller.getDeityById(deity.id);
    if (!mounted) return;
    setState(() {
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
                    controller: _searchController,
                    onChanged: _searchScheduler.onQueryChanged,
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
                      : _cmsClickable(
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
                  onTap: () {
                    if (Get.isRegistered<PoojaController>()) {
                      Get.find<PoojaController>().fetchApprovedPoojasForSelector();
                    }
                    setState(() {
                      _editing = null;
                      _showForm = true;
                    });
                  },
                ),
              ],
            ),
          ),
          Container(
            color: CmsColors.white,
            padding: EdgeInsets.only(left: isWeb ? 24 : 16, bottom: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Obx(
                () => Row(
                children: filters.map((f) {
                  final sel = _filter == f;
                  return _cmsClickable(
                    onTap: () async {
                      _clearSearchField();
                      setState(() => _filter = f);
                      await _controller.setStatusFilter(
                        f == 'All' ? null : f.toUpperCase(),
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: sel ? CmsColors.orange : CmsColors.bg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: sel ? CmsColors.orange : CmsColors.border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            f,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color:
                                  sel ? const Color(0xFFFCF7EF) : CmsColors.textSecond,
                            ),
                          ),
                          if (f == 'Pending' && _controller.pendingCount > 0) ...[
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: sel
                                    ? Colors.white.withOpacity(0.85)
                                    : CmsColors.orange,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${_controller.pendingCount}',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: sel
                                      ? CmsColors.orange
                                      : const Color(0xFFFCF7EF),
                                ),
                              ),
                            ),
                          ],
                          if (f == 'Queued' && _controller.queuedCount > 0) ...[
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: sel
                                    ? Colors.white.withOpacity(0.85)
                                    : CmsColors.orange,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${_controller.queuedCount}',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: sel
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
          Expanded(
            child: Obx(() {
              if (_controller.isLoading && _controller.deities.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(color: CmsColors.orange),
                );
              }
              if (_controller.error != null && _controller.deities.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _controller.error!,
                        style: const TextStyle(
                          color: CmsColors.textSecond,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => _loadDeities(force: true),
                        style: TextButton.styleFrom().copyWith(
                          mouseCursor: _cmsButtonClickCursor,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }
              final list = _controller.deities;
              if (list.isEmpty) {
                final isSearch = _controller.search.isNotEmpty;
                return Center(
                  child: Text(
                    isSearch
                        ? 'No deities match your search.'
                        : 'No deities found.',
                    style: const TextStyle(
                      color: CmsColors.textSecond,
                    ),
                  ),
                );
              }
              return ListView.builder(
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
                          border: Border.all(color: CmsColors.border),
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
                                    d.name.trim().isNotEmpty ? d.name : 'Untitled deity',
                                    style: TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w600,
                                      color: CmsColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _associatedPujasLabel(d),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
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
                  );
            }),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(isWeb ? 24 : 16, 0, isWeb ? 24 : 16, 16),
            child: Obx(
              () => CmsPaginationBar(
                page: _controller.page,
                pageSize: _controller.limit,
                totalPages: _controller.totalPages,
                totalRows: _controller.total,
                isLoading: _controller.isLoading,
                onPageSelected: _controller.goToPage,
                onPageSizeChanged: _controller.setPageSize,
              ),
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
    return _cmsClickableInk(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
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
  String? _appearanceDescRich;
  late final TextEditingController _spiritualTitleCtrl;
  String? _spiritualDescRich;
  String? _connectingHowToPrayRich;
  late final TextEditingController _connectingWhatPleasesCtrl;
  late final TextEditingController _connectingDispleasesCtrl;
  String? _chantingMantraRich;
  late final TextEditingController _chantingRepetitionsCtrl;
  late final TextEditingController _chantingBenefitsCtrl;
  late final TextEditingController _chantingPreferredDaysCtrl;
  late final TextEditingController _chantingAssociatedColorsCtrl;
  late final TextEditingController _homePlacementCtrl;
  late final TextEditingController _homeOfferingsCtrl;
  late final TextEditingController _homeDoCtrl;
  late final TextEditingController _homeDontCtrl;
  String? _devotionalSignRich;
  String? _devotionalNotesRich;
  late final TextEditingController _storiesTitleCtrl;
  String? _storiesDescRich;
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
  final List<String> _associatedColors = <String>[];
  final List<String> _homeOfferings = <String>[];
  final List<String> _homeDos = <String>[];
  final List<String> _homeDonts = <String>[];
  final List<PoojaModel> _poojaOptions = <PoojaModel>[];
  bool _isLoadingPoojas = false;
  bool _showLineageFormsEditor = false;
  bool _showAppearanceEditor = false;
  bool _showSpiritualEditor = false;
  bool _showStoriesEditor = false;
  int? _editingLineageFormsIndex;
  int? _editingAppearanceIndex;
  int? _editingSpiritualIndex;
  int? _editingStoriesIndex;
  late final TextEditingController _lineageFormsTitleCtrl;
  String? _lineageFormsDescRich;
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
    _appearanceDescRich = null;
    _spiritualTitleCtrl = TextEditingController();
    _spiritualDescRich = null;
    _connectingHowToPrayRich = initial?.connectingHowToPray;
    _connectingWhatPleasesCtrl = TextEditingController();
    _connectingDispleasesCtrl = TextEditingController();
    _chantingMantraRich = initial?.chantingMantra;
    _chantingRepetitionsCtrl = TextEditingController(
      text: initial?.chantingRepetitions ?? '',
    );
    _chantingBenefitsCtrl = TextEditingController();
    _chantingPreferredDaysCtrl = TextEditingController(
      text: initial?.chantingPreferredDays.join(', ') ?? '',
    );
    _chantingAssociatedColorsCtrl = TextEditingController();
    _homePlacementCtrl = TextEditingController(
      text: initial?.homePlacement ?? '',
    );
    _homeOfferingsCtrl = TextEditingController();
    _homeDoCtrl = TextEditingController();
    _homeDontCtrl = TextEditingController();
    _devotionalSignRich = initial?.devotionalSignOfConnection;
    _devotionalNotesRich = initial?.devotionalNotes;
    _storiesTitleCtrl = TextEditingController();
    _storiesDescRich = null;
    _imageUrlsCtrl = TextEditingController(text: initial?.imageUrl ?? '');
    _lineageFormsTitleCtrl = TextEditingController();
    _lineageFormsDescRich = null;
    if (initial != null) {
      _alternateNames.addAll(initial.alternateNames);
      _roles.addAll(initial.roles);
      _ritualIds.addAll(initial.rituals);
      _appearanceEntries.addAll(initial.appearance);
      _spiritualEntries.addAll(initial.spiritualSignificance);
      _whatPleases.addAll(initial.connectingWhatPleases);
      _displeases.addAll(initial.connectingDispleases);
      _chantBenefits.addAll(initial.chantingBenefits);
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
    _spiritualTitleCtrl.dispose();
    _connectingWhatPleasesCtrl.dispose();
    _connectingDispleasesCtrl.dispose();
    _chantingRepetitionsCtrl.dispose();
    _chantingBenefitsCtrl.dispose();
    _chantingPreferredDaysCtrl.dispose();
    _chantingAssociatedColorsCtrl.dispose();
    _homePlacementCtrl.dispose();
    _homeOfferingsCtrl.dispose();
    _homeDoCtrl.dispose();
    _homeDontCtrl.dispose();
    _storiesTitleCtrl.dispose();
    _imageUrlsCtrl.dispose();
    _lineageFormsTitleCtrl.dispose();
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

  void _startEditChipText(
    TextEditingController ctrl,
    List<String> target,
    int index,
  ) {
    if (index < 0 || index >= target.length) return;
    final value = target[index];
    ctrl.text = value;
    ctrl.selection = TextSelection.collapsed(offset: value.length);
    setState(() => target.removeAt(index));
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

  Future<List<PoojaModel>> _loadRitualOptions({bool showError = false}) async {
    if (!Get.isRegistered<PoojaController>()) return List<PoojaModel>.from(_poojaOptions);
    final poojaController = Get.find<PoojaController>();
    setState(() => _isLoadingPoojas = true);
    try {
      final approved = await poojaController.fetchApprovedPoojasForSelector();
      if (!mounted) return approved;
      setState(() {
        _poojaOptions
          ..clear()
          ..addAll(approved);
        _isLoadingPoojas = false;
      });
      return approved;
    } catch (_) {
      if (!mounted) return List<PoojaModel>.from(_poojaOptions);
      setState(() => _isLoadingPoojas = false);
      if (showError) {
        showCmsSnackbar(
          title: 'Error',
          message: 'Failed to load approved pujas',
          isError: true,
        );
      }
      return List<PoojaModel>.from(_poojaOptions);
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
    required List<Map<String, String>> target,
    String? richDesc,
    ValueSetter<String?>? clearRichDesc,
    int? editingIndex,
    VoidCallback? onAdded,
  }) {
    final title = titleCtrl.text.trim();
    final description = richDesc ?? '';
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
      final entry = {'title': title, 'description': description};
      if (editingIndex != null) {
        target[editingIndex] = entry;
      } else {
        target.add(entry);
      }
      titleCtrl.clear();
      clearRichDesc?.call(null);
      onAdded?.call();
    });
  }

  void _startEditKeyValueEntry({
    required int index,
    required List<Map<String, String>> target,
    required TextEditingController titleCtrl,
    required ValueSetter<String?> setRichDesc,
    required void Function() onStarted,
  }) {
    if (index < 0 || index >= target.length) return;
    final entry = target[index];
    titleCtrl.text = entry['title'] ?? '';
    setRichDesc(entry['description'] ?? '');
    onStarted();
  }

  void _clearKeyValueEditorFields({
    required TextEditingController titleCtrl,
    required ValueSetter<String?> clearRichDesc,
    required void Function() onCleared,
  }) {
    titleCtrl.clear();
    clearRichDesc(null);
    onCleared();
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
          hint: 'Enter description...',
          controller: _descCtrl,
          maxLines: 4,
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
          onEdit: (index) => _startEditChipText(
            _alternateNamesCtrl,
            _alternateNames,
            index,
          ),
          onRemove: (index) => setState(() => _alternateNames.removeAt(index)),
        ),
        const SizedBox(height: 12),
        _ChipListEditor(
          label: 'Roles',
          hint: 'e.g. wisdom, prosperity',
          controller: _rolesCtrl,
          values: _roles,
          onAdd: () => _addChipValue(_rolesCtrl, _roles),
          onEdit: (index) => _startEditChipText(_rolesCtrl, _roles, index),
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
          isLoading: _isLoadingPoojas,
          onOpen: () async {
            final approved = await _loadRitualOptions(showError: true);
            return approved
                .map((p) => _MultiSelectOption(value: p.id, label: p.title))
                .toList();
          },
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
            style: TextStyle(fontSize: 12, color: CmsColors.textSecond),
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
      title: 'Family/ Divine association and Iconography',
      children: [
        _KeyValueEditor(
          heading: 'Family / Divine Associations / Seating / Iconography',
          showEditor: _showLineageFormsEditor,
          editingIndex: _editingLineageFormsIndex,
          onToggle: () => setState(() {
            if (_showLineageFormsEditor) {
              _clearKeyValueEditorFields(
                titleCtrl: _lineageFormsTitleCtrl,
                clearRichDesc: (v) => _lineageFormsDescRich = v,
                onCleared: () {
                  _editingLineageFormsIndex = null;
                  _showLineageFormsEditor = false;
                },
              );
            } else {
              _editingLineageFormsIndex = null;
              _showLineageFormsEditor = true;
            }
          }),
          titleCtrl: _lineageFormsTitleCtrl,
          richDescValue: _lineageFormsDescRich,
          onRichDescChanged: (v) => _lineageFormsDescRich = v,
          onAdd: () => _addKeyValueEntry(
            titleCtrl: _lineageFormsTitleCtrl,
            target: _lineageFormsEntries,
            richDesc: _lineageFormsDescRich,
            clearRichDesc: (v) => _lineageFormsDescRich = v,
            editingIndex: _editingLineageFormsIndex,
            onAdded: () => _editingLineageFormsIndex = null,
          ),
          entries: _lineageFormsEntries,
          onEdit: (index) => _startEditKeyValueEntry(
            index: index,
            target: _lineageFormsEntries,
            titleCtrl: _lineageFormsTitleCtrl,
            setRichDesc: (v) => _lineageFormsDescRich = v,
            onStarted: () => setState(() {
              _editingLineageFormsIndex = index;
              _showLineageFormsEditor = true;
            }),
          ),
          onRemove: (index) => setState(() {
            if (_editingLineageFormsIndex == index) {
              _clearKeyValueEditorFields(
                titleCtrl: _lineageFormsTitleCtrl,
                clearRichDesc: (v) => _lineageFormsDescRich = v,
                onCleared: () {
                  _editingLineageFormsIndex = null;
                  _showLineageFormsEditor = false;
                },
              );
            } else if (_editingLineageFormsIndex != null &&
                index < _editingLineageFormsIndex!) {
              _editingLineageFormsIndex = _editingLineageFormsIndex! - 1;
            }
            _lineageFormsEntries.removeAt(index);
          }),
        ),
      ],
    );
    final sectionsCard = CmsFormCard(
      title: 'Appearance & Symbolism',
      children: [
        _KeyValueEditor(
          heading: 'Appearance & Symbolism',
          showEditor: _showAppearanceEditor,
          editingIndex: _editingAppearanceIndex,
          onToggle: () => setState(() {
            if (_showAppearanceEditor) {
              _clearKeyValueEditorFields(
                titleCtrl: _appearanceTitleCtrl,
                clearRichDesc: (v) => _appearanceDescRich = v,
                onCleared: () {
                  _editingAppearanceIndex = null;
                  _showAppearanceEditor = false;
                },
              );
            } else {
              _editingAppearanceIndex = null;
              _showAppearanceEditor = true;
            }
          }),
          titleCtrl: _appearanceTitleCtrl,
          richDescValue: _appearanceDescRich,
          onRichDescChanged: (v) => _appearanceDescRich = v,
          onAdd: () => _addKeyValueEntry(
            titleCtrl: _appearanceTitleCtrl,
            target: _appearanceEntries,
            richDesc: _appearanceDescRich,
            clearRichDesc: (v) => _appearanceDescRich = v,
            editingIndex: _editingAppearanceIndex,
            onAdded: () => _editingAppearanceIndex = null,
          ),
          entries: _appearanceEntries,
          onEdit: (index) => _startEditKeyValueEntry(
            index: index,
            target: _appearanceEntries,
            titleCtrl: _appearanceTitleCtrl,
            setRichDesc: (v) => _appearanceDescRich = v,
            onStarted: () => setState(() {
              _editingAppearanceIndex = index;
              _showAppearanceEditor = true;
            }),
          ),
          onRemove: (index) => setState(() {
            if (_editingAppearanceIndex == index) {
              _clearKeyValueEditorFields(
                titleCtrl: _appearanceTitleCtrl,
                clearRichDesc: (v) => _appearanceDescRich = v,
                onCleared: () {
                  _editingAppearanceIndex = null;
                  _showAppearanceEditor = false;
                },
              );
            } else if (_editingAppearanceIndex != null &&
                index < _editingAppearanceIndex!) {
              _editingAppearanceIndex = _editingAppearanceIndex! - 1;
            }
            _appearanceEntries.removeAt(index);
          }),
        ),
      ],
    );
    final spiritualCard = CmsFormCard(
      title: 'Spiritual Significance',
      children: [
        _KeyValueEditor(
          heading: 'Spiritual Significance',
          showEditor: _showSpiritualEditor,
          editingIndex: _editingSpiritualIndex,
          onToggle: () => setState(() {
            if (_showSpiritualEditor) {
              _clearKeyValueEditorFields(
                titleCtrl: _spiritualTitleCtrl,
                clearRichDesc: (v) => _spiritualDescRich = v,
                onCleared: () {
                  _editingSpiritualIndex = null;
                  _showSpiritualEditor = false;
                },
              );
            } else {
              _editingSpiritualIndex = null;
              _showSpiritualEditor = true;
            }
          }),
          titleCtrl: _spiritualTitleCtrl,
          richDescValue: _spiritualDescRich,
          onRichDescChanged: (v) => _spiritualDescRich = v,
          onAdd: () => _addKeyValueEntry(
            titleCtrl: _spiritualTitleCtrl,
            target: _spiritualEntries,
            richDesc: _spiritualDescRich,
            clearRichDesc: (v) => _spiritualDescRich = v,
            editingIndex: _editingSpiritualIndex,
            onAdded: () => _editingSpiritualIndex = null,
          ),
          entries: _spiritualEntries,
          onEdit: (index) => _startEditKeyValueEntry(
            index: index,
            target: _spiritualEntries,
            titleCtrl: _spiritualTitleCtrl,
            setRichDesc: (v) => _spiritualDescRich = v,
            onStarted: () => setState(() {
              _editingSpiritualIndex = index;
              _showSpiritualEditor = true;
            }),
          ),
          onRemove: (index) => setState(() {
            if (_editingSpiritualIndex == index) {
              _clearKeyValueEditorFields(
                titleCtrl: _spiritualTitleCtrl,
                clearRichDesc: (v) => _spiritualDescRich = v,
                onCleared: () {
                  _editingSpiritualIndex = null;
                  _showSpiritualEditor = false;
                },
              );
            } else if (_editingSpiritualIndex != null &&
                index < _editingSpiritualIndex!) {
              _editingSpiritualIndex = _editingSpiritualIndex! - 1;
            }
            _spiritualEntries.removeAt(index);
          }),
        ),
      ],
    );
    final connectingCard = CmsFormCard(
      title: 'Connecting with Deity',
      children: [
        CmsRichTextField(
          label: 'How to Invoke / Call Upon This Deity',
          initialValue: _connectingHowToPrayRich,
          onChanged: (v) => setState(() => _connectingHowToPrayRich = v),
        ),
        const SizedBox(height: 12),
        _ChipListEditor(
          label: 'What Pleases / Appeases This Deity',
          hint: 'e.g. Sincerity, discipline, devotion',
          controller: _connectingWhatPleasesCtrl,
          values: _whatPleases,
          onAdd: () => _addChipValue(_connectingWhatPleasesCtrl, _whatPleases),
          onEdit: (index) => _startEditChipText(
            _connectingWhatPleasesCtrl,
            _whatPleases,
            index,
          ),
          onRemove: (index) => setState(() => _whatPleases.removeAt(index)),
        ),
        const SizedBox(height: 12),
        _ChipListEditor(
          label: 'What May Displease / Trigger This Deity',
          hint: 'e.g. Arrogance, disrespect',
          controller: _connectingDispleasesCtrl,
          values: _displeases,
          onAdd: () => _addChipValue(_connectingDispleasesCtrl, _displeases),
          onEdit: (index) => _startEditChipText(
            _connectingDispleasesCtrl,
            _displeases,
            index,
          ),
          onRemove: (index) => setState(() => _displeases.removeAt(index)),
        ),
      ],
    );
    final chantingCard = CmsFormCard(
      title: 'Prayer & Chanting',
      children: [
        CmsRichTextField(
          label: 'Recommended Mantra / Chant',
          initialValue: _chantingMantraRich,
          onChanged: (v) => setState(() => _chantingMantraRich = v),
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
          onEdit: (index) => _startEditChipText(
            _chantingBenefitsCtrl,
            _chantBenefits,
            index,
          ),
          onRemove: (index) => setState(() => _chantBenefits.removeAt(index)),
        ),
        const SizedBox(height: 12),
        CmsFormField(
          label: 'Preferred Days',
          hint: 'e.g. Full moon, Ekadashi, Morning',
          controller: _chantingPreferredDaysCtrl,
        ),
        const SizedBox(height: 12),
        _ChipListEditor(
          label: 'Associated Colors',
          hint: 'e.g. Green, Yellow',
          controller: _chantingAssociatedColorsCtrl,
          values: _associatedColors,
          onAdd: () =>
              _addChipValue(_chantingAssociatedColorsCtrl, _associatedColors),
          onEdit: (index) => _startEditChipText(
            _chantingAssociatedColorsCtrl,
            _associatedColors,
            index,
          ),
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
          onEdit: (index) => _startEditChipText(
            _homeOfferingsCtrl,
            _homeOfferings,
            index,
          ),
          onRemove: (index) => setState(() => _homeOfferings.removeAt(index)),
        ),
        const SizedBox(height: 12),
        _ChipListEditor(
          label: 'Do',
          hint: 'e.g. keep clean, light lamp',
          controller: _homeDoCtrl,
          values: _homeDos,
          onAdd: () => _addChipValue(_homeDoCtrl, _homeDos),
          onEdit: (index) => _startEditChipText(_homeDoCtrl, _homeDos, index),
          onRemove: (index) => setState(() => _homeDos.removeAt(index)),
        ),
        const SizedBox(height: 12),
        _ChipListEditor(
          label: 'Don\'t',
          hint: 'e.g. avoid clutter',
          controller: _homeDontCtrl,
          values: _homeDonts,
          onAdd: () => _addChipValue(_homeDontCtrl, _homeDonts),
          onEdit: (index) =>
              _startEditChipText(_homeDontCtrl, _homeDonts, index),
          onRemove: (index) => setState(() => _homeDonts.removeAt(index)),
        ),
      ],
    );
    final devotionalCard = CmsFormCard(
      title: 'Devotional Experience',
      children: [
        CmsRichTextField(
          label: 'Sign of Connection',
          initialValue: _devotionalSignRich,
          onChanged: (v) => setState(() => _devotionalSignRich = v),
        ),
        const SizedBox(height: 12),
        CmsRichTextField(
          label: 'Notes',
          initialValue: _devotionalNotesRich,
          onChanged: (v) => setState(() => _devotionalNotesRich = v),
        ),
      ],
    );
    final storiesCard = CmsFormCard(
      title: 'Stories',
      children: [
        _KeyValueEditor(
          heading: 'Stories',
          showEditor: _showStoriesEditor,
          editingIndex: _editingStoriesIndex,
          onToggle: () => setState(() {
            if (_showStoriesEditor) {
              _clearKeyValueEditorFields(
                titleCtrl: _storiesTitleCtrl,
                clearRichDesc: (v) => _storiesDescRich = v,
                onCleared: () {
                  _editingStoriesIndex = null;
                  _showStoriesEditor = false;
                },
              );
            } else {
              _editingStoriesIndex = null;
              _showStoriesEditor = true;
            }
          }),
          titleCtrl: _storiesTitleCtrl,
          richDescValue: _storiesDescRich,
          onRichDescChanged: (v) => _storiesDescRich = v,
          onAdd: () => _addKeyValueEntry(
            titleCtrl: _storiesTitleCtrl,
            target: _storiesEntries,
            richDesc: _storiesDescRich,
            clearRichDesc: (v) => _storiesDescRich = v,
            editingIndex: _editingStoriesIndex,
            onAdded: () => _editingStoriesIndex = null,
          ),
          entries: _storiesEntries,
          onEdit: (index) => _startEditKeyValueEntry(
            index: index,
            target: _storiesEntries,
            titleCtrl: _storiesTitleCtrl,
            setRichDesc: (v) => _storiesDescRich = v,
            onStarted: () => setState(() {
              _editingStoriesIndex = index;
              _showStoriesEditor = true;
            }),
          ),
          onRemove: (index) => setState(() {
            if (_editingStoriesIndex == index) {
              _clearKeyValueEditorFields(
                titleCtrl: _storiesTitleCtrl,
                clearRichDesc: (v) => _storiesDescRich = v,
                onCleared: () {
                  _editingStoriesIndex = null;
                  _showStoriesEditor = false;
                },
              );
            } else if (_editingStoriesIndex != null &&
                index < _editingStoriesIndex!) {
              _editingStoriesIndex = _editingStoriesIndex! - 1;
            }
            _storiesEntries.removeAt(index);
          }),
        ),
      ],
    );
    final mediaCard = CmsFormCard(
      title: 'Media',
      children: [
        CmsUploadBox(
          label: 'Thumbnail Image',
          icon: Icons.image_outlined,
          accept: '1920 × 1080 px, JPG, PNG up to 5MB',
          mediaType: PickMediaType.image,
          initialUrl: widget.initial?.imageUrl,
          onPicked: (file) => setState(() {
            _pickedImage = file;
            _imageUrlsCtrl.clear();
          }),
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
              _cmsClickable(
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
                  style: OutlinedButton.styleFrom().copyWith(
                    mouseCursor: _cmsButtonClickCursor,
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _submitDeity,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CmsColors.orange,
                    foregroundColor: Color(0xFFFCF7EF),
                    disabledBackgroundColor: CmsColors.orange.withOpacity(0.6),
                    disabledForegroundColor: Color(0xFFFCF7EF),
                  ).copyWith(mouseCursor: _cmsButtonClickCursor),
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Color(0xFFFCF7EF)),
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
      await widget.onSave({
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
          'how_to_pray': _connectingHowToPrayRich ?? '',
          'what_pleases': _valuesWithPending(
            _connectingWhatPleasesCtrl,
            _whatPleases,
          ),
          'displeases': _valuesWithPending(
            _connectingDispleasesCtrl,
            _displeases,
          ),
        },
        'chanting': {
          'mantra': _chantingMantraRich ?? '',
          'repetitions': _chantingRepetitionsCtrl.text.trim(),
          'benefits': _valuesWithPending(_chantingBenefitsCtrl, _chantBenefits),
          'preferred_days': _csv(_chantingPreferredDaysCtrl.text),
          'associated_colors': _valuesWithPending(
            _chantingAssociatedColorsCtrl,
            _associatedColors,
          ),
        },
        'home_practice': {
          'placement': _homePlacementCtrl.text.trim(),
          'offerings': _valuesWithPending(_homeOfferingsCtrl, _homeOfferings),
          'do_and_dont': {
            'do': _valuesWithPending(_homeDoCtrl, _homeDos),
            'dont': _valuesWithPending(_homeDontCtrl, _homeDonts),
          },
        },
        'devotional_experience': {
          'sign_of_connection': _devotionalSignRich ?? '',
          'notes': _devotionalNotesRich ?? '',
        },
        'stories': _storiesEntries,
        'pujas': List<String>.from(_ritualIds),
        'media': {'images': _csv(_imageUrlsCtrl.text)},
        'status': _status,
      }, image: _pickedImage);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _KeyValueEditor extends StatefulWidget {
  const _KeyValueEditor({
    required this.heading,
    required this.showEditor,
    required this.onToggle,
    required this.titleCtrl,
    this.descCtrl,
    this.richDescValue,
    this.onRichDescChanged,
    required this.onAdd,
    required this.entries,
    required this.onEdit,
    required this.onRemove,
    this.editingIndex,
  });

  final String heading;
  final bool showEditor;
  final VoidCallback onToggle;
  final TextEditingController titleCtrl;
  final TextEditingController? descCtrl;
  final String? richDescValue;
  final ValueChanged<String>? onRichDescChanged;
  final VoidCallback onAdd;
  final List<Map<String, String>> entries;
  final ValueChanged<int> onEdit;
  final ValueChanged<int> onRemove;
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
  Widget build(BuildContext context) {
    return Column(
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
            Tooltip(
              message: widget.showEditor ? 'Hide entry form' : 'Show entry form',
              child: _cmsClickable(
                onTap: widget.onToggle,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: CmsColors.bg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: CmsColors.border),
                  ),
                  child: Icon(
                    widget.showEditor
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
          widget.onRichDescChanged != null
              ? CmsRichTextField(
                  key: ValueKey(widget.richDescValue),
                  label: '${widget.heading} Description',
                  initialValue: widget.richDescValue,
                  onChanged: widget.onRichDescChanged!,
                )
              : CmsFormField(
                  label: '${widget.heading} Description',
                  hint: 'Enter description',
                  controller: widget.descCtrl!,
                  maxLines: 3,
                ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _handleAdd,
              style: ElevatedButton.styleFrom(
                backgroundColor: CmsColors.orange,
                foregroundColor: Color(0xFFFCF7EF),
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ).copyWith(mouseCursor: _cmsButtonClickCursor),
              child: Text(
                widget.editingIndex != null ? 'Update entry' : 'Add entry',
              ),
            ),
          ),
        ],
        if (widget.entries.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'No entries added yet',
              style: TextStyle(fontSize: 12, color: CmsColors.textSecond),
            ),
          )
        else ...[
          const SizedBox(height: 8),
          ...widget.entries.asMap().entries.map((entry) {
            final title = (entry.value['title'] ?? '').trim();
            final description = (entry.value['description'] ?? '').trim();
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: widget.editingIndex == entry.key
                    ? CmsColors.orange.withOpacity(0.08)
                    : CmsColors.bg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: widget.editingIndex == entry.key
                      ? CmsColors.orange.withOpacity(0.35)
                      : CmsColors.border,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (title.isNotEmpty)
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 12,
                              color: CmsThemeColors.inputText,
                              fontWeight: FontWeight.bold,
                              height: 1.4,
                            ),
                          ),
                        if (description.isNotEmpty)
                          RichTextDisplay(
                            description,
                            style: const TextStyle(
                              fontSize: 12,
                              color: CmsThemeColors.inputText,
                              height: 1.4,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _cmsClickable(
                    onTap: () => widget.onEdit(entry.key),
                    child: Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: widget.editingIndex == entry.key
                          ? CmsColors.orange
                          : CmsColors.textSecond,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _cmsClickable(
                    onTap: () => widget.onRemove(entry.key),
                    child: const Icon(
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
    required this.onEdit,
    required this.onRemove,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final List<String> values;
  final VoidCallback onAdd;
  final ValueChanged<int> onEdit;
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
              style: TextStyle(fontSize: 12, color: CmsColors.textSecond),
            ),
          )
        else ...[
          const SizedBox(height: 10),
          ...values.asMap().entries.map(
            (entry) => _LineChip(
              label: entry.value,
              onEdit: () => onEdit(entry.key),
              onRemove: () => onRemove(entry.key),
            ),
          ),
        ],
      ],
    );
  }
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
              controller: widget.ctrl,
              focusNode: _focus,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _handleAdd(),
              cursorColor: CmsColors.orange,
              style: const TextStyle(
                fontSize: 13,
                color: CmsThemeColors.inputText,
              ),
              decoration: InputDecoration(
                hintText: widget.hint,
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
        _cmsClickable(
          onTap: _handleAdd,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: CmsColors.orange,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.add, color: Color(0xFFFCF7EF), size: 18),
          ),
        ),
      ],
    );
  }
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
          if (onEdit != null) ...[
            const SizedBox(width: 8),
            _cmsClickable(
              onTap: onEdit!,
              child: const Icon(
                Icons.edit_outlined,
                size: 16,
                color: CmsColors.textSecond,
              ),
            ),
          ],
          const SizedBox(width: 8),
          _cmsClickable(
            onTap: onRemove,
            child: Icon(Icons.close, size: 16, color: CmsColors.textSecond),
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
    this.onOpen,
    this.isLoading = false,
  });

  final String fieldLabel;
  final String hintText;
  final List<_MultiSelectOption> options;
  final List<String> selectedValues;
  final ValueChanged<List<String>> onChanged;
  final Future<List<_MultiSelectOption>> Function()? onOpen;
  final bool isLoading;

  Future<void> _openModal(BuildContext context) async {
    var latestOptions = options;
    if (onOpen != null) {
      latestOptions = await onOpen!();
    }
    if (!context.mounted) return;
    final current = List<String>.from(selectedValues);
    final picked = await showDialog<List<String>>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _AssociatePujaModal(
        options: latestOptions,
        selectedValues: current,
        isLoading: latestOptions.isEmpty && isLoading,
      ),
    );
    if (picked != null) onChanged(picked);
  }

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
        _cmsClickableInk(
          onTap: isLoading ? null : () => _openModal(context),
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
                if (isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: CmsColors.orange,
                    ),
                  )
                else
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

class _AssociatePujaModal extends StatefulWidget {
  const _AssociatePujaModal({
    required this.options,
    required this.selectedValues,
    this.isLoading = false,
  });

  final List<_MultiSelectOption> options;
  final List<String> selectedValues;
  final bool isLoading;

  @override
  State<_AssociatePujaModal> createState() => _AssociatePujaModalState();
}

class _AssociatePujaModalState extends State<_AssociatePujaModal> {
  late final List<String> _selected;
  late final TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    _selected = List<String>.from(widget.selectedValues);
    _searchCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchCtrl.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? widget.options
        : widget.options
            .where((o) => o.label.toLowerCase().contains(query))
            .toList();

    return Dialog(
      backgroundColor: CmsColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: SizedBox(
        width: 520,
        height: MediaQuery.of(context).size.height * 0.7,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Associate Puja',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: CmsColors.textPrimary,
                      ),
                    ),
                  ),
                  _cmsClickable(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(
                      Icons.close,
                      size: 20,
                      color: CmsColors.textSecond,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.options.length} approved pujas',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: CmsColors.orange,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(
                  fontSize: 13,
                  color: CmsThemeColors.inputText,
                ),
                decoration: InputDecoration(
                  hintText: 'Search pujas...',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: CmsThemeColors.inputHint,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 18,
                    color: CmsColors.textSecond,
                  ),
                  filled: true,
                  fillColor: CmsColors.bg,
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
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: CmsColors.orange),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: widget.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: CmsColors.orange),
                      )
                    : filtered.isEmpty
                    ? Center(
                        child: Text(
                          widget.options.isEmpty
                              ? 'No approved pujas found'
                              : 'No matching pujas',
                          style: const TextStyle(
                            fontSize: 13,
                            color: CmsColors.textSecond,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final option = filtered[index];
                          final checked = _selected.contains(option.value);
                          return CheckboxListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            value: checked,
                            activeColor: CmsColors.orange,
                            title: Text(
                              option.label,
                              style: const TextStyle(
                                fontSize: 14,
                                color: CmsThemeColors.inputText,
                              ),
                            ),
                            onChanged: (v) {
                              setState(() {
                                if (v == true) {
                                  if (!_selected.contains(option.value)) {
                                    _selected.add(option.value);
                                  }
                                } else {
                                  _selected.remove(option.value);
                                }
                              });
                            },
                          );
                        },
                      ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom().copyWith(
                      mouseCursor: _cmsButtonClickCursor,
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  CmsPrimaryButton(
                    label: 'Done',
                    onTap: () => Navigator.of(context).pop(_selected),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
          _cmsClickable(
            onTap: onRemove,
            child: Icon(Icons.close, size: 14, color: CmsColors.textSecond),
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
  const _DeityColorField({required this.value, required this.onChanged});

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
        _cmsClickable(
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
                  _cmsClickable(
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
                return _cmsClickable(
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
          style: TextButton.styleFrom().copyWith(
            mouseCursor: _cmsButtonClickCursor,
          ),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_selected),
          style: ElevatedButton.styleFrom(
            backgroundColor: CmsColors.orange,
            foregroundColor: Color(0xFFFCF7EF),
            elevation: 0,
          ).copyWith(mouseCursor: _cmsButtonClickCursor),
          child: const Text('Select'),
        ),
      ],
    );
  }
}

typedef _DeityItem = DeityModel;
