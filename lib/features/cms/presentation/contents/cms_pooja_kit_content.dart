// lib/features/cms/presentation/contents/cms_pooja_kit_content.dart
//
// Pooja Kit CMS screens.
//
// Sidebar group "Pooja Kit" expands into:
//   • Manage Pooja Kit  → [CmsPoojaKitContent]            (this file, list + Add form)
//   • Orders            → [CmsPoojaKitOrdersContent]      (cms_pooja_kit_orders_content.dart)
//   • Replace  → [CmsPoojaKitRefundsContent]     (cms_pooja_kit_refunds_content.dart)
//   • Payments          → [CmsPoojaKitPaymentsContent]    (cms_pooja_kit_payments_content.dart)
//
// Create flow uses multipart/form-data against
// POST /api/v1/products/create-product.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/core/services/media_upload_service.dart';
import 'package:satya_devotte_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:satya_devotte_app/features/cms/data/models/inventory_models.dart';
import 'package:satya_devotte_app/features/cms/models/product_model.dart';
import 'package:satya_devotte_app/features/cms/presentation/controllers/inventory_controller.dart';
import 'package:satya_devotte_app/features/cms/presentation/controllers/product_controller.dart';
import 'package:satya_devotte_app/features/cms/presentation/pages/cms_shell_page.dart';
import 'package:satya_devotte_app/features/cms/presentation/widgets/cms_shared_widgets.dart';
import 'package:satya_devotte_app/features/cms/presentation/widgets/cms_upload_box.dart';

// ════════════════════════════════════════════════════════════════
// MANAGE POOJA KIT
// ════════════════════════════════════════════════════════════════
class CmsPoojaKitContent extends StatefulWidget {
  const CmsPoojaKitContent({super.key});

  @override
  State<CmsPoojaKitContent> createState() => _CmsPoojaKitContentState();
}

class _CmsPoojaKitContentState extends State<CmsPoojaKitContent> {
  late final ProductController _ctrl;
  bool _showForm = false;
  ProductModel? _editing;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<ProductController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _ctrl.loadProducts();
    });
  }

  void _closeForm() => setState(() {
        _showForm = false;
        _editing = null;
      });

  @override
  Widget build(BuildContext context) {
    if (_showForm) {
      return _ProductForm(
        ctrl: _ctrl,
        product: _editing,
        onCancel: _closeForm,
        onSaved: () {
          _closeForm();
          _ctrl.loadProducts();
        },
      );
    }
    return _ProductList(
      ctrl: _ctrl,
      onAdd: () => setState(() {
        _editing = null;
        _showForm = true;
      }),
      onEdit: (p) => setState(() {
        _editing = p;
        _showForm = true;
      }),
    );
  }
}

// ── List view ────────────────────────────────────────────────────
class _ProductList extends StatelessWidget {
  const _ProductList({
    required this.ctrl,
    required this.onAdd,
    required this.onEdit,
  });

  final ProductController ctrl;
  final VoidCallback onAdd;
  final ValueChanged<ProductModel> onEdit;

  static const _filters = [
    'All',
    'Pending',
    'Queued',
    'Approved',
    'Rejected',
    'Active',
    'Inactive',
  ];

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width >= 1024;
    final isTablet = MediaQuery.of(context).size.width >= 768;
    return Column(
      children: [
        // ── Header bar (title + search + Add + Bulk Edit) ─────────
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
                  'Puja Kits',
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
                  hint: 'Search Puja Kits...',
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
                        onTap: ctrl.loadProducts,
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
                label: isTablet ? '+ Add Puja Kit' : 'Add',
                onTap: onAdd,
              ),
            ],
          ),
        ),
        // ── Filter tabs ───────────────────────────────────────────
        Container(
          color: CmsColors.white,
          padding: EdgeInsets.only(left: isWeb ? 24 : 16, bottom: 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Obx(
              () => Row(
                children: _filters.expand((f) {
                  final isSel = ctrl.filter == f;
                  // Show a count badge for every non-"All" chip when the
                  // currently-loaded page has at least one match. Helps
                  // distinguish lifecycle filters (Active / Inactive) from
                  // review filters (Pending / Queued / …) at a glance.
                  final showCount = f != 'All' && ctrl.countFor(f) > 0;
                  // Vertical divider between the review-status group
                  // (…Rejected) and the lifecycle group (Active, Inactive).
                  final leading = <Widget>[
                    if (f == 'Active')
                      Container(
                        width: 1,
                        height: 22,
                        margin: const EdgeInsets.only(right: 12, left: 4),
                        color: CmsColors.border,
                      ),
                  ];
                  return [
                    ...leading,
                    GestureDetector(
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
                          if (showCount) ...[
                            const SizedBox(width: 5),
                            _filterCountBadge(ctrl.countFor(f), isSel),
                          ],
                        ],
                      ),
                    ),
                    ),
                  ];
                }).toList(),
              ),
            ),
          ),
        ),
        const Divider(height: 1, color: CmsColors.border),
        Expanded(
          child: Obx(() {
            if (ctrl.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: CmsColors.orange),
              );
            }
            final allFiltered = ctrl.filteredProducts;
            if (allFiltered.isEmpty) {
              return CmsEmptyState(
                icon: Icons.shopping_basket_outlined,
                title: (ctrl.filter == 'All' && ctrl.search.isEmpty)
                    ? 'No Puja Kits Yet'
                    : 'No matching Puja Kits',
                subtitle:
                    'Puja Kits you create will appear here. Tap "+ Add Puja Kit" '
                    'to create your first kit.',
                actionLabel:
                    (ctrl.filter == 'All' && ctrl.search.isEmpty)
                        ? 'Add Puja Kit'
                        : null,
                onAction:
                    (ctrl.filter == 'All' && ctrl.search.isEmpty)
                        ? onAdd
                        : null,
              );
            }
            final paged = ctrl.pagedProducts;
            return RefreshIndicator(
              color: CmsColors.orange,
              onRefresh: ctrl.loadProducts,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 24 : 16,
                  vertical: isTablet ? 20 : 16,
                ),
                child: Column(
                  children: [
                    if (isTablet)
                      // Table always fits the available width — columns
                      // flex to share the row, no horizontal scrolling.
                      _ProductTable(
                        ctrl: ctrl,
                        rows: paged,
                        onEdit: onEdit,
                        onDelete: (p) => _deleteConfirm(context, p, ctrl),
                        onApprove: (p) => _approveDialog(context, p, ctrl),
                        onReject: (p) => _rejectDialog(context, p, ctrl),
                        onQueue: (p) => ctrl.queueProduct(p.id),
                      )
                    else
                      Column(
                        children: [
                          for (final p in paged) ...[
                            _ProductCard(
                              product: p,
                              onEdit: () => onEdit(p),
                              onDelete: () =>
                                  _deleteConfirm(context, p, ctrl),
                              onApprove: () =>
                                  _approveDialog(context, p, ctrl),
                              onReject: () =>
                                  _rejectDialog(context, p, ctrl),
                              onQueue: () => ctrl.queueProduct(p.id),
                              onToggleStatus: (active) =>
                                  ctrl.setProductStatus(
                                id: p.id,
                                productStatus:
                                    active ? 'ACTIVE' : 'INACTIVE',
                              ),
                              isStatusPending: () =>
                                  ctrl.isStatusPending(p.id),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ],
                      ),
                    const SizedBox(height: 12),
                    _PaginationBar(ctrl: ctrl),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _filterCountBadge(int count, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.white.withOpacity(0.3)
            : CmsColors.orange,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ── Confirm / dialog helpers ─────────────────────────────────────
void _deleteConfirm(
  BuildContext ctx,
  ProductModel p,
  ProductController ctrl,
) async {
  final ok = await showCmsDeleteDialog(ctx, itemName: p.title);
  if (ok == true) await ctrl.deleteProduct(p.id);
}

void _approveDialog(
  BuildContext ctx,
  ProductModel p,
  ProductController ctrl,
) {
  showDialog<void>(
    context: ctx,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: const Text(
        'Approve Puja Kit',
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
            'This will publish the Puja Kit to all users.',
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
            await ctrl.approveProduct(p.id);
          },
          icon: const Icon(Icons.check, size: 16),
          label: const Text('Approve & Publish'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
          ),
        ),
      ],
    ),
  );
}

void _rejectDialog(
  BuildContext ctx,
  ProductModel p,
  ProductController ctrl,
) {
  final reasonCtrl = TextEditingController();
  showDialog<void>(
    context: ctx,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: const Text(
        'Reject Puja Kit',
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
              hintText: 'e.g. Missing details...',
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
            await ctrl.rejectProduct(p.id, reasonCtrl.text.trim());
          },
          icon: const Icon(Icons.close, size: 16),
          label: const Text('Reject'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
          ),
        ),
      ],
    ),
  );
}

