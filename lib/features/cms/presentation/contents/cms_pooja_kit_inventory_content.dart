// Pooja Kit → Manage Inventory (Ecommerce).
// APIs: Flutter-Manageinventory.plan — GET/POST/PATCH/DELETE /inventory,
// GET /inventory/categories, POST .../adjust-stock.

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:satya_devotte_app/core/services/media_upload_service.dart';
import 'package:satya_devotte_app/features/cms/data/models/inventory_models.dart';
import 'package:satya_devotte_app/features/cms/presentation/controllers/inventory_controller.dart';
import 'package:satya_devotte_app/features/cms/presentation/pages/cms_shell_page.dart';
import 'package:satya_devotte_app/features/cms/presentation/widgets/cms_shared_widgets.dart';
import 'package:satya_devotte_app/features/cms/presentation/widgets/cms_upload_box.dart';

class CmsPoojaKitInventoryContent extends StatefulWidget {
  const CmsPoojaKitInventoryContent({super.key});

  @override
  State<CmsPoojaKitInventoryContent> createState() =>
      _CmsPoojaKitInventoryContentState();
}

class _CmsPoojaKitInventoryContentState extends State<CmsPoojaKitInventoryContent> {
  late final InventoryController _ctrl;
  InventoryItem? _editing;
  bool _showForm = false;
  bool _loadingDetail = false;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<InventoryController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _ctrl.init();
    });
  }

  void _openCreate() => setState(() {
        _editing = null;
        _showForm = true;
      });

  Future<void> _openEdit(InventoryItem item) async {
    setState(() => _loadingDetail = true);
    final fresh = await _ctrl.fetchItem(item.id);
    if (!mounted) return;
    setState(() {
      _loadingDetail = false;
      _editing = fresh ?? item;
      _showForm = true;
    });
  }

  void _closeForm() => setState(() {
        _showForm = false;
        _editing = null;
      });

  @override
  Widget build(BuildContext context) {
    if (_loadingDetail) {
      return const Center(
        child: CircularProgressIndicator(color: CmsColors.orange),
      );
    }
    if (_showForm) {
      return _InventoryForm(
        ctrl: _ctrl,
        item: _editing,
        onCancel: _closeForm,
        onSaved: _closeForm,
      );
    }
    return _InventoryListView(
      ctrl: _ctrl,
      onAdd: _openCreate,
      onEdit: _openEdit,
    );
  }
}

// ════════════════════════════════════════════════════════════════
// LIST
// ════════════════════════════════════════════════════════════════
class _InventoryListView extends StatelessWidget {
  const _InventoryListView({
    required this.ctrl,
    required this.onAdd,
    required this.onEdit,
  });

  final InventoryController ctrl;
  final VoidCallback onAdd;
  final ValueChanged<InventoryItem> onEdit;