// ════════════════════════════════════════════════════════════════
// PRODUCT TABLE (web / tablet)
// ════════════════════════════════════════════════════════════════
class _ProductTable extends StatelessWidget {
  const _ProductTable({
    required this.ctrl,
    required this.rows,
    required this.onEdit,
    required this.onDelete,
    required this.onApprove,
    required this.onReject,
    required this.onQueue,
  });

  final ProductController ctrl;
  final List<ProductModel> rows;
  final ValueChanged<ProductModel> onEdit;
  final ValueChanged<ProductModel> onDelete;
  final ValueChanged<ProductModel> onApprove;
  final ValueChanged<ProductModel> onReject;
  final ValueChanged<ProductModel> onQueue;

  // Column flex weights — sized so the table always fits inside the
  // available width on web/tablet (no horizontal scrolling).
  static const _flexName = 5;
  static const _flexCreated = 3;
  static const _flexQty = 2;
  static const _flexPrice = 2;
  static const _flexStatus = 3;
  static const _flexAction = 4;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CmsColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CmsColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(),
            for (int i = 0; i < rows.length; i++) ...[
              if (i != 0)
                const Divider(height: 1, color: CmsColors.border),
              _ProductTableRow(
                product: rows[i],
                isStriped: i.isOdd,
                isStatusPending: ctrl.isStatusPending(rows[i].id),
                onEdit: () => onEdit(rows[i]),
                onDelete: () => onDelete(rows[i]),
                onApprove: () => onApprove(rows[i]),
                onReject: () => onReject(rows[i]),
                onQueue: () => onQueue(rows[i]),
                onToggleStatus: (a) => ctrl.setProductStatus(
                  id: rows[i].id,
                  productStatus: a ? 'ACTIVE' : 'INACTIVE',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFFF7F8FA),
        border: Border(
          bottom: BorderSide(color: CmsColors.border),
        ),
      ),
      child: const Row(
        children: [
          Expanded(flex: _flexName, child: _HCell('Product Name')),
          Expanded(flex: _flexCreated, child: _HCell('Created At')),
          Expanded(flex: _flexQty, child: _HCell('Kits')),
          Expanded(flex: _flexPrice, child: _HCell('Price', alignRight: true)),
          Expanded(
            flex: _flexStatus,
            child: Padding(
              padding: EdgeInsets.only(left: 16),
              child: _HCell('Status'),
            ),
          ),
          Expanded(
            flex: _flexAction,
            child: _HCell('Action', alignRight: true),
          ),
        ],
      ),
    );
  }
}

class _HCell extends StatelessWidget {
  const _HCell(this.label, {this.alignRight = false});
  final String label;
  final bool alignRight;

  @override
  Widget build(BuildContext context) => Text(
        label,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: CmsColors.textSecond,
          letterSpacing: 0.2,
        ),
      );
}

class _ProductTableRow extends StatefulWidget {
  const _ProductTableRow({
    required this.product,
    required this.isStriped,
    required this.isStatusPending,
    required this.onEdit,
    required this.onDelete,
    required this.onApprove,
    required this.onReject,
    required this.onQueue,
    required this.onToggleStatus,
  });
  final ProductModel product;
  final bool isStriped;
  final bool isStatusPending;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onQueue;
  final Future<bool> Function(bool) onToggleStatus;

  @override
  State<_ProductTableRow> createState() => _ProductTableRowState();
}