  static const _stockFilters = ['All', 'In stock', 'Low stock', 'Out of stock'];
  static const _statusFilters = ['ALL', 'ACTIVE', 'INACTIVE'];

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 768;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  'Manage Inventory',
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
                  hint: 'Search name or description…',
                  onChanged: ctrl.setSearch,
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
                        onTap: ctrl.refresh,
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
                label: isTablet ? '+ Add item' : 'Add',
                onTap: onAdd,
              ),
            ],
          ),
        ),
        Obx(
          () {
            // Subscribe to all filter/category observables used in this strip.
            final _ = ctrl.categories.length;
            ctrl.categoryFilters.length;
            final categoryFiltersSnapshot =
                List<String>.from(ctrl.categoryFilters);
            return _FilterStrip(
              ctrl: ctrl,
              categoryFilters: categoryFiltersSnapshot,
              statusFilter: ctrl.statusFilter,
              stockFilter: ctrl.stockFilter,
              onCategory: ctrl.setCategoryFilters,
              onStatus: ctrl.setStatusFilter,
              onStock: ctrl.setStockFilter,
            );
          },
        ),
        const Divider(height: 1, color: CmsColors.border),
        Expanded(child: _InventoryBody(ctrl: ctrl, onEdit: onEdit)),
        Obx(() {
          if (ctrl.total == 0 && ctrl.items.isEmpty) {
            return const SizedBox.shrink();
          }
          return Material(
            color: CmsColors.white,
            child: Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: CmsColors.border)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                minimum: const EdgeInsets.only(bottom: 4),
                child: _InventoryPaginationBar(controller: ctrl),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _FilterStrip extends StatelessWidget {
  const _FilterStrip({
    required this.ctrl,
    required this.categoryFilters,
    required this.statusFilter,
    required this.stockFilter,
    required this.onCategory,
    required this.onStatus,
    required this.onStock,
  });

  final InventoryController ctrl;
  final List<String> categoryFilters;
  final String statusFilter;
  final String stockFilter;
  final ValueChanged<List<String>> onCategory;
  final ValueChanged<String> onStatus;
  final ValueChanged<String> onStock;

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 768;
    return Padding(
      padding: EdgeInsets.only(
        top: 12,
        bottom: 12,
        left: isTablet ? 24 : 16,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final s in _InventoryListView._statusFilters) ...[
                _FilterChip(
                  label: s == 'ALL'
                      ? 'All status'
                      : s[0] + s.substring(1).toLowerCase(),
                  selected: statusFilter == s,
                  onTap: () => onStatus(s),
                ),
                const SizedBox(width: 6),
              ],
              for (final f in _InventoryListView._stockFilters) ...[
                _FilterChip(
                  label: f,
                  selected: stockFilter == f,
                  onTap: () => onStock(f),
                ),
                const SizedBox(width: 6),
              ],
              _CategoryFilterButton(
                ctrl: ctrl,
                categoryFilters: categoryFilters,
                onApply: onCategory,
              ),
              const SizedBox(width: 6),
              Opacity(
                opacity: categoryFilters.isNotEmpty ? 1 : 0.55,
                child: TextButton.icon(
                  onPressed: categoryFilters.isNotEmpty
                      ? () => onCategory(const <String>[])
                      : null,
                  icon: const Icon(
                    Icons.clear_rounded,
                    size: 14,
                    color: CmsColors.red,
                  ),
                  label: const Text(
                    'Clear filters',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: CmsColors.red,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: CmsColors.red,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? CmsColors.orange : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? CmsColors.orange : CmsColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : CmsColors.orangeDark,
          ),
        ),
      ),
    );
  }
}

/// Opens a category dropdown with Apply / Cancel (does not filter until Apply).
class _CategoryFilterButton extends StatelessWidget {
  const _CategoryFilterButton({
    required this.ctrl,
    required this.categoryFilters,
    required this.onApply,
  });

  final InventoryController ctrl;
  final List<String> categoryFilters;
  final ValueChanged<List<String>> onApply;

  String _labelFor(String code) {
    if (code == 'ALL') return 'All categories';
    for (final c in ctrl.categories) {
      if (c.code == code) return c.label;
    }
    return code;
  }

  Future<void> _openFilter(BuildContext context) async {
    await ctrl.loadCategories();
    if (!context.mounted) return;
    final applied = await showDialog<List<String>>(
      context: context,
      builder: (ctx) => _CategoryFilterDialog(
        categories: ctrl.categories,
        initialCodes: categoryFilters,
      ),
    );
    if (applied != null) onApply(applied);
  }

  @override
  Widget build(BuildContext context) {
    final selected = categoryFilters
        .where((e) => e.trim().isNotEmpty && e.toUpperCase() != 'ALL')
        .toList(growable: false);
    final isActive = selected.isNotEmpty;
    final label = !isActive
        ? 'Category'
        : selected.length == 1
            ? _labelFor(selected.first)
            : '${selected.length} categories selected';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openFilter(context),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isActive
                ? CmsColors.orange.withOpacity(0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive ? CmsColors.orange : CmsColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.filter_list_rounded,
                size: 14,
                color: isActive ? CmsColors.orange : CmsColors.textSecond,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isActive ? CmsColors.orangeDark : CmsColors.textPrimary,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: isActive ? CmsColors.orange : CmsColors.textSecond,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryFilterDialog extends StatefulWidget {
  const _CategoryFilterDialog({
    required this.categories,
    required this.initialCodes,
  });

  final List<InventoryCategory> categories;
  final List<String> initialCodes;

  @override
  State<_CategoryFilterDialog> createState() => _CategoryFilterDialogState();
}

class _CategoryFilterDialogState extends State<_CategoryFilterDialog> {
  late Set<String> _draft;
  late final TextEditingController _searchCtrl;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _draft = widget.initialCodes
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && e.toUpperCase() != 'ALL')
        .toSet();
    _searchCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool get _showAllOption {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return 'all categories'.contains(q);
  }

  List<InventoryCategory> get _filteredCategories {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.categories;
    return widget.categories.where((c) {
      return c.label.toLowerCase().contains(q) ||
          c.code.toLowerCase().contains(q);
    }).toList();
  }

  int get _listItemCount {
    var n = _filteredCategories.length;
    if (_showAllOption) n += 1;
    return n;
  }

  String _codeAt(int index) {
    if (_showAllOption) {
      if (index == 0) return 'ALL';
      return _filteredCategories[index - 1].code;
    }
    return _filteredCategories[index].code;
  }

  String _labelAt(int index) {
    if (_showAllOption) {
      if (index == 0) return 'All categories';
      return _filteredCategories[index - 1].label;
    }
    return _filteredCategories[index].label;
  }

  String? _subtitleAt(int index) {
    if (_showAllOption && index == 0) return null;
    final cat = _showAllOption
        ? _filteredCategories[index - 1]
        : _filteredCategories[index];
    return cat.code;
  }

  @override
  Widget build(BuildContext context) {
    final empty = _listItemCount == 0;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Filter by category',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: CmsColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search categories…',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: CmsColors.bg,
                  isDense: true,
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
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: empty
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No categories match your search.',
                        style: TextStyle(
                          fontSize: 13,
                          color: CmsColors.textSecond,
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: _listItemCount,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final code = _codeAt(index);
                        final isSelected = code == 'ALL'
                            ? _draft.isEmpty
                            : _draft.contains(code);
                        final subtitle = _subtitleAt(index);
                        return InkWell(
                          onTap: () {
                            setState(() {
                              if (code == 'ALL') {
                                _draft.clear();
                                return;
                              }
                              if (_draft.contains(code)) {
                                _draft.remove(code);
                              } else {
                                _draft.add(code);
                              }
                            });
                          },
                          child: Container(
                            color: isSelected
                                ? CmsColors.orange.withOpacity(0.06)
                                : null,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _labelAt(index),
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected
                                              ? CmsColors.orange
                                              : CmsColors.textPrimary,
                                        ),
                                      ),
                                      if (subtitle != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          subtitle,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: CmsColors.textSecond,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle,
                                    size: 18,
                                    color: CmsColors.orange,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () =>
                        Navigator.pop(context, _draft.toList(growable: false)),
                    style: FilledButton.styleFrom(
                      backgroundColor: CmsColors.orange,
                    ),
                    child: const Text('Apply'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryBody extends StatelessWidget {
  const _InventoryBody({required this.ctrl, required this.onEdit});
  final InventoryController ctrl;
  final ValueChanged<InventoryItem> onEdit;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (ctrl.isLoading && ctrl.items.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(color: CmsColors.orange),
        );
      }
      if (ctrl.error != null && ctrl.items.isEmpty) {
        return _ErrorBox(message: ctrl.error!, onRetry: ctrl.refresh);
      }
      if (!ctrl.isLoading && ctrl.items.isEmpty) {
        return const CmsEmptyState(
          icon: Icons.warehouse_outlined,
          title: 'No inventory items',
          subtitle:
              'Add warehouse stock items here. They can be used as components '
              'when building Puja Kits.',
        );
      }
      return RefreshIndicator(
        color: CmsColors.orange,
        onRefresh: ctrl.refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width >= 768 ? 24 : 16,
            vertical: 16,
          ),
          child: _InventoryTable(
            ctrl: ctrl,
            items: ctrl.items,
            onEdit: onEdit,
            onAdjust: (item) => _showAdjustStockDialog(context, ctrl, item),
            onDelete: (item) => _confirmDelete(context, ctrl, item),
          ),
        ),
      );
    });
  }

  static Future<void> _showAdjustStockDialog(
    BuildContext context,
    InventoryController ctrl,
    InventoryItem item,
  ) async {
    var delta = 0;
    final reasonCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text('Adjust stock — ${item.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current: ${item.stockQuantity} in stock '
                '(${item.itemSizeLabel} each)\n'
                'Total: ${item.totalAvailableLabel}',
                style: const TextStyle(
                  fontSize: 12,
                  color: CmsColors.textSecond,
                ),
              ),
              if (delta != 0) ...[
                const SizedBox(height: 8),
                Text(
                  'After: ${item.stockQuantity + delta} in stock → '
                  '${_fmtQty((item.stockQuantity + delta) * item.itemQuantity)} '
                  '${item.unit} total',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: CmsColors.orangeDark,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filled(
                    onPressed: () => setLocal(() => delta -= 1),
                    icon: const Icon(Icons.remove),
                    style: IconButton.styleFrom(
                      backgroundColor: CmsColors.bg,
                      foregroundColor: CmsColors.textPrimary,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      delta >= 0 ? '+$delta' : '$delta',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: CmsColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton.filled(
                    onPressed: () => setLocal(() => delta += 1),
                    icon: const Icon(Icons.add),
                    style: IconButton.styleFrom(
                      backgroundColor: CmsColors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: reasonCtrl,
                decoration: const InputDecoration(
                  labelText: 'Reason (optional)',
                  hintText: 'e.g. delivery, stocktake',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: delta == 0 ? null : () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: CmsColors.orange),
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) {
      reasonCtrl.dispose();
      return;
    }
    if (delta == 0) {
      reasonCtrl.dispose();
      return;
    }
    final reason = reasonCtrl.text.trim();
    reasonCtrl.dispose();
    await ctrl.adjustStock(
      item.id,
      delta: delta,
      reason: reason.isEmpty ? null : reason,
    );
  }

  static Future<void> _confirmDelete(
    BuildContext context,
    InventoryController ctrl,
    InventoryItem item,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete inventory item?'),
        content: Text(
          '“${item.name}” will be soft-deleted (marked inactive).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: CmsColors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) await ctrl.deleteItem(item.id);
  }
}

/// Fixed column widths so headers and cells stay aligned (see Orders table).
const _kColGap = 12.0;

const _kInventoryTableColumns = <_InvColSpec>[
  _InvColSpec('', 44),
  _InvColSpec('Item', 172),
  _InvColSpec('Category', 132),
  _InvColSpec('Item size', 96),
  _InvColSpec('Price', 84),
  _InvColSpec('Stock', 56, align: TextAlign.right),
  _InvColSpec('Level', 112),
  _InvColSpec('Status', 108),
  _InvColSpec('', 40),
];

class _InventoryTable extends StatelessWidget {
  const _InventoryTable({
    required this.ctrl,
    required this.items,
    required this.onEdit,
    required this.onAdjust,
    required this.onDelete,
  });

  final InventoryController ctrl;
  final List<InventoryItem> items;
  final ValueChanged<InventoryItem> onEdit;
  final ValueChanged<InventoryItem> onAdjust;
  final ValueChanged<InventoryItem> onDelete;

  static double get _minTableWidth {
    final cols = _kInventoryTableColumns.fold(0.0, (w, c) => w + c.width);
    final gaps = _kColGap * (_kInventoryTableColumns.length - 1);
    return cols + gaps + 32;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final parentW = constraints.maxWidth;
        final tableWidth = parentW.isFinite && parentW > _minTableWidth
            ? parentW
            : _minTableWidth;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            child: Container(
              decoration: BoxDecoration(
                color: CmsColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: CmsColors.border),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  children: [
                    const _InventoryTableHeader(),
                    const Divider(height: 1, color: CmsColors.border),
                    for (var i = 0; i < items.length; i++) ...[
                      if (i != 0)
                        const Divider(height: 1, color: CmsColors.border),
                      _InventoryRow(
                        ctrl: ctrl,
                        item: items[i],
                        isStriped: i.isOdd,
                        isSubmitting: ctrl.isSubmitting,
                        onEdit: () => onEdit(items[i]),
                        onAdjust: () => onAdjust(items[i]),
                        onDelete: () => onDelete(items[i]),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _InventoryRow extends StatelessWidget {
  const _InventoryRow({
    required this.ctrl,
    required this.item,
    required this.isStriped,
    required this.isSubmitting,
    required this.onEdit,
    required this.onAdjust,
    required this.onDelete,
  });

  final InventoryController ctrl;
  final InventoryItem item;
  final bool isStriped;
  final bool isSubmitting;
  final VoidCallback onEdit;
  final VoidCallback onAdjust;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final level = _stockLevelStyle(item);
    return Container(
      color: isStriped ? const Color(0xFFFCFCFD) : CmsColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: _inventoryRowCells(
          level: level,
          item: item,
          ctrl: ctrl,
          isSubmitting: isSubmitting,
          onEdit: onEdit,
          onAdjust: onAdjust,
          onDelete: onDelete,
        ),
      ),
    );
  }
}

List<Widget> _inventoryRowCells({
  required _StockLevelStyle level,
  required InventoryItem item,
  required InventoryController ctrl,
  required bool isSubmitting,
  required VoidCallback onEdit,
  required VoidCallback onAdjust,
  required VoidCallback onDelete,
}) {
  final c = _kInventoryTableColumns;
  return [
    _InvCell(
      width: c[0].width,
      child: _InventoryItemThumb(imageUrl: item.imageUrl),
    ),
    _InvCell(
      width: c[1].width,
      child: Text(
        item.name,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: CmsColors.textPrimary,
        ),
      ),
    ),
    _InvCell(
      width: c[2].width,
      child: Text(
        ctrl.categoryLabel(item.category),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12, color: CmsColors.textSecond),
      ),
    ),
    _InvCell(
      width: c[3].width,
      child: Text(
        item.itemSizeLabel,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12, color: CmsColors.textPrimary),
      ),
    ),
    _InvCell(
      width: c[4].width,
      child: _InventoryPriceCell(item: item),
    ),
    _InvCell(
      width: c[5].width,
      align: Alignment.centerRight,
      child: Text(
        '${item.stockQuantity}',
        textAlign: TextAlign.right,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: level.color,
        ),
      ),
    ),
    _InvCell(
      width: c[6].width,
      child: _StockPill(label: item.stockLevelLabel, color: level.color),
    ),
    _InvCell(
      width: c[7].width,
      child: Obx(
        () => _InventoryStatusSwitch(
          isActive: item.isActive,
          pending: ctrl.isStatusPending(item.id),
          onChanged: (active) =>
              ctrl.setItemStatus(id: item.id, active: active),
        ),
      ),
    ),
    _InvCell(
      width: c[8].width,
      gapAfter: false,
      align: Alignment.centerRight,
      child: _InventoryRowMenu(
        isSubmitting: isSubmitting,
        onEdit: onEdit,
        onAdjust: onAdjust,
        onDelete: onDelete,
      ),
    ),
  ];
}

class _StockLevelStyle {
  const _StockLevelStyle(this.color);
  final Color color;
}

_StockLevelStyle _stockLevelStyle(InventoryItem item) {
  if (item.isOutOfStock) {
    return const _StockLevelStyle(Color(0xFFC62828));
  }
  if (item.isLowStock) {
    return const _StockLevelStyle(Color(0xFFEF6C00));
  }
  return const _StockLevelStyle(Color(0xFF2E7D32));
}

String _fmtQty(num v) {
  if (v == v.roundToDouble()) return v.toInt().toString();
  return v.toStringAsFixed(2);
}

String _money(num amount, String currency) {
  final sym = currency == 'ZAR' ? 'R' : currency;
  final n = amount == amount.roundToDouble()
      ? amount.toInt().toString()
      : amount.toStringAsFixed(2);
  return '$sym $n';
}

class _InventoryPriceCell extends StatelessWidget {
  const _InventoryPriceCell({required this.item});
  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    final price = item.price;
    final sale = item.salePrice;
    final effective = item.resolvedEffectivePrice;
    final hasSale = sale != null && sale < price;

    if (!hasSale) {
      return Text(
        _money(effective, item.currency),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: CmsColors.textPrimary,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _money(effective, item.currency),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2E7D32),
          ),
        ),
        Text(
          _money(price, item.currency),
          style: const TextStyle(
            fontSize: 10,
            color: CmsColors.textSecond,
            decoration: TextDecoration.lineThrough,
          ),
        ),
      ],
    );
  }
}

class _InventoryRowMenu extends StatelessWidget {
  const _InventoryRowMenu({
    required this.isSubmitting,
    required this.onEdit,
    required this.onAdjust,
    required this.onDelete,
  });

  final bool isSubmitting;
  final VoidCallback onEdit;
  final VoidCallback onAdjust;
  final VoidCallback onDelete;

  static const _menuWidth = 152.0;

  Future<void> _openMenu(BuildContext context) async {
    final box = context.findRenderObject()! as RenderBox;
    final origin = box.localToGlobal(Offset.zero);
    final selected = await showMenu<String>(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 8,
      position: RelativeRect.fromLTRB(
        origin.dx + box.size.width - _menuWidth,
        origin.dy + box.size.height + 4,
        origin.dx + box.size.width,
        origin.dy + box.size.height + 4,
      ),
      items: const [
        PopupMenuItem(value: 'edit', child: Text('Edit')),
        PopupMenuItem(value: 'adjust', child: Text('Adjust stock')),
        PopupMenuItem(
          value: 'delete',
          child: Text('Delete', style: TextStyle(color: CmsColors.red)),
        ),
      ],
    );
    if (!context.mounted) return;
    switch (selected) {
      case 'edit':
        onEdit();
      case 'adjust':
        onAdjust();
      case 'delete':
        onDelete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Actions',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      onPressed: isSubmitting ? null : () => _openMenu(context),
      icon: const Icon(Icons.more_vert, size: 20, color: CmsColors.textSecond),
    );
  }
}

class _InventoryItemThumb extends StatelessWidget {
  const _InventoryItemThumb({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: url != null && url.isNotEmpty
          ? Image.network(
              url,
              width: 36,
              height: 36,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder(),
            )
          : _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 36,
      height: 36,
      color: CmsColors.bg,
      alignment: Alignment.center,
      child: const Icon(
        Icons.inventory_2_outlined,
        size: 18,
        color: CmsColors.textSecond,
      ),
    );
  }
}

class _InventoryStatusSwitch extends StatelessWidget {
  const _InventoryStatusSwitch({
    required this.isActive,
    required this.pending,
    required this.onChanged,
  });

  final bool isActive;
  final bool pending;
  final Future<bool> Function(bool active) onChanged;

  @override
  Widget build(BuildContext context) {
    final color =
        isActive ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (pending)
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: color),
          )
        else
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: isActive,
              onChanged: pending ? null : (v) => onChanged(v),
              activeThumbColor: Colors.white,
              activeTrackColor: const Color(0xFF2E7D32),
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: const Color(0xFFC62828).withValues(alpha: 0.45),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            isActive ? 'Active' : 'Inactive',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _StockPill extends StatelessWidget {
  const _StockPill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 108),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _InventoryTableHeader extends StatelessWidget {
  const _InventoryTableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      color: const Color(0xFFF7F8FA),
      child: Row(
        children: [
          for (var i = 0; i < _kInventoryTableColumns.length; i++)
            _InvCell(
              width: _kInventoryTableColumns[i].width,
              gapAfter: i < _kInventoryTableColumns.length - 1,
              align: _kInventoryTableColumns[i].align == TextAlign.right
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Text(
                _kInventoryTableColumns[i].label,
                textAlign: _kInventoryTableColumns[i].align,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: CmsColors.textSecond,
                  letterSpacing: 0.2,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InvCell extends StatelessWidget {
  const _InvCell({
    required this.width,
    required this.child,
    this.align = Alignment.centerLeft,
    this.gapAfter = true,
  });

  final double width;
  final Widget child;
  final Alignment align;
  final bool gapAfter;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: width,
          child: ClipRect(
            child: Align(alignment: align, child: child),
          ),
        ),
        if (gapAfter) const SizedBox(width: _kColGap),
      ],
    );
  }
}

class _InvColSpec {
  const _InvColSpec(
    this.label,
    this.width, {
    this.align = TextAlign.left,
  });
  final String label;
  final double width;
  final TextAlign align;
}

// ════════════════════════════════════════════════════════════════
// CREATE / EDIT FORM
// ════════════════════════════════════════════════════════════════
class _InventoryForm extends StatefulWidget {
  const _InventoryForm({
    required this.ctrl,
    required this.item,
    required this.onCancel,
    required this.onSaved,
  });

  final InventoryController ctrl;
  final InventoryItem? item;
  final VoidCallback onCancel;
  final VoidCallback onSaved;

  @override
  State<_InventoryForm> createState() => _InventoryFormState();
}

class _InventoryFormState extends State<_InventoryForm> {
  static const _currency = 'ZAR';

  late final TextEditingController _nameCtrl;
  late final TextEditingController _unitCtrl;
  late final TextEditingController _itemQtyCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _thresholdCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _salePriceCtrl;
  late final TextEditingController _descCtrl;
  late String _category;
  late String _status;
  PickedFile? _image;

  bool get _isEdit => widget.item != null;

  @override
  void initState() {
    super.initState();
    final p = widget.item;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _unitCtrl = TextEditingController(text: p?.unit ?? 'grams');
    _itemQtyCtrl = TextEditingController(
      text: p == null ? '' : p.itemQuantity.toString(),
    );
    _stockCtrl = TextEditingController(text: '${p?.stockQuantity ?? 0}');
    _thresholdCtrl =
        TextEditingController(text: '${p?.lowStockThreshold ?? 10}');
    _priceCtrl = TextEditingController(
      text: p == null ? '' : p.price.toString(),
    );
    _salePriceCtrl = TextEditingController(
      text: p?.salePrice == null ? '' : p!.salePrice.toString(),
    );
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _category = p?.category ?? '';
    _status = p?.status ?? 'ACTIVE';

    _itemQtyCtrl.addListener(_onStockFieldsChanged);
    _stockCtrl.addListener(_onStockFieldsChanged);
    _unitCtrl.addListener(_onStockFieldsChanged);
  }

  void _onStockFieldsChanged() {
    if (mounted) setState(() {});
  }

  String? get _stockPreview {
    final itemQty = num.tryParse(_itemQtyCtrl.text.trim());
    final stock = int.tryParse(_stockCtrl.text.trim());
    final unit = _unitCtrl.text.trim();
    if (itemQty == null || itemQty <= 0 || stock == null || stock < 0) {
      return null;
    }
    if (unit.isEmpty) return null;
    final total = stock * itemQty;
    final size = itemQty == itemQty.roundToDouble()
        ? itemQty.toInt().toString()
        : itemQty.toStringAsFixed(2);
    final totalStr = total == total.roundToDouble()
        ? total.toInt().toString()
        : total.toStringAsFixed(2);
    return '$stock × $size $unit = $totalStr $unit available';
  }

  @override
  void dispose() {
    _itemQtyCtrl.removeListener(_onStockFieldsChanged);
    _stockCtrl.removeListener(_onStockFieldsChanged);
    _unitCtrl.removeListener(_onStockFieldsChanged);
    _nameCtrl.dispose();
    _unitCtrl.dispose();
    _itemQtyCtrl.dispose();
    _stockCtrl.dispose();
    _thresholdCtrl.dispose();
    _priceCtrl.dispose();
    _salePriceCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.length < 2) {
      showCmsSnackbar(
        title: 'Name required',
        message: 'Enter at least 2 characters.',
        isError: true,
      );
      return;
    }
    if (_category.isEmpty) {
      showCmsSnackbar(
        title: 'Category required',
        message: 'Select a category.',
        isError: true,
      );
      return;
    }
    final unit = _unitCtrl.text.trim();
    if (unit.isEmpty) {
      showCmsSnackbar(
        title: 'Unit required',
        message: 'e.g. grams, pieces, ml',
        isError: true,
      );
      return;
    }
    final itemQtyText = _itemQtyCtrl.text.trim();
    final itemQty = num.tryParse(itemQtyText);
    if (itemQty == null || itemQty <= 0) {
      showCmsSnackbar(
        title: 'Item quantity required',
        message:
            'Enter the size of one unit (e.g. 50 for 50 grams of turmeric powder).',
        isError: true,
      );
      return;
    }
    final priceText = _priceCtrl.text.trim();
    if (priceText.isEmpty) {
      showCmsSnackbar(
        title: 'Price required',
        message: 'Enter MRP per stock unit.',
        isError: true,
      );
      return;
    }
    final price = num.tryParse(priceText);
    if (price == null || price < 0) {
      showCmsSnackbar(
        title: 'Invalid price',
        message: 'Price must be zero or greater.',
        isError: true,
      );
      return;
    }
    final salePriceText = _salePriceCtrl.text.trim();
    final salePrice =
        salePriceText.isEmpty ? null : num.tryParse(salePriceText);
    if (salePriceText.isNotEmpty && salePrice == null) {
      showCmsSnackbar(
        title: 'Invalid sale price',
        message: 'Sale price must be a number or empty.',
        isError: true,
      );
      return;
    }
    if (salePrice != null && salePrice > price) {
      showCmsSnackbar(
        title: 'Invalid sale price',
        message: 'Sale price cannot exceed MRP.',
        isError: true,
      );
      return;
    }
    final stock = int.tryParse(_stockCtrl.text.trim()) ?? 0;
    final threshold = int.tryParse(_thresholdCtrl.text.trim()) ?? 10;
    if (stock < 0 || threshold < 0) {
      showCmsSnackbar(
        title: 'Invalid numbers',
        message: 'Stock and threshold must be zero or greater.',
        isError: true,
      );
      return;
    }

    final ok = _isEdit
        ? await widget.ctrl.updateItem(
            id: widget.item!.id,
            name: name,
            category: _category,
            unit: unit,
            itemQuantity: itemQty,
            price: price,
            salePrice: salePrice,
            clearSalePrice: salePriceText.isEmpty,
            currency: _currency,
            stockQuantity: stock,
            description: _descCtrl.text.trim(),
            lowStockThreshold: threshold,
            status: _status,
            image: _image,
          )
        : await widget.ctrl.createItem(
            name: name,
            category: _category,
            unit: unit,
            itemQuantity: itemQty,
            price: price,
            salePrice: salePrice,
            currency: _currency,
            stockQuantity: stock,
            description: _descCtrl.text.trim(),
            lowStockThreshold: threshold,
            status: _status,
            image: _image,
          );
    if (ok) widget.onSaved();
  }

  List<Widget> _buildDetailsFields() {
    return [
      CmsFormField(
        label: 'Name *',
        hint: 'e.g. Turmeric powder',
        controller: _nameCtrl,
      ),
      const SizedBox(height: 12),
      if (widget.ctrl.categories.isEmpty)
        CmsFormField(
          label: 'Category code *',
          hint: 'e.g. SACRED_POWDERS',
          initialValue: _category,
          onChanged: (v) => _category = v.trim().toUpperCase(),
        )
      else
        _CategoryPickerField(
          label: 'Category *',
          value: _category,
          categories: widget.ctrl.categories,
          resolveLabel: widget.ctrl.categoryLabel,
          onChanged: (code) => setState(() => _category = code),
        ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: CmsFormField(
              label: 'Item quantity *',
              hint: 'e.g. 50',
              controller: _itemQtyCtrl,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CmsFormField(
              label: 'Unit *',
              hint: 'grams, pieces, ml',
              controller: _unitCtrl,
            ),
          ),
        ],
      ),
      const SizedBox(height: 6),
      const Text(
        'Size of one unit — e.g. turmeric powder: 50 grams.',
        style: TextStyle(fontSize: 11, color: CmsColors.textSecond),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: CmsFormField(
              label: 'Stock quantity *',
              hint: 'e.g. 50',
              controller: _stockCtrl,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CmsFormField(
              label: 'Low stock threshold',
              hint: '10',
              controller: _thresholdCtrl,
            ),
          ),
        ],
      ),
      const SizedBox(height: 6),
      const Text(
        'Number of units in stock (not total grams). '
        '50 units × 50 g = 2,500 g total.',
        style: TextStyle(fontSize: 11, color: CmsColors.textSecond),
      ),
      if (_stockPreview != null) ...[
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E8),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: CmsColors.orange.withValues(alpha: 0.35)),
          ),
          child: Text(
            _stockPreview!,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: CmsColors.orangeDark,
            ),
          ),
        ),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 768;
    return Obx(() {
      final loading = widget.ctrl.isSubmitting;
      return Column(
        children: [
          Container(
            color: CmsColors.white,
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 24 : 16,
              vertical: 12,
            ),
            child: Row(
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
                Expanded(
                  child: Text(
                    _isEdit ? 'Edit inventory item' : 'Add inventory item',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: CmsColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: CmsColors.border),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isTablet ? 24 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isTablet)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: CmsFormCard(
                            title: 'Item details',
                            children: _buildDetailsFields(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CmsFormCard(
                            title: 'Product image',
                            children: [
                              CmsUploadBox(
                                label: _isEdit
                                    ? 'Product Image'
                                    : 'Product Image *',
                                icon: Icons.image_outlined,
                                accept: 'JPG, PNG up to 5MB',
                                mediaType: PickMediaType.image,
                                initialUrl: widget.item?.imageUrl,
                                onPicked: (f) => setState(() => _image = f),
                                onRemoved: () => setState(() => _image = null),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  else ...[
                    CmsFormCard(
                      title: 'Item details',
                      children: _buildDetailsFields(),
                    ),
                    const SizedBox(height: 16),
                    CmsFormCard(
                      title: 'Product image',
                      children: [
                        CmsUploadBox(
                          label:
                              _isEdit ? 'Product Image' : 'Product Image *',
                          icon: Icons.image_outlined,
                          accept: 'JPG, PNG up to 5MB',
                          mediaType: PickMediaType.image,
                          initialUrl: widget.item?.imageUrl,
                          onPicked: (f) => setState(() => _image = f),
                          onRemoved: () => setState(() => _image = null),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  CmsFormCard(
                    title: 'Pricing (per unit)',
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Expanded(
                            flex: 2,
                            child: _InvReadOnlyCurrency(),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: CmsFormField(
                              label: 'MRP *',
                              hint: '29.99',
                              controller: _priceCtrl,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: CmsFormField(
                              label: 'Sale price',
                              hint: 'Optional',
                              controller: _salePriceCtrl,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Sale price must be ≤ MRP. Price is per one '
                        'stock unit. Total available = stock quantity × item quantity.',
                        style: TextStyle(
                          fontSize: 11,
                          color: CmsColors.textSecond,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CmsFormCard(
                    title: 'More',
                    children: [
                      _DropdownField(
                        label: 'Status',
                        value: _status,
                        items: const [
                          MapEntry('ACTIVE', 'Active'),
                          MapEntry('INACTIVE', 'Inactive'),
                        ],
                        onChanged: (v) =>
                            setState(() => _status = v ?? _status),
                      ),
                      const SizedBox(height: 12),
                      CmsFormField(
                        label: 'Description',
                        hint: 'Optional notes',
                        controller: _descCtrl,
                        maxLines: 3,
                      ),
                    ],
                  ),
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
                                  _isEdit
                                      ? 'Save Changes'
                                      : 'Create inventory item',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }
}

/// Fixed ZAR label — no dropdown.
class _InvReadOnlyCurrency extends StatelessWidget {
  const _InvReadOnlyCurrency();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Currency',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: CmsColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: CmsColors.bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: CmsColors.border),
          ),
          child: const Text(
            'ZAR',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: CmsColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

/// Tap → searchable category list (no default selection).
class _CategoryPickerField extends StatelessWidget {
  const _CategoryPickerField({
    required this.label,
    required this.value,
    required this.categories,
    required this.resolveLabel,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<InventoryCategory> categories;
  final String Function(String code) resolveLabel;
  final ValueChanged<String> onChanged;

  String? get _displayLabel {
    if (value.isEmpty) return null;
    for (final c in categories) {
      if (c.code == value) return c.label;
    }
    final fallback = resolveLabel(value);
    return fallback == value ? value : fallback;
  }

  Future<void> _openPicker(BuildContext context) async {
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => _CategoryPickerDialog(
        categories: categories,
        selectedCode: value.isNotEmpty ? value : null,
      ),
    );
    if (code != null) onChanged(code);
  }

  @override
  Widget build(BuildContext context) {
    final display = _displayLabel;
    return Column(
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
        Material(
          color: CmsColors.white,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: categories.isEmpty ? null : () => _openPicker(context),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: CmsColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      display ?? 'Select category',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            display != null ? FontWeight.w600 : FontWeight.w400,
                        color: display != null
                            ? CmsColors.textPrimary
                            : CmsColors.textSecond,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 22,
                    color: CmsColors.textSecond,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryPickerDialog extends StatefulWidget {
  const _CategoryPickerDialog({
    required this.categories,
    this.selectedCode,
  });

  final List<InventoryCategory> categories;
  final String? selectedCode;

  @override
  State<_CategoryPickerDialog> createState() => _CategoryPickerDialogState();
}

class _CategoryPickerDialogState extends State<_CategoryPickerDialog> {
  late final TextEditingController _searchCtrl;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<InventoryCategory> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.categories;
    return widget.categories.where((c) {
      return c.label.toLowerCase().contains(q) ||
          c.code.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Select category',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: CmsColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search by name or code…',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: CmsColors.bg,
                  isDense: true,
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
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: filtered.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No categories match your search.',
                        style: TextStyle(
                          fontSize: 13,
                          color: CmsColors.textSecond,
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final cat = filtered[index];
                        final isSelected = cat.code == widget.selectedCode;
                        return InkWell(
                          onTap: () => Navigator.pop(context, cat.code),
                          child: Container(
                            color: isSelected
                                ? CmsColors.orange.withValues(alpha: 0.06)
                                : null,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cat.label,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected
                                              ? CmsColors.orange
                                              : CmsColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        cat.code,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: CmsColors.textSecond,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle,
                                    size: 18,
                                    color: CmsColors.orange,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });
  final String label;
  final String value;
  final List<MapEntry<String, String>> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: CmsColors.textSecond,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: items.any((e) => e.key == value) ? value : items.first.key,
          decoration: InputDecoration(
            filled: true,
            fillColor: CmsColors.bg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: CmsColors.border),
            ),
          ),
          items: items
              .map(
                (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _InventoryPaginationBar extends StatelessWidget {
  const _InventoryPaginationBar({required this.controller});
  final InventoryController controller;

  static const _pageSizes = [10, 20, 50, 100];

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final page = controller.page;
      final size = controller.limit;
      final tp = controller.totalPages;
      final totalRows = controller.total;
      final start = totalRows == 0 ? 0 : (page - 1) * size + 1;
      final end = (page * size).clamp(0, totalRows);

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Text(
              'Showing $start–$end of $totalRows',
              style: const TextStyle(fontSize: 12, color: CmsColors.textSecond),
            ),
            const SizedBox(width: 16),
            const Text(
              'Rows:',
              style: TextStyle(fontSize: 12, color: CmsColors.textSecond),
            ),
            const SizedBox(width: 6),
            DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _pageSizes.contains(size) ? size : 20,
                isDense: true,
                items: _pageSizes
                    .map((s) => DropdownMenuItem(value: s, child: Text('$s')))
                    .toList(),
                onChanged: (v) {
                  if (v != null) controller.setLimit(v);
                },
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: page > 1 ? controller.prevPage : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Text('Page $page of $tp',
                style: const TextStyle(fontSize: 12, color: CmsColors.textSecond)),
            IconButton(
              onPressed: page < tp ? controller.nextPage : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      );
    });
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: CmsColors.red, size: 36),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            CmsPrimaryButton(
              label: 'Retry',
              icon: Icons.refresh_rounded,
              onTap: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