class _ProductTableRowState extends State<_ProductTableRow> {
  bool _hover = false;

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    try {
      final d = DateTime.parse(raw).toLocal();
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
      final ampm = d.hour < 12 ? 'am' : 'pm';
      final mm = d.minute.toString().padLeft(2, '0');
      return '${months[d.month - 1]} ${d.day}, ${d.year} '
          '$hour12:$mm $ampm';
    } catch (_) {
      return raw;
    }
  }

  Color _reviewColor(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return const Color(0xFF2E7D32);
      case 'REJECTED':
        return const Color(0xFFC62828);
      case 'QUEUED':
        return CmsColors.orangeDark;
      case 'PENDING':
      default:
        return const Color(0xFFEF6C00);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final auth = Get.find<AuthController>();
    final isSuperAdmin = auth.isSuperAdmin;
    final isCreatorSuperAdmin =
        isSuperAdmin && p.createdBy == auth.currentUserId;
    final canReview = isSuperAdmin && (p.isPending || p.isQueued);
    final reviewColor = _reviewColor(p.status);

    final bg = _hover
        ? const Color(0xFFFAFBFD)
        : (widget.isStriped
            ? const Color(0xFFFCFCFD)
            : CmsColors.white);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.basic,
      child: Container(
        color: bg,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Name (with review status below) ───────────────────
            Expanded(
              flex: _ProductTable._flexName,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: p.imageUrl != null && p.imageUrl!.isNotEmpty
                        ? Image.network(
                            p.imageUrl!,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholder(),
                          )
                        : _placeholder(),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          p.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: CmsColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Review status pill — sits under the title so
                        // PENDING / QUEUED / APPROVED / REJECTED is
                        // always visible next to the product name.
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: reviewColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: reviewColor.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            p.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: reviewColor,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // ── Created at ───────────────────────────────────────
            Expanded(
              flex: _ProductTable._flexCreated,
              child: Text(
                _formatDate(p.createdAt),
                style: const TextStyle(
                  fontSize: 12,
                  color: CmsColors.textPrimary,
                ),
              ),
            ),
            // ── Quantity ─────────────────────────────────────────
            Expanded(
              flex: _ProductTable._flexQty,
              child: Text(
                _formatQty(p.stockQuantity),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: CmsColors.textPrimary,
                ),
              ),
            ),
            // ── Price ────────────────────────────────────────────
            // Show sale price prominently with the original price struck
            // through directly below — only when [salePrice] is set and
            // actually undercuts the base price. Otherwise just the base
            // price renders.
            Expanded(
              flex: _ProductTable._flexPrice,
              child: _PriceCell(
                currency: p.currency,
                price: p.price,
                salePrice: p.salePrice,
              ),
            ),
            // ── Status toggle (Active / Inactive) ────────────────
            // Left padding pushes the toggle away from the right-aligned
            // price column so the two never visually touch.
            Expanded(
              flex: _ProductTable._flexStatus,
              child: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: _StatusSwitch(
                  isActive: p.isActive,
                  pending: widget.isStatusPending,
                  onChanged: widget.onToggleStatus,
                ),
              ),
            ),
            // ── Actions ──────────────────────────────────────────
            // Row 1: edit + delete icons.
            // Row 2 (if super-admin and reviewable): Approve / Reject
            //        — or Queue / Publish when the creator is a
            //        super-admin themselves.
            Expanded(
              flex: _ProductTable._flexAction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      CmsActionIcon(
                        icon: Icons.edit_outlined,
                        color: Colors.blue,
                        onTap: widget.onEdit,
                        tooltip: 'Edit',
                      ),
                      const SizedBox(width: 6),
                      CmsActionIcon(
                        icon: Icons.delete_outline,
                        color: Colors.red,
                        onTap: widget.onDelete,
                        tooltip: 'Delete',
                      ),
                    ],
                  ),
                  if (canReview) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (isCreatorSuperAdmin) ...[
                          if (p.isPending) ...[
                            _SmBtn(
                              'Queue',
                              Colors.orange,
                              widget.onQueue,
                            ),
                            const SizedBox(width: 6),
                          ],
                          _SmBtn(
                            'Publish',
                            Colors.green,
                            widget.onApprove,
                          ),
                        ] else ...[
                          _SmBtn('Reject', Colors.red, widget.onReject),
                          const SizedBox(width: 6),
                          _SmBtn(
                            'Approve',
                            Colors.green,
                            widget.onApprove,
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: CmsColors.orange.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.shopping_basket_outlined,
          color: CmsColors.orange,
          size: 18,
        ),
      );

  String _formatQty(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i != 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

// ── Small reusable bits for the table ───────────────────────────
//
// Price cell: when `salePrice` is set and below `price`, the sale price
// is shown prominently and the original price is rendered struck-through
// underneath as `"<salePrice> / <price>"` (with the strike on the latter).
// When there's no sale price (or it doesn't actually undercut the base),
// just the base price is shown.
class _PriceCell extends StatelessWidget {
  const _PriceCell({
    required this.currency,
    required this.price,
    required this.salePrice,
  });

  final String currency;
  final num price;
  final num? salePrice;

  String _fmt(num v) {
    // Trim a trailing `.0` so whole-number prices render cleanly.
    final s = v.toString();
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }

  @override
  Widget build(BuildContext context) {
    final hasSale = salePrice != null && salePrice! < price;
    // `SizedBox(width: double.infinity)` makes the cell claim the full
    // width of its parent `Expanded`. That guarantees the Text children
    // receive a bounded width and the `overflow: ellipsis` actually
    // truncates extremely long values (a long unbroken number like
    // `300000000000004` would otherwise blow past the column edge).
    if (!hasSale) {
      return SizedBox(
        width: double.infinity,
        child: Text(
          '$currency ${_fmt(price)}',
          textAlign: TextAlign.right,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: CmsColors.textPrimary,
          ),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$currency ${_fmt(salePrice!)}',
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: CmsColors.orange,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$currency ${_fmt(price)}',
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: CmsColors.textSecond,
              decoration: TextDecoration.lineThrough,
              decorationColor: CmsColors.textSecond,
            ),
          ),
        ],
      ),
    );
  }
}

// Single Active/Inactive toggle used inside table rows. Renders as a real
// Material `Switch` with a small label next to it; while a request is in
// flight (`pending`) the switch is replaced by a tiny spinner so users
// don't double-tap.
class _StatusSwitch extends StatelessWidget {
  const _StatusSwitch({
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
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
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
                onChanged: (v) => onChanged(v),
                activeColor: Colors.white,
                activeTrackColor: const Color(0xFF2E7D32),
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: const Color(0xFFC62828).withOpacity(0.45),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          const SizedBox(width: 6),
          // Flexible + ellipsis so the label never blows up the column
          // width on very narrow viewports.
          Flexible(
            child: Text(
              isActive ? 'Active' : 'Inactive',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// PAGINATION
// ════════════════════════════════════════════════════════════════
class _PaginationBar extends StatelessWidget {
  const _PaginationBar({required this.ctrl});
  final ProductController ctrl;

  static const _pageSizes = [10, 25, 50, 100];

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isWide = MediaQuery.of(context).size.width >= 768;
      final page = ctrl.page;
      final size = ctrl.pageSize;
      final tp = ctrl.totalPages;
      final totalRows = ctrl.totalRows;
      final start = totalRows == 0 ? 0 : (page - 1) * size + 1;
      final end = (page * size).clamp(0, totalRows);

      final children = <Widget>[
        Text(
          'Showing $start–$end of $totalRows',
          style: const TextStyle(
            fontSize: 12,
            color: CmsColors.textSecond,
          ),
        ),
        const SizedBox(width: 18),
        const Text(
          'Rows per page:',
          style: TextStyle(fontSize: 12, color: CmsColors.textSecond),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: CmsColors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: CmsColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _pageSizes.contains(size) ? size : _pageSizes.first,
              isDense: true,
              style: const TextStyle(
                fontSize: 12,
                color: CmsColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              items: _pageSizes
                  .map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text('$s'),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) ctrl.setPageSize(v);
              },
            ),
          ),
        ),
      ];

      final pager = <Widget>[
        _PagerBtn(
          icon: Icons.chevron_left,
          enabled: page > 1,
          onTap: () => ctrl.setPage(page - 1),
        ),
        for (final n in _pageRange(page, tp))
          n == -1
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    '…',
                    style: TextStyle(color: CmsColors.textSecond),
                  ),
                )
              : _PageNumberBtn(
                  number: n,
                  isActive: n == page,
                  onTap: () => ctrl.setPage(n),
                ),
        _PagerBtn(
          icon: Icons.chevron_right,
          enabled: page < tp,
          onTap: () => ctrl.setPage(page + 1),
        ),
      ];

      if (isWide) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: CmsColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: CmsColors.border),
          ),
          child: Row(
            children: [
              ...children,
              const Spacer(),
              ...pager.map(
                (w) => Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: w,
                ),
              ),
            ],
          ),
        );
      }
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: CmsColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CmsColors.border),
        ),
        child: Column(
          children: [
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 6,
              children: children,
            ),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              runSpacing: 4,
              children: pager,
            ),
          ],
        ),
      );
    });
  }

  /// Window of page numbers around the current page. Returns `-1` for
  /// ellipses. Always includes first + last.
  List<int> _pageRange(int current, int total) {
    if (total <= 7) return [for (int i = 1; i <= total; i++) i];
    final out = <int>[1];
    final start = (current - 1).clamp(2, total - 4);
    final end = (current + 1).clamp(5, total - 1);
    if (start > 2) out.add(-1);
    for (int i = start; i <= end; i++) {
      out.add(i);
    }
    if (end < total - 1) out.add(-1);
    out.add(total);
    return out;
  }
}

class _PagerBtn extends StatelessWidget {
  const _PagerBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: enabled ? CmsColors.bg : CmsColors.bg.withOpacity(0.6),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: CmsColors.border),
          ),
          child: Icon(
            icon,
            size: 18,
            color: enabled
                ? CmsColors.textPrimary
                : CmsColors.textSecond.withOpacity(0.5),
          ),
        ),
      );
}

class _PageNumberBtn extends StatelessWidget {
  const _PageNumberBtn({
    required this.number,
    required this.isActive,
    required this.onTap,
  });
  final int number;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? CmsColors.orange : CmsColors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive ? CmsColors.orange : CmsColors.border,
            ),
          ),
          child: Text(
            '$number',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isActive ? Colors.white : CmsColors.textPrimary,
            ),
          ),
        ),
      );
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.onEdit,
    required this.onDelete,
    required this.onApprove,
    required this.onReject,
    required this.onQueue,
    required this.onToggleStatus,
    required this.isStatusPending,
  });
  final ProductModel product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onQueue;
  final Future<bool> Function(bool active) onToggleStatus;
  final bool Function() isStatusPending;

  Color _reviewColor(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return const Color(0xFF2E7D32);
      case 'REJECTED':
        return const Color(0xFFC62828);
      case 'QUEUED':
        return CmsColors.orangeDark;
      case 'PENDING':
      default:
        return const Color(0xFFEF6C00);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final isSuperAdmin = auth.isSuperAdmin;
    // A super-admin who is *also* the creator of this product gets the
    // "Publish Now / Queue" action set (same UX as Donations / Poojas).
    final isCreatorSuperAdmin =
        isSuperAdmin && product.createdBy == auth.currentUserId;
    final canReview = isSuperAdmin &&
        (product.isPending || product.isQueued);
    final reviewColor = _reviewColor(product.status);
    final isWide = MediaQuery.of(context).size.width >= 768;
    final imageSize = isWide ? 132.0 : 96.0;

    return Container(
      decoration: BoxDecoration(
        color: CmsColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: reviewColor.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Image rail (full card height) ──────────────────
              Stack(
                children: [
                  SizedBox(
                    width: imageSize,
                    child: product.imageUrl != null &&
                            product.imageUrl!.isNotEmpty
                        ? Image.network(
                            product.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _imgFallback(imageSize),
                          )
                        : _imgFallback(imageSize),
                  ),
                  // Featured badge floats over the image.
                  if (product.isFeatured)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5A623),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 11,
                              color: Colors.white,
                            ),
                            SizedBox(width: 3),
                            Text(
                              'Featured',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              // ── Body ───────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top: title row + chips
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.title,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: CmsColors.textPrimary,
                                        height: 1.25,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        if (product.category.isNotEmpty) ...[
                                          const Icon(
                                            Icons.category_outlined,
                                            size: 13,
                                            color: CmsColors.textSecond,
                                          ),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              product.category,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: CmsColors.textSecond,
                                              ),
                                              overflow:
                                                  TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            width: 3,
                                            height: 3,
                                            decoration: const BoxDecoration(
                                              color: CmsColors.textSecond,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                        Flexible(
                                          child: Text(
                                            product.slug,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: CmsColors.textSecond,
                                              fontFamily: 'monospace',
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Price block (right aligned).
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    product.displayPrice,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: CmsColors.orange,
                                    ),
                                  ),
                                  if (product.salePrice != null &&
                                      product.salePrice! < product.price)
                                    Text(
                                      '${product.currency} ${product.price.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: CmsColors.textSecond,
                                        decoration:
                                            TextDecoration.lineThrough,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          if (product.description.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              product.description,
                              style: const TextStyle(
                                fontSize: 12,
                                color: CmsColors.textSecond,
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 10),
                          // Status + meta chip rail.
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _statusChip(
                                label: product.status.toUpperCase(),
                                color: reviewColor,
                                icon: _reviewIcon(product.status),
                              ),
                              _metaChip(
                                icon: Icons.inventory_2_outlined,
                                label: '${product.stockQuantity} kits',
                                color: const Color(0xFF1976D2),
                              ),
                              if (product.items.isNotEmpty)
                                _metaChip(
                                  icon: Icons.list_alt_rounded,
                                  label:
                                      '${product.items.length} item${product.items.length == 1 ? '' : 's'}',
                                  color: const Color(0xFF6A1B9A),
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: CmsColors.border),
                      const SizedBox(height: 10),
                      // ── Actions ───────────────────────────────
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        alignment: WrapAlignment.start,
                        children: [
                          CmsActionIcon(
                            icon: Icons.edit_outlined,
                            color: Colors.blue,
                            onTap: onEdit,
                            tooltip: 'Edit',
                          ),
                          CmsActionIcon(
                            icon: Icons.delete_outline,
                            color: Colors.red,
                            onTap: onDelete,
                            tooltip: 'Delete',
                          ),
                          _ActiveInactiveToggle(
                            isActive: product.isActive,
                            pending: isStatusPending(),
                            onChanged: onToggleStatus,
                          ),
                          if (canReview) ...[
                            if (isCreatorSuperAdmin) ...[
                              if (product.isPending)
                                _SmBtn('Queue', Colors.orange, onQueue),
                              _SmBtn(
                                'Publish Now',
                                Colors.green,
                                onApprove,
                              ),
                            ] else ...[
                              _SmBtn('Reject', Colors.red, onReject),
                              _SmBtn('Approve', Colors.green, onApprove),
                            ],
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imgFallback(double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              CmsColors.orange.withOpacity(0.18),
              CmsColors.orange.withOpacity(0.06),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Icon(
          Icons.shopping_basket_outlined,
          color: CmsColors.orange,
          size: 38,
        ),
      );

  IconData _reviewIcon(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return Icons.check_circle_outline;
      case 'REJECTED':
        return Icons.cancel_outlined;
      case 'QUEUED':
        return Icons.schedule_outlined;
      case 'PENDING':
      default:
        return Icons.hourglass_top_outlined;
    }
  }

  Widget _statusChip({
    required String label,
    required Color color,
    required IconData icon,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      );

  Widget _metaChip({
    required IconData icon,
    required String label,
    required Color color,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      );

}

// ── Active / Inactive chip-style switch ──────────────────────────
class _ActiveInactiveToggle extends StatelessWidget {
  const _ActiveInactiveToggle({
    required this.isActive,
    required this.pending,
    required this.onChanged,
  });

  final bool isActive;
  final bool pending;
  final Future<bool> Function(bool active) onChanged;

  @override
  Widget build(BuildContext context) {
    final activeColor = const Color(0xFF2E7D32);
    final inactiveColor = CmsColors.textSecond;
    final color = isActive ? activeColor : inactiveColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pending)
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: color,
              ),
            )
          else
            Icon(
              isActive ? Icons.check_circle_outline : Icons.block_outlined,
              size: 14,
              color: color,
            ),
          const SizedBox(width: 6),
          Text(
            isActive ? 'Active' : 'Inactive',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          Transform.scale(
            scale: 0.75,
            child: Switch(
              value: isActive,
              onChanged: pending ? null : (v) => onChanged(v),
              activeColor: Colors.white,
              activeTrackColor: activeColor,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: inactiveColor.withOpacity(0.5),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Small text button used for Approve / Reject / Queue ─────────
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
// ADD POOJA KIT — FORM
// ════════════════════════════════════════════════════════════════
class _ProductForm extends StatefulWidget {
  const _ProductForm({
    required this.ctrl,
    this.product,
    required this.onCancel,
    required this.onSaved,
  });
  final ProductController ctrl;
  // When non-null the form is in **edit mode**: fields are pre-filled and
  // submit calls `updateProduct` instead of `createProduct`.
  final ProductModel? product;
  final VoidCallback onCancel;
  final VoidCallback onSaved;

  @override
  State<_ProductForm> createState() => _ProductFormState();
}

class _KitLineEditor {
  _KitLineEditor({
    required this.inventoryItemId,
    TextEditingController? quantityCtrl,
    this.onQtyChanged,
  }) : quantityCtrl = quantityCtrl ?? TextEditingController(text: '1') {
    if (onQtyChanged != null) {
      this.quantityCtrl.addListener(onQtyChanged!);
    }
  }

  String inventoryItemId;
  final TextEditingController quantityCtrl;
  final VoidCallback? onQtyChanged;

  void dispose() {
    if (onQtyChanged != null) {
      quantityCtrl.removeListener(onQtyChanged!);
    }
    quantityCtrl.dispose();
  }
}

String _kitMoney(num amount, String currency) {
  final sym = currency == 'ZAR' ? 'R' : currency;
  final n = amount == amount.roundToDouble()
      ? amount.toStringAsFixed(0)
      : amount.toStringAsFixed(2);
  return '$sym $n';
}

class _KitComponentsCost {
  const _KitComponentsCost({
    required this.listTotal,
    required this.saleTotal,
    required this.currency,
    this.skippedOtherCurrency = 0,
    this.hasInventorySale = false,
  });

  /// Sum of inventory list `price` × units per kit.
  final num listTotal;
  /// Sum using each item's sale price when set (else list price).
  final num saleTotal;
  final String currency;
  final int skippedOtherCurrency;
  final bool hasInventorySale;

  bool get hasLines =>
      listTotal > 0 || saleTotal > 0 || skippedOtherCurrency > 0;
}

String _formatPriceInput(num value) {
  return value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(2);
}

bool _inventoryHasSale(InventoryItem inv) {
  final sale = inv.salePrice;
  return sale != null && sale < inv.price;
}

class _ProductFormState extends State<_ProductForm> {
  late final InventoryController _invCtrl;
  late final TextEditingController _titleCtrl;
  late final TextEditingController _slugCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _salePriceCtrl;
  late String _currency;
  late String _reviewStatus;
  late String _productStatus;
  late bool _isFeatured;
  PickedFile? _image;
  bool _slugManuallyEdited = false;
  final List<_KitLineEditor> _kitLines = [];

  bool get _isEdit => widget.product != null;

  static const _reviewStatuses = ['DRAFT', 'PENDING'];

  @override
  void initState() {
    super.initState();
    _invCtrl = Get.find<InventoryController>();
    final p = widget.product;
    _titleCtrl = TextEditingController(text: p?.title ?? '');
    _slugCtrl = TextEditingController(text: p?.slug ?? '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _categoryCtrl = TextEditingController(text: p?.category ?? '');
    _priceCtrl = TextEditingController(
      text: p == null ? '' : p.price.toString(),
    );
    _salePriceCtrl = TextEditingController(
      text: p?.salePrice == null ? '' : p!.salePrice.toString(),
    );
    _currency = p?.currency.isNotEmpty == true ? p!.currency : 'ZAR';
    _reviewStatus = p != null && _reviewStatuses.contains(p.status.toUpperCase())
        ? p.status.toUpperCase()
        : 'PENDING';
    _productStatus =
        p?.productStatus.isNotEmpty == true ? p!.productStatus : 'ACTIVE';
    _isFeatured = p?.isFeatured ?? false;
    _slugManuallyEdited = p != null && p.slug.isNotEmpty;

    if (!_isEdit) {
      _titleCtrl.addListener(_syncSlug);
      _slugCtrl.addListener(_markSlugEdited);
    }
    _priceCtrl.addListener(_onPricingFieldsChanged);
    _salePriceCtrl.addListener(_onPricingFieldsChanged);

    if (p != null && p.items.isNotEmpty) {
      final seen = <String>{};
      for (final item in p.items) {
        if (item.inventoryItem.isEmpty) continue;
        if (!seen.add(item.inventoryItem)) continue;
        _kitLines.add(_newKitLine(
          inventoryItemId: item.inventoryItem,
          quantityText: item.quantity.toString(),
        ));
      }
      if (_kitLines.isEmpty) _addKitLine();
    } else {
      _addKitLine();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _invCtrl.loadPickerItems();
    });
  }

  void _onPricingFieldsChanged() {
    if (mounted) setState(() {});
  }

  void _syncSlug() {
    if (_slugManuallyEdited) return;
    final generated = ProductController.slugify(_titleCtrl.text);
    if (_slugCtrl.text != generated) {
      _slugCtrl
        ..removeListener(_markSlugEdited)
        ..text = generated
        ..selection = TextSelection.collapsed(offset: generated.length)
        ..addListener(_markSlugEdited);
    }
  }

  void _markSlugEdited() {
    final generated = ProductController.slugify(_titleCtrl.text);
    if (_slugCtrl.text != generated) {
      _slugManuallyEdited = true;
    }
  }

  _KitLineEditor _newKitLine({
    String inventoryItemId = '',
    String quantityText = '1',
  }) {
    return _KitLineEditor(
      inventoryItemId: inventoryItemId,
      quantityCtrl: TextEditingController(text: quantityText),
      onQtyChanged: () {
        if (mounted) setState(() {});
      },
    );
  }

  void _addKitLine() {
    if (!_canAddKitLine) return;
    setState(() {
      _kitLines.add(_newKitLine());
    });
  }

  /// Inventory IDs already picked on other kit lines (optionally skip one row).
  Set<String> _usedInventoryIdsExcept(int? lineIndex) {
    final used = <String>{};
    for (var i = 0; i < _kitLines.length; i++) {
      if (lineIndex != null && i == lineIndex) continue;
      final id = _kitLines[i].inventoryItemId;
      if (id.isNotEmpty) used.add(id);
    }
    return used;
  }

  bool get _canAddKitLine => _pickerOptions.isNotEmpty;

  String? _duplicateInventoryId() {
    final seen = <String>{};
    for (final line in _kitLines) {
      final id = line.inventoryItemId;
      if (id.isEmpty) continue;
      if (!seen.add(id)) return id;
    }
    return null;
  }

  void _onInventoryItemSelected(int lineIndex, String id) {
    setState(() => _kitLines[lineIndex].inventoryItemId = id);
  }

  InventoryItem? _inventoryForId(String id) {
    if (id.isEmpty) return null;
    final fromPicker = _invCtrl.inventoryById(id);
    if (fromPicker != null) return fromPicker;
    for (final i in _pickerOptions) {
      if (i.id == id) return i;
    }
    return null;
  }

  _KitComponentsCost _componentsCost() {
    var listTotal = 0.0;
    var saleTotal = 0.0;
    var skipped = 0;
    var hasSale = false;
    for (final line in _kitLines) {
      if (line.inventoryItemId.isEmpty) continue;
      final qty = num.tryParse(line.quantityCtrl.text.trim());
      if (qty == null || qty <= 0) continue;
      final inv = _inventoryForId(line.inventoryItemId);
      if (inv == null) continue;
      if (inv.currency != _currency) {
        skipped++;
        continue;
      }
      listTotal += inv.price * qty;
      final onSale = _inventoryHasSale(inv);
      if (onSale) hasSale = true;
      final unitSale = onSale ? inv.salePrice! : inv.price;
      saleTotal += unitSale * qty;
    }
    return _KitComponentsCost(
      listTotal: listTotal,
      saleTotal: saleTotal,
      currency: _currency,
      skippedOtherCurrency: skipped,
      hasInventorySale: hasSale,
    );
  }

  void _applyInventoryPricesToKit() {
    final cost = _componentsCost();
    if (cost.listTotal <= 0) return;
    _priceCtrl.text = _formatPriceInput(cost.listTotal);
    if (cost.hasInventorySale && cost.saleTotal < cost.listTotal) {
      _salePriceCtrl.text = _formatPriceInput(cost.saleTotal);
    } else {
      _salePriceCtrl.clear();
    }
    setState(() {});
  }

  void _removeKitLine(int index) {
    setState(() {
      _kitLines.removeAt(index).dispose();
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _slugCtrl.dispose();
    _descCtrl.dispose();
    _categoryCtrl.dispose();
    _priceCtrl.removeListener(_onPricingFieldsChanged);
    _salePriceCtrl.removeListener(_onPricingFieldsChanged);
    _priceCtrl.dispose();
    _salePriceCtrl.dispose();
    for (final line in _kitLines) {
      line.dispose();
    }
    super.dispose();
  }

  List<ProductItem> _collectItems() {
    final out = <ProductItem>[];
    final seen = <String>{};
    for (final line in _kitLines) {
      if (line.inventoryItemId.isEmpty) continue;
      final qty = num.tryParse(line.quantityCtrl.text.trim());
      if (qty == null || qty <= 0) continue;
      if (!seen.add(line.inventoryItemId)) continue;
      out.add(ProductItem(inventoryItem: line.inventoryItemId, quantity: qty));
    }
    return out;
  }

  List<InventoryItem> get _pickerOptions {
    final ids = <String>{};
    final list = <InventoryItem>[];
    for (final i in _invCtrl.pickerItems) {
      if (ids.add(i.id)) list.add(i);
    }
    for (final line in _kitLines) {
      if (line.inventoryItemId.isEmpty) continue;
      if (ids.contains(line.inventoryItemId)) continue;
      ProductItem? fromProduct;
      for (final e in widget.product?.items ?? const <ProductItem>[]) {
        if (e.inventoryItem == line.inventoryItemId) {
          fromProduct = e;
          break;
        }
      }
      if (fromProduct != null) {
        ids.add(line.inventoryItemId);
        list.add(
          InventoryItem(
            id: line.inventoryItemId,
            name: fromProduct.inventoryName ?? line.inventoryItemId,
            slug: '',
            category: '',
            unit: fromProduct.inventoryUnit ?? '',
            itemQuantity: fromProduct.inventoryItemQuantity ?? 1,
            stockQuantity: 0,
            lowStockThreshold: 0,
            status: 'ACTIVE',
            price: fromProduct.inventoryPrice ?? 0,
            salePrice: fromProduct.inventorySalePrice,
            currency: fromProduct.inventoryCurrency ?? _currency,
          ),
        );
      }
    }
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final slug = _slugCtrl.text.trim();
    final priceText = _priceCtrl.text.trim();
    if (!_isEdit && slug.isEmpty) _syncSlug();
    final resolvedSlug = _isEdit
        ? (widget.product!.slug.isNotEmpty
            ? widget.product!.slug
            : ProductController.slugify(title))
        : (slug.isNotEmpty ? slug : ProductController.slugify(title));
    if (title.isEmpty || resolvedSlug.isEmpty || priceText.isEmpty) {
      showCmsSnackbar(
        title: 'Required',
        message: 'Title and price are required.',
        isError: true,
      );
      return;
    }
    final price = num.tryParse(priceText);
    if (price == null) {
      showCmsSnackbar(
        title: 'Invalid price',
        message: 'Enter a valid number for price.',
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

    final dupId = _duplicateInventoryId();
    if (dupId != null) {
      final dupName = _inventoryForId(dupId)?.name ?? dupId;
      showCmsSnackbar(
        title: 'Duplicate component',
        message:
            'Each inventory item can only be added once per kit. '
            'Remove the duplicate "$dupName" line.',
        isError: true,
      );
      return;
    }

    final items = _collectItems();
    if (items.isEmpty) {
      showCmsSnackbar(
        title: 'Kit lines required',
        message:
            'Add at least one inventory item with units per kit (quantity > 0).',
        isError: true,
      );
      return;
    }

    bool ok;
    if (_isEdit) {
      ok = await widget.ctrl.updateProduct(
        id: widget.product!.id,
        title: title,
        slug: resolvedSlug,
        description: _descCtrl.text.trim(),
        items: items,
        price: price,
        salePrice: salePrice,
        clearSalePrice: salePriceText.isEmpty,
        currency: _currency,
        category: _categoryCtrl.text.trim(),
        isFeatured: _isFeatured,
        image: _image,
      );
    } else {
      ok = await widget.ctrl.createProduct(
        title: title,
        slug: resolvedSlug,
        description: _descCtrl.text.trim(),
        items: items,
        price: price,
        salePrice: salePrice,
        currency: _currency,
        category: _categoryCtrl.text.trim(),
        status: _reviewStatus,
        productStatus: _productStatus,
        isFeatured: _isFeatured,
        image: _image,
      );
    }
    if (ok) widget.onSaved();
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
            _formHeader(),
            const SizedBox(height: 20),
            if (isWeb)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: CmsFormCard(
                      title: 'Basic details',
                      children: [
                        CmsFormField(
                          label: 'Title *',
                          hint: 'e.g. Ganesh Puja Kit',
                          controller: _titleCtrl,
                        ),
                        const SizedBox(height: 12),
                        CmsFormField(
                          label: 'Description',
                          hint: 'Complete Ganesh pooja essentials kit',
                          controller: _descCtrl,
                          maxLines: 3,
                        ),
                        // const SizedBox(height: 12),
                        // CmsFormField(
                        //   label: 'Category',
                        //   hint: 'e.g. Ganesh',
                        //   controller: _categoryCtrl,
                        // ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CmsFormCard(
                      title: 'Product image',
                      children: [
                        CmsUploadBox(
                          label:
                              _isEdit ? 'Product Image' : 'Product Image ',
                          icon: Icons.image_outlined,
                          accept: 'JPG, PNG up to 5MB',
                          mediaType: PickMediaType.image,
                          initialUrl: widget.product?.imageUrl,
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
                title: 'Basic details',
                children: [
                  CmsFormField(
                    label: 'Title *',
                    hint: 'e.g. Ganesh Puja Kit',
                    controller: _titleCtrl,
                  ),
                  const SizedBox(height: 12),
                  CmsFormField(
                    label: 'Description',
                    hint: 'Complete Ganesh pooja essentials kit',
                    controller: _descCtrl,
                    maxLines: 3,
                  ),
                  // const SizedBox(height: 12),
                  // CmsFormField(
                  //   label: 'Category',
                  //   hint: 'e.g. Ganesh',
                  //   controller: _categoryCtrl,
                  // ),
                ],
              ),
              const SizedBox(height: 16),
              CmsFormCard(
                title: 'Product image',
                children: [
                  CmsUploadBox(
                    label: _isEdit ? 'Product Image' : 'Product Image *',
                    icon: Icons.image_outlined,
                    accept: 'JPG, PNG up to 5MB',
                    mediaType: PickMediaType.image,
                    initialUrl: widget.product?.imageUrl,
                    onPicked: (f) => setState(() => _image = f),
                    onRemoved: () => setState(() => _image = null),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),

            CmsFormCard(
              title: 'Kit components (inventory)',
              children: [
                const Text(
                  'Pick warehouse items and how many stock units each kit '
                  'consumes (packs, not grams).',
                  style: TextStyle(fontSize: 12, color: CmsColors.textSecond),
                ),
                const SizedBox(height: 12),
                Obx(() {
                  if (_invCtrl.isPickerLoading && _pickerOptions.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: CmsColors.orange,
                          ),
                        ),
                      ),
                    );
                  }
                  if (_pickerOptions.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text(
                        'No active inventory items. Add stock under '
                        'Manage Inventory first.',
                        style: TextStyle(
                          fontSize: 12,
                          color: CmsColors.textSecond,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }),
                ..._kitLines.asMap().entries.map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _KitInventoryLineRow(
                          line: e.value,
                          inventoryOptions: _pickerOptions,
                          usedInventoryIds: _usedInventoryIdsExcept(e.key),
                          canRemove: _kitLines.length > 1,
                          onRemove: () => _removeKitLine(e.key),
                          onInventoryChanged: (id) =>
                              _onInventoryItemSelected(e.key, id),
                        ),
                      ),
                    ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _canAddKitLine ? _addKitLine : null,
                    icon: const Icon(
                      Icons.add,
                      size: 16,
                      color: CmsColors.orange,
                    ),
                    label: const Text(
                      'Add component',
                      style: TextStyle(
                        color: CmsColors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            CmsFormCard(
              title: 'Kit pricing',
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: _Labeled(
                        label: 'Currency',
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: CmsColors.bg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: CmsColors.border),
                          ),
                          child: Text(
                            _currency,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: CmsColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: CmsFormField(
                        label: 'Kit MRP *',
                        hint: '999',
                        controller: _priceCtrl,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: CmsFormField(
                        label: 'Sale price',
                        hint: '799',
                        controller: _salePriceCtrl,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _KitComponentsCostSummary(
                  cost: _componentsCost(),
                  kitPriceText: _priceCtrl.text.trim(),
                  kitSalePriceText: _salePriceCtrl.text.trim(),
                  onApplyInventoryPrices: _applyInventoryPricesToKit,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Kit price uses inventory MRP prices; kit sale price uses '
                  'inventory sale prices when any component is on sale.',
                  style: TextStyle(fontSize: 11, color: CmsColors.textSecond),
                ),
                const SizedBox(height: 16),
                _buildFeaturedToggle(),
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
                            _isEdit ? 'Save Changes' : 'Create Puja Kit',
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
      );
    });
  }

  Widget _buildFeaturedToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: CmsColors.bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CmsColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.star_outline, size: 18, color: CmsColors.orange),
          const SizedBox(width: 10),
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
                  'Show this kit in featured listings on the app home.',
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

  Widget _formHeader() => Row(
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
            _isEdit ? 'Edit Puja Kit' : 'Add Puja Kit',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: CmsColors.textPrimary,
            ),
          ),
        ],
      );
}

/// Units per kit with − / + controls and white input background.
class _KitUnitsStepper extends StatelessWidget {
  const _KitUnitsStepper({required this.line});

  final _KitLineEditor line;

  int _currentQty() {
    final parsed = num.tryParse(line.quantityCtrl.text.trim());
    if (parsed == null || parsed < 1) return 1;
    return parsed.round();
  }

  void _setQty(int value) {
    final next = value < 1 ? 1 : value;
    line.quantityCtrl.text = next.toString();
  }

  void _adjust(int delta) => _setQty(_currentQty() + delta);

  @override
  Widget build(BuildContext context) {
    return _Labeled(
      label: 'Units / kit *',
      child: Container(
        decoration: BoxDecoration(
          color: CmsColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: CmsColors.border),
        ),
        child: Row(
          children: [
            _KitQtyIconButton(
              icon: Icons.remove,
              tooltip: 'Decrease units',
              onPressed: _currentQty() > 1 ? () => _adjust(-1) : null,
            ),
            Expanded(
              child: TextFormField(
                controller: line.quantityCtrl,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: CmsColors.textPrimary,
                ),
                decoration: const InputDecoration(
                  hintText: '1',
                  hintStyle: TextStyle(
                    color: Color(0xFFAAAAAA),
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: CmsColors.white,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                onChanged: (_) {
                  final raw = line.quantityCtrl.text.trim();
                  if (raw.isEmpty) return;
                  final parsed = int.tryParse(raw);
                  if (parsed != null && parsed < 1) {
                    _setQty(1);
                  }
                },
              ),
            ),
            _KitQtyIconButton(
              icon: Icons.add,
              tooltip: 'Increase units',
              onPressed: () => _adjust(1),
            ),
          ],
        ),
      ),
    );
  }
}

class _KitQtyIconButton extends StatelessWidget {
  const _KitQtyIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 40,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        icon: Icon(
          icon,
          size: 18,
          color: onPressed == null
              ? CmsColors.textSecond.withOpacity(0.4)
              : CmsColors.orange,
        ),
      ),
    );
  }
}

// ── Kit BOM line: inventory picker + units per kit ──
class _KitInventoryLineRow extends StatelessWidget {
  const _KitInventoryLineRow({
    required this.line,
    required this.inventoryOptions,
    required this.usedInventoryIds,
    required this.canRemove,
    required this.onRemove,
    required this.onInventoryChanged,
  });

  final _KitLineEditor line;
  final List<InventoryItem> inventoryOptions;
  final Set<String> usedInventoryIds;
  final bool canRemove;
  final VoidCallback onRemove;
  final ValueChanged<String> onInventoryChanged;

  @override
  Widget build(BuildContext context) {
    final selected = line.inventoryItemId;

    InventoryItem? inv;
    if (selected.isNotEmpty) {
      for (final i in inventoryOptions) {
        if (i.id == selected) {
          inv = i;
          break;
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: CmsColors.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CmsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: _Labeled(
                  label: 'Inventory item *',
                  child: _InventoryPickerField(
                    value: selected,
                    items: inventoryOptions,
                    usedInventoryIds: usedInventoryIds,
                    onChanged: onInventoryChanged,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _KitUnitsStepper(line: line),
              ),
              if (canRemove) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(top: 22),
                  child: IconButton(
                    tooltip: 'Remove line',
                    onPressed: onRemove,
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (inv != null) ...[
            const SizedBox(height: 6),
            Text(
              '${inv.itemSizeLabel} · ${inv.stockQuantity} in stock',
              style: const TextStyle(
                fontSize: 11,
                color: CmsColors.textSecond,
              ),
            ),
            const SizedBox(height: 4),
            _KitLinePriceInfo(inv: inv, line: line),
          ],
        ],
      ),
    );
  }
}

/// Tap field → searchable dialog with list + sale prices per row.
class _InventoryPickerField extends StatelessWidget {
  const _InventoryPickerField({
    required this.value,
    required this.items,
    required this.usedInventoryIds,
    required this.onChanged,
  });

  final String value;
  final List<InventoryItem> items;
  final Set<String> usedInventoryIds;
  final ValueChanged<String> onChanged;

  InventoryItem? get _selected {
    if (value.isEmpty) return null;
    for (final i in items) {
      if (i.id == value) return i;
    }
    return null;
  }

  Future<void> _openPicker(BuildContext context) async {
    final id = await showDialog<String>(
      context: context,
      builder: (ctx) => _InventoryPickerDialog(
        items: items,
        selectedId: value.isNotEmpty ? value : null,
        usedInventoryIds: usedInventoryIds,
      ),
    );
    if (id != null) onChanged(id);
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: CmsColors.bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: CmsColors.border),
        ),
        child: const Text(
          'No inventory',
          style: TextStyle(fontSize: 12, color: CmsColors.textSecond),
        ),
      );
    }

    final selected = _selected;
    return Material(
      color: CmsColors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => _openPicker(context),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: CmsColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: selected == null
                    ? const Text(
                        'Select inventory item',
                        style: TextStyle(
                          fontSize: 13,
                          color: CmsColors.textSecond,
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selected.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: CmsColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          _InventoryListSalePrices(inv: selected, compact: true),
                        ],
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
    );
  }
}

class _InventoryPickerDialog extends StatefulWidget {
  const _InventoryPickerDialog({
    required this.items,
    required this.usedInventoryIds,
    this.selectedId,
  });

  final List<InventoryItem> items;
  final Set<String> usedInventoryIds;
  final String? selectedId;

  @override
  State<_InventoryPickerDialog> createState() => _InventoryPickerDialogState();
}

class _InventoryPickerDialogState extends State<_InventoryPickerDialog> {
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

  List<InventoryItem> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.items;
    return widget.items.where((i) {
      return i.name.toLowerCase().contains(q) ||
          i.category.toLowerCase().contains(q) ||
          i.slug.toLowerCase().contains(q) ||
          i.unit.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Select inventory item',
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
                  hintText: 'Search by name, category, unit…',
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
                        'No items match your search.',
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
                        final item = filtered[index];
                        final isSelected = item.id == widget.selectedId;
                        final alreadyInKit =
                            widget.usedInventoryIds.contains(item.id);
                        return InkWell(
                          onTap: () {
                            if (alreadyInKit) {
                              showCmsSnackbar(
                                title: 'Item already added',
                                message:
                                    '"${item.name}" is already in this kit.',
                                isError: true,
                              );
                              return;
                            }
                            Navigator.pop(context, item.id);
                          },
                          child: Container(
                            color: isSelected
                                ? CmsColors.orange.withOpacity(0.06)
                                : alreadyInKit
                                    ? CmsColors.bg
                                    : null,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected
                                              ? CmsColors.orange
                                              : alreadyInKit
                                                  ? CmsColors.textSecond
                                                  : CmsColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        alreadyInKit
                                            ? 'Already in kit'
                                            : '${item.itemSizeLabel} · ${item.stockQuantity} in stock',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: CmsColors.textSecond,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                _InventoryListSalePrices(inv: item),
                                if (isSelected) ...[
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.check_circle,
                                    size: 18,
                                    color: CmsColors.orange,
                                  ),
                                ],
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

/// List price (struck through when on sale) + sale price label.
class _InventoryListSalePrices extends StatelessWidget {
  const _InventoryListSalePrices({
    required this.inv,
    this.compact = false,
  });

  final InventoryItem inv;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final onSale = _inventoryHasSale(inv);
    final listStyle = TextStyle(
      fontSize: compact ? 11 : 12,
      fontWeight: compact ? FontWeight.w500 : FontWeight.w600,
      color: onSale ? CmsColors.textSecond : CmsColors.textPrimary,
      decoration: onSale ? TextDecoration.lineThrough : null,
    );
    final saleStyle = TextStyle(
      fontSize: compact ? 11 : 12,
      fontWeight: FontWeight.w700,
      color: CmsColors.orange,
    );

    if (!onSale) {
      return Text(
        _kitMoney(inv.price, inv.currency),
        style: listStyle.copyWith(decoration: null),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_kitMoney(inv.price, inv.currency), style: listStyle),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 4 : 6),
          child: Text(
            '→',
            style: TextStyle(
              fontSize: compact ? 10 : 11,
              color: CmsColors.textSecond,
            ),
          ),
        ),
        Text(_kitMoney(inv.salePrice!, inv.currency), style: saleStyle),
      ],
    );
  }
}

class _KitLinePriceInfo extends StatelessWidget {
  const _KitLinePriceInfo({required this.inv, required this.line});

  final InventoryItem inv;
  final _KitLineEditor line;

  @override
  Widget build(BuildContext context) {
    final qty = num.tryParse(line.quantityCtrl.text.trim()) ?? 0;
    final onSale = _inventoryHasSale(inv);
    final listLine = qty > 0 ? inv.price * qty : 0.0;
    final saleLine = qty > 0 && onSale ? inv.salePrice! * qty : listLine;

    const labelStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: CmsColors.textSecond,
    );
    const valueStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: CmsColors.textPrimary,
    );

    if (qty <= 0) {
      return Text.rich(
        TextSpan(
          children: [
            const TextSpan(text: 'Total Item Price: ', style: labelStyle),
            const TextSpan(text: '—', style: valueStyle),
          ],
        ),
      );
    }

    if (onSale) {
      return Text.rich(
        TextSpan(
          children: [
            const TextSpan(text: 'Total Item Price: ', style: labelStyle),
            TextSpan(
              text: _kitMoney(saleLine, inv.currency),
              style: valueStyle.copyWith(color: CmsColors.orange),
            ),
            const TextSpan(text: ' / ', style: labelStyle),
            TextSpan(
              text: _kitMoney(listLine, inv.currency),
              style: valueStyle.copyWith(
                color: CmsColors.textSecond,
                decoration: TextDecoration.lineThrough,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Text.rich(
      TextSpan(
        children: [
          const TextSpan(text: 'Total Item Price: ', style: labelStyle),
          TextSpan(
            text: _kitMoney(listLine, inv.currency),
            style: valueStyle,
          ),
        ],
      ),
    );
  }
}

class _KitComponentsCostSummary extends StatelessWidget {
  const _KitComponentsCostSummary({
    required this.cost,
    required this.kitPriceText,
    required this.kitSalePriceText,
    required this.onApplyInventoryPrices,
  });

  final _KitComponentsCost cost;
  final String kitPriceText;
  final String kitSalePriceText;
  final VoidCallback onApplyInventoryPrices;

  @override
  Widget build(BuildContext context) {
    if (!cost.hasLines) {
      return const Text(
        'Add kit components to see inventory price totals.',
        style: TextStyle(fontSize: 11, color: CmsColors.textSecond),
      );
    }

    final kitPrice = num.tryParse(kitPriceText);
    final kitSale = num.tryParse(kitSalePriceText);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F0),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CmsColors.orange.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _costRow(
            label: 'Kit components total (MRP)',
            value: _kitMoney(cost.listTotal, cost.currency),
            valueColor: CmsColors.orangeDark,
          ),
          if (cost.hasInventorySale) ...[
            const SizedBox(height: 6),
            _costRow(
              label: 'Kit components total (sale price)',
              value: _kitMoney(cost.saleTotal, cost.currency),
              valueColor: const Color(0xFF2E7D32),
            ),
          ],
          if (cost.skippedOtherCurrency > 0) ...[
            const SizedBox(height: 6),
            Text(
              '${cost.skippedOtherCurrency} line(s) skipped — currency does not '
              'match ${cost.currency}.',
              style: const TextStyle(fontSize: 10, color: CmsColors.textSecond),
            ),
          ],
          if (kitPrice != null && kitPrice > 0) ...[
            const SizedBox(height: 8),
            _costRow(
              label: 'Kit MRP entered',
              value: _kitMoney(kitPrice, cost.currency),
            ),
          ],
          if (kitSale != null && kitSale > 0) ...[
            const SizedBox(height: 4),
            _costRow(
              label: 'Kit sale price entered',
              value: _kitMoney(kitSale, cost.currency),
            ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: cost.listTotal > 0 ? onApplyInventoryPrices : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: CmsColors.orangeDark,
                side: const BorderSide(color: CmsColors.orange),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              icon: const Icon(Icons.price_check_outlined, size: 18),
              label: Text(
                cost.hasInventorySale
                    ? 'Use inventory prices for kit & sale price'
                    : 'Use inventory prices for kit price',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _costRow({
    required String label,
    required String value,
    Color valueColor = CmsColors.textPrimary,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, color: CmsColors.textSecond),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

// ── Tiny helpers (kept local to avoid leaking into shared widgets) ──
class _Labeled extends StatelessWidget {
  const _Labeled({required this.label, required this.child});
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

// NOTE: CmsPoojaKitOrdersContent / CmsPoojaKitRefundsContent /
// CmsPoojaKitPaymentsContent live in their own files now and are wired into
// the sidebar by `cms_shell_page.dart`. See:
//   • lib/features/cms/presentation/contents/cms_pooja_kit_orders_content.dart
//   • lib/features/cms/presentation/contents/cms_pooja_kit_refunds_content.dart
//   • lib/features/cms/presentation/contents/cms_pooja_kit_payments_content.dart
