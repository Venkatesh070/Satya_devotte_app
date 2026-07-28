// Pooja Kit → Orders tab content for the CMS.
//
// Drives `AdminOrdersController` from a single screen with two modes:
//   • LIST   — paginated table/cards with orderStatus + paymentStatus +
//              search filters and a page-size selector.
//   • DETAIL — once a row is opened the same surface flips to an order
//              detail view with summary / line items / shipping / tracking
//              / invoice / fulfilment, plus contextual admin actions:
//              Mark Processing, Add Tracking, Dispatch, Mark Delivered,
//              Cancel order, and Verify (PayFast) by reference.
//
// Mirrors the section structure described in
// `Flutter-cms-refund&orders&payments.plan` §4.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:satya_devotte_app/core/routing/cms_route_paths.dart';
import 'package:satya_devotte_app/core/utils/cms_search_scheduler.dart';
import 'package:satya_devotte_app/features/cms/data/models/admin_order_models.dart';
import 'package:satya_devotte_app/features/cms/presentation/controllers/admin_orders_controller.dart';
import 'package:satya_devotte_app/features/cms/presentation/pages/cms_shell_page.dart';
import 'package:satya_devotte_app/features/cms/presentation/widgets/cms_shared_widgets.dart';


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

Widget _cmsClickableInk({
  required VoidCallback? onTap,
  required Widget child,
  BorderRadius? borderRadius,
}) {
  return MouseRegion(
    cursor: onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
    child: InkWell(
      onTap: onTap,
      borderRadius: borderRadius,
      child: child,
    ),
  );
}

Widget _cmsClickableOptional({
  required VoidCallback? onTap,
  required Widget child,
}) {
  return MouseRegion(
    cursor: onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
    child: GestureDetector(
      onTap: onTap,
      child: child,
    ),
  );
}

const _cmsButtonClickCursor = WidgetStatePropertyAll<MouseCursor>(
  SystemMouseCursors.click,
);

class CmsPoojaKitOrdersContent extends StatelessWidget {
  const CmsPoojaKitOrdersContent({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<AdminOrdersController>();
    // First open of this tab triggers a fetch. Subsequent re-mounts keep
    // whatever page/filter state the controller already holds.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (c.items.isEmpty && !c.isLoading && c.error == null) {
        c.refresh();
      }
      if (kIsWeb) {
        final fragment = Uri.base.fragment;
        if (fragment.isNotEmpty) {
          final route =
              fragment.startsWith('/') ? fragment : '/$fragment';
          final orderId = CmsRoutePaths.poojaKitOrderIdFromRoute(route);
          if (orderId != null && c.selectedOrderId != orderId) {
            c.openOrder(orderId, syncUrl: false);
          }
        }
      }
    });
    return Obx(() {
      if (c.selectedOrderId != null) {
        return _OrderDetailView(controller: c);
      }
      return _OrdersListView(controller: c);
    });
  }
}

// ════════════════════════════════════════════════════════════════
// LIST
// ════════════════════════════════════════════════════════════════
class _OrdersListView extends StatelessWidget {
  const _OrdersListView({required this.controller});
  final AdminOrdersController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // const CmsPoojaKitSectionHeader(
        //   title: 'Orders',
        //   subtitle:
        //       'Track and manage devotee orders for Pooja Kits. Filter by '
        //       'status, search by order number and drill in to dispatch.',
        // ),
        const Divider(height: 1, color: CmsColors.border),
        _OrdersFiltersBar(controller: controller),
        const Divider(height: 1, color: CmsColors.border),
        Expanded(child: _OrdersBody(controller: controller)),
        Obx(() {
          final showPager = controller.total > 0 ||
              controller.items.isNotEmpty;
          if (!showPager) return const SizedBox.shrink();
          return Material(
            color: CmsColors.white,
            child: Container(
              decoration: BoxDecoration(
                color: CmsColors.white,
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
                child: _OrdersPaginationBar(controller: controller),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _OrdersFiltersBar extends StatefulWidget {
  const _OrdersFiltersBar({required this.controller});
  final AdminOrdersController controller;

  @override
  State<_OrdersFiltersBar> createState() => _OrdersFiltersBarState();
}

class _OrdersFiltersBarState extends State<_OrdersFiltersBar> {
  late final TextEditingController _search;
  late final CmsSearchScheduler _searchScheduler;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(text: widget.controller.search);
    _searchScheduler = CmsSearchScheduler(
      onSearch: widget.controller.setSearch,
    );
  }

  @override
  void dispose() {
    _searchScheduler.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width >= 900;
    return Container(
      color: CmsColors.white,
      padding: EdgeInsets.symmetric(
        horizontal: isWeb ? 24 : 16,
        vertical: 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(
            () => _ChipRow(
              label: 'Order status',
              options: AdminOrdersController.orderStatusFilters,
              selected: widget.controller.orderStatus,
              onSelect: widget.controller.setOrderStatusFilter,
            ),
          ),
          const SizedBox(height: 8),
          Obx(
            () => _ChipRow(
              label: 'Payment',
              options: AdminOrdersController.paymentStatusFilters,
              selected: widget.controller.paymentStatus,
              onSelect: widget.controller.setPaymentStatusFilter,
              optionLabel: paymentStatusWireChipLabel,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    controller: _search,
                    onSubmitted: _searchScheduler.searchNow,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search by order number…',
                      hintStyle: const TextStyle(
                        color: Color(0xFFAAAAAA),
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: Color(0xFFAAAAAA),
                      ),
                      suffixIcon: _search.text.isEmpty
                          ? null
                          : IconButton(
                              style: IconButton.styleFrom().copyWith(
                                mouseCursor: _cmsButtonClickCursor,
                              ),
                              icon: const Icon(Icons.close, size: 16),
                              onPressed: () {
                                _search.clear();
                                _searchScheduler.searchNow('');
                                setState(() {});
                              },
                            ),
                      filled: true,
                      fillColor: CmsColors.bg,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 10),
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
                    onChanged: (v) {
                      setState(() {});
                      _searchScheduler.onQueryChanged(v);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Obx(
                () => IconButton(
                  tooltip: 'Reload',
                  style: IconButton.styleFrom().copyWith(
                    mouseCursor: _cmsButtonClickCursor,
                  ),
                  onPressed: widget.controller.isLoading
                      ? null
                      : widget.controller.refresh,
                  icon: widget.controller.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: CmsColors.orange,
                          ),
                        )
                      : const Icon(
                          Icons.refresh,
                          size: 20,
                          color: CmsColors.textSecond,
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelect,
    this.optionLabel,
  });
  final String label;
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelect;
  /// When set, maps each [options] wire to chip text (e.g. payment filters).
  final String Function(String wire)? optionLabel;

  @override
  Widget build(BuildContext context) {
    String labelFor(String wire) =>
        optionLabel != null ? optionLabel!(wire) : _prettyChip(wire);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: CmsColors.textSecond,
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final opt in options) ...[
                  _FilterChip(
                    label: labelFor(opt),
                    selected: opt == selected,
                    onTap: () => onSelect(opt),
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  static String _prettyChip(String wire) {
    if (wire == 'ALL') return 'All';
    return wire[0] + wire.substring(1).toLowerCase();
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
    return _cmsClickableOptional(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color:
              selected ? CmsColors.orange : CmsColors.orange.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? CmsColors.orange : CmsColors.orange.withOpacity(0.35),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: selected ? Color(0xFFFCF7EF) : CmsColors.orangeDark,
          ),
        ),
      ),
    );
  }
}

class _OrdersBody extends StatelessWidget {
  const _OrdersBody({required this.controller});
  final AdminOrdersController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading && controller.items.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.error != null && controller.items.isEmpty) {
        return _ErrorBox(
          message: controller.error!,
          onRetry: controller.refresh,
        );
      }
      if (!controller.isLoading && controller.isEmpty) {
        return const CmsEmptyState(
          icon: Icons.receipt_long_outlined,
          title: 'No Orders Yet',
          subtitle:
              'When devotees place a Pooja Kit order it will show up here.',
        );
      }
      final wide = MediaQuery.of(context).size.width >= 1000;
      return wide
          ? _OrdersTable(orders: controller.items, controller: controller)
          : _OrdersCardList(orders: controller.items, controller: controller);
    });
  }
}

class _OrdersTable extends StatelessWidget {
  const _OrdersTable({required this.orders, required this.controller});
  final List<AdminOrder> orders;
  final AdminOrdersController controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: CmsColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: CmsColors.border),
              ),
              child: Column(
                children: [
                  const _TableHeader(
                    columns: [
                      _ColSpec('Order #', width: 160),
                      _ColSpec('Customer', flex: 1),
                      _ColSpec('Subtotal', width: 88),
                      _ColSpec('Delivery', width: 88),
                      _ColSpec('Total', width: 88),
                      _ColSpec('Payment', width: 92),
                      _ColSpec('Status', width: 100),
                      _ColSpec('Date', width: 152),
                      _ColSpec('', width: 56),
                    ],
                  ),
                  const Divider(height: 1, color: CmsColors.border),
                  for (final o in orders)
                    _cmsClickableInk(
                      onTap: () => controller.openOrder(o.id),
                      child: _OrderRow(order: o),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Line 1: calendar date. Line 2: local time and timezone name.
class CmsKitOrderDateCell extends StatelessWidget {
  const CmsKitOrderDateCell({
    super.key,
    required this.at,
    this.textAlign = TextAlign.start,
  });

  final DateTime? at;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    if (at == null) {
      return Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          '—',
          textAlign: textAlign,
          style: const TextStyle(fontSize: 12, color: CmsColors.textSecond),
        ),
      );
    }
    final dt = at!.toLocal();
    final dateStr = DateFormat('d MMM yyyy').format(dt);
    final timeStr = DateFormat('h:mm a').format(dt);
    final tzName = dt.timeZoneName;
    final cross = textAlign == TextAlign.end
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Column(
        crossAxisAlignment: cross,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            dateStr,
            textAlign: textAlign,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: CmsColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$timeStr · $tzName',
            textAlign: textAlign,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.5,
              height: 1.25,
              color: CmsColors.textSecond,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.order});
  final AdminOrder order;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: CmsColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                order.orderNumber.isEmpty ? '—' : order.orderNumber,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: CmsColors.textPrimary,
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2, right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.userName.isEmpty ? '—' : order.userName,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: CmsColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (order.userEmail.isNotEmpty)
                    Text(
                      order.userEmail,
                      style: const TextStyle(
                        fontSize: 11,
                        color: CmsColors.textSecond,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: 88,
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: _OrderPriceCell(value: order.formattedSubtotal),
            ),
          ),
          SizedBox(
            width: 88,
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: _OrderPriceCell(value: order.formattedShipping),
            ),
          ),
          SizedBox(
            width: 88,
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: _OrderPriceCell(value: order.formattedTotal, bold: true),
            ),
          ),
          SizedBox(
            width: 92,
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Align(
                alignment: Alignment.centerLeft,
                child: PaymentStatusBadge(status: order.paymentStatus),
              ),
            ),
          ),
          SizedBox(
            width: 100,
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Align(
                alignment: Alignment.centerLeft,
                child: OrderStatusBadge(status: order.orderStatus),
              ),
            ),
          ),
          SizedBox(
            width: 152,
            child: CmsKitOrderDateCell(at: order.createdAt),
          ),
          SizedBox(
            width: 56,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: CmsColors.textSecond,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrdersCardList extends StatelessWidget {
  const _OrdersCardList({required this.orders, required this.controller});
  final List<AdminOrder> orders;
  final AdminOrdersController controller;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final o = orders[i];
        return _cmsClickableInk(
          borderRadius: BorderRadius.circular(12),
          onTap: () => controller.openOrder(o.id),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CmsColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CmsColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        o.orderNumber.isEmpty ? '—' : o.orderNumber,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: CmsColors.textPrimary,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        alignment: WrapAlignment.end,
                        children: [
                          PaymentStatusBadge(status: o.paymentStatus),
                          OrderStatusBadge(status: o.orderStatus),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${o.userName.isEmpty ? '—' : o.userName} · ${o.userEmail}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: CmsColors.textSecond,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                _OrderPriceBreakdownLines(order: o),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: CmsKitOrderDateCell(at: o.createdAt, textAlign: TextAlign.end),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OrdersPaginationBar extends StatelessWidget {
  const _OrdersPaginationBar({required this.controller});
  final AdminOrdersController controller;

  static const _pageSizes = [10, 20, 50, 100];

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isWide = MediaQuery.of(context).size.width >= 768;
      final page = controller.page;
      final size = controller.limit;
      final tp = controller.totalPages;
      final totalRows = controller.total;
      final start = totalRows == 0 ? 0 : (page - 1) * size + 1;
      final end = (page * size).clamp(0, totalRows);

      final left = <Widget>[
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
              value: _pageSizes.contains(size) ? size : _pageSizes[1],
              isDense: true,
              style: const TextStyle(
                fontSize: 12,
                color: CmsColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              items: _pageSizes
                  .map((s) => DropdownMenuItem(value: s, child: Text('$s')))
                  .toList(),
              onChanged: (v) {
                if (v != null) controller.setLimit(v);
              },
            ),
          ),
        ),
      ];

      final pager = <Widget>[
        _OrdersPagerBtnMini(
          icon: Icons.chevron_left,
          enabled: page > 1,
          onTap: controller.prevPage,
        ),
        for (final n in _ordersPageRange(page, tp))
          n == -1
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    '…',
                    style: TextStyle(color: CmsColors.textSecond),
                  ),
                )
              : _OrdersPageNumberBtnMini(
                  number: n,
                  isActive: n == page,
                  onTap: () => controller.goToPage(n),
                ),
        _OrdersPagerBtnMini(
          icon: Icons.chevron_right,
          enabled: page < tp,
          onTap: controller.nextPage,
        ),
      ];

      if (isWide) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: CmsColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CmsColors.border),
            ),
            child: Row(
              children: [
                ...left,
                const Spacer(),
                ...pager.map(
                  (w) => Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: w,
                  ),
                ),
              ],
            ),
          ),
        );
      }
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Container(
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
                children: left,
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
        ),
      );
    });
  }
}

List<int> _ordersPageRange(int current, int total) {
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

class _OrdersPagerBtnMini extends StatelessWidget {
  const _OrdersPagerBtnMini({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
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
        ),
      );
}

class _OrdersPageNumberBtnMini extends StatelessWidget {
  const _OrdersPageNumberBtnMini({
    required this.number,
    required this.isActive,
    required this.onTap,
  });
  final int number;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _cmsClickable(
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
              color: isActive ? Color(0xFFFCF7EF) : CmsColors.textPrimary,
            ),
          ),
        ),
      );
}

// ════════════════════════════════════════════════════════════════
// DETAIL
// ════════════════════════════════════════════════════════════════
class _OrderDetailView extends StatelessWidget {
  const _OrderDetailView({required this.controller});
  final AdminOrdersController controller;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) controller.closeDetail();
      },
      child: Obx(() {
        final order = controller.detail;
        return Column(
          children: [
            _DetailHeader(controller: controller, order: order),
            const Divider(height: 1, color: CmsColors.border),
            Expanded(
              child: () {
                if (controller.detailLoading && order == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (controller.detailError != null && order == null) {
                  return _ErrorBox(
                    message: controller.detailError!,
                    onRetry: controller.fetchDetail,
                  );
                }
                if (order == null) {
                  return const CmsEmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'Order not found',
                    subtitle: 'This order may have been removed.',
                  );
                }
                return _OrderDetailBody(controller: controller, order: order);
              }(),
            ),
          ],
        );
      }),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.controller, required this.order});
  final AdminOrdersController controller;
  final AdminOrder? order;

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width >= 768;
    final title = order?.orderNumber.isNotEmpty == true
        ? 'Order ${order!.orderNumber}'
        : 'Order details';
    return Container(
      color: CmsColors.white,
      padding: EdgeInsets.symmetric(
        horizontal: isWeb ? 24 : 16,
        vertical: 12,
      ),
      child: Row(
        children: [
          IconButton(
            style: IconButton.styleFrom().copyWith(
              mouseCursor: _cmsButtonClickCursor,
            ),
            tooltip: 'Back to orders',
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: controller.closeDetail,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: CmsColors.textPrimary,
                  ),
                ),
                if (order != null)
                  Text(
                    order!.formattedDateTime,
                    style: const TextStyle(
                      fontSize: 12,
                      color: CmsColors.textSecond,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            style: IconButton.styleFrom().copyWith(
              mouseCursor: _cmsButtonClickCursor,
            ),
            tooltip: 'Refresh',
            onPressed: controller.fetchDetail,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }
}

class _OrderDetailBody extends StatelessWidget {
  const _OrderDetailBody({required this.controller, required this.order});
  final AdminOrdersController controller;
  final AdminOrder order;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummaryCard(order: order),
          const SizedBox(height: 14),
          _LineItemsCard(order: order),
          const SizedBox(height: 14),
          _OrderTotalsCard(order: order),
          const SizedBox(height: 14),
          _ShippingCard(order: order),
          const SizedBox(height: 14),
          if (order.isPaymentPaid) ...[
            _TrackingCard(controller: controller, order: order),
            const SizedBox(height: 14),
          ],
          _InvoiceCard(order: order),
          const SizedBox(height: 14),
          _FulfillmentCard(order: order),
          const SizedBox(height: 20),
          _ActionBar(controller: controller, order: order),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.order});
  final AdminOrder order;

  @override
  Widget build(BuildContext context) {
    return CmsFormCard(
      title: 'Summary',
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _MetaPair(
                label: 'Order #',
                value: order.orderNumber.isEmpty ? '—' : order.orderNumber,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _MetaPair(label: 'Currency', value: order.currency),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _MetaPair(
                label: 'Method',
                value: order.paymentMethod.isEmpty ? '—' : order.paymentMethod,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _MetaPair(
                label: 'Payment',
                value: order.paymentStatus.label,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _MetaPair(
          label: 'Reference',
          value: (order.payfastPaymentId ?? '').trim().isEmpty
              ? '—'
              : order.payfastPaymentId!,
        ),
        const SizedBox(height: 12),
        _MetaPair(
          label: 'Customer',
          value: order.userName.isEmpty
              ? (order.userEmail.isEmpty ? '—' : order.userEmail)
              : '${order.userName}\n${order.userEmail}',
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            OrderStatusBadge(status: order.orderStatus),
            const SizedBox(width: 8),
            PaymentStatusBadge(status: order.paymentStatus),
            if (order.inventoryReserved) ...[
              const SizedBox(width: 8),
              const _MutedPill(text: 'Inventory reserved'),
            ],
          ],
        ),
      ],
    );
  }
}

class _LineItemsCard extends StatelessWidget {
  const _LineItemsCard({required this.order});
  final AdminOrder order;

  @override
  Widget build(BuildContext context) {
    final items = order.items;
    return CmsFormCard(
      title: 'Items (${items.length})',
      children: [
        if (items.isEmpty)
          const Text(
            'No items on this order.',
            style: TextStyle(fontSize: 12, color: CmsColors.textSecond),
          )
        else
          for (var i = 0; i < items.length; i++) ...[
            _LineItemRow(item: items[i], currency: order.currency),
            if (i != items.length - 1)
              const Divider(height: 16, color: CmsColors.border),
          ],
      ],
    );
  }
}

class _OrderTotalsCard extends StatelessWidget {
  const _OrderTotalsCard({required this.order});
  final AdminOrder order;

  @override
  Widget build(BuildContext context) {
    return CmsFormCard(
      title: 'Amounts',
      children: [
        _OrderAmountRow(label: 'Subtotal', value: order.formattedSubtotal),
        const SizedBox(height: 8),
        _OrderAmountRow(
          label: 'Delivery charges',
          value: order.formattedShipping,
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Divider(height: 1, color: CmsColors.border),
        ),
        _OrderAmountRow(
          label: 'Total',
          value: order.formattedTotal,
          bold: true,
        ),
      ],
    );
  }
}

class _OrderPriceBreakdownLines extends StatelessWidget {
  const _OrderPriceBreakdownLines({required this.order});
  final AdminOrder order;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _OrderAmountRow(
          label: 'Subtotal',
          value: order.formattedSubtotal,
          compact: true,
        ),
        const SizedBox(height: 4),
        _OrderAmountRow(
          label: 'Delivery',
          value: order.formattedShipping,
          compact: true,
        ),
        const SizedBox(height: 4),
        _OrderAmountRow(
          label: 'Total',
          value: order.formattedTotal,
          compact: true,
          bold: true,
        ),
      ],
    );
  }
}

class _OrderPriceCell extends StatelessWidget {
  const _OrderPriceCell({required this.value, this.bold = false});
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: TextStyle(
        fontSize: 12.5,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
        color: CmsColors.textPrimary,
      ),
    );
  }
}

class _OrderAmountRow extends StatelessWidget {
  const _OrderAmountRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.compact = false,
  });
  final String label;
  final String value;
  final bool bold;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: compact ? 11.5 : 12,
              fontWeight: FontWeight.w500,
              color: CmsColors.textSecond,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: compact ? 12 : 13,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
            color: CmsColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _LineItemRow extends StatelessWidget {
  const _LineItemRow({required this.item, required this.currency});
  final OrderLineItem item;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            width: 44,
            height: 44,
            child: item.image.isNotEmpty
                ? Image.network(
                    item.image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _ItemPlaceholder(),
                  )
                : _ItemPlaceholder(),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title.isEmpty ? '—' : item.title,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: CmsColors.textPrimary,
                ),
              ),
              Text(
                'Qty ${item.qty}  ·  Unit ${_money(item.unitPrice, currency)}',
                style: const TextStyle(
                  fontSize: 11.5,
                  color: CmsColors.textSecond,
                ),
              ),
            ],
          ),
        ),
        Text(
          _money(item.lineTotal, currency),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: CmsColors.textPrimary,
          ),
        ),
      ],
    );
  }

  String _money(double v, String c) {
    final symbol = c == 'ZAR' ? 'R' : c;
    final decimals = v.truncateToDouble() == v ? 0 : 2;
    return '$symbol ${v.toStringAsFixed(decimals)}';
  }
}

class _ItemPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: CmsColors.bg,
      child: const Icon(
        Icons.image_outlined,
        size: 20,
        color: CmsColors.textSecond,
      ),
    );
  }
}

class _ShippingCard extends StatelessWidget {
  const _ShippingCard({required this.order});
  final AdminOrder order;

  @override
  Widget build(BuildContext context) {
    final addr = order.shippingAddress;
    return CmsFormCard(
      title: 'Shipping',
      children: [
        if (addr == null)
          const Text(
            'No shipping address attached.',
            style: TextStyle(fontSize: 12, color: CmsColors.textSecond),
          )
        else ...[
          if (addr.name.isNotEmpty) _AddrLine(text: addr.name, bold: true),
          if (addr.line1.isNotEmpty) _AddrLine(text: addr.line1),
          if (addr.line2.isNotEmpty) _AddrLine(text: addr.line2),
          _AddrLine(
            text: [
              if (addr.city.isNotEmpty) addr.city,
              if (addr.region.isNotEmpty) addr.region,
              if (addr.postalCode.isNotEmpty) addr.postalCode,
            ].join(', '),
          ),
          if (addr.country.isNotEmpty) _AddrLine(text: addr.country),
          if (addr.phone.isNotEmpty)
            _AddrLine(text: 'Phone: ${addr.phone}', muted: true),
          if (addr.email.isNotEmpty)
            _AddrLine(text: 'Email: ${addr.email}', muted: true),
        ],
      ],
    );
  }
}

class _AddrLine extends StatelessWidget {
  const _AddrLine({required this.text, this.bold = false, this.muted = false});
  final String text;
  final bool bold;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          color: muted ? CmsColors.textSecond : CmsColors.textPrimary,
        ),
      ),
    );
  }
}

class _TrackingCard extends StatelessWidget {
  const _TrackingCard({required this.controller, required this.order});
  final AdminOrdersController controller;
  final AdminOrder order;

  @override
  Widget build(BuildContext context) {
    final t = order.tracking;
    return CmsFormCard(
      title: 'Tracking',
      children: [
        if (t == null || !t.hasTrackingNumber) ...[
          const Text(
            'No tracking number set. Add tracking before you mark the order '
            'as Shipped, or use Dispatch to do both in one step.',
            style: TextStyle(fontSize: 12, color: CmsColors.textSecond),
          ),
        ] else ...[
          _MetaPair(label: 'Courier', value: t.courier.isEmpty ? '—' : t.courier),
          const SizedBox(height: 4),
          _MetaPair(label: 'Tracking #', value: t.trackingNumber),
          if (t.trackingUrl.isNotEmpty) ...[
            const SizedBox(height: 4),
            _cmsClickableInk(
              onTap: () => _openUrl(t.trackingUrl),
              child: Text(
                t.trackingUrl,
                style: const TextStyle(
                  fontSize: 12,
                  color: CmsColors.orange,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
          if (order.dispatchedAt != null) ...[
            const SizedBox(height: 6),
            _MetaPair(
              label: 'Dispatched',
              value: order.dispatchedAt.toString(),
            ),
          ],
          if (order.sharedWithUserAt != null) ...[
            const SizedBox(height: 4),
            _MetaPair(
              label: 'Shared with user',
              value: order.sharedWithUserAt.toString(),
            ),
          ],
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            CmsPrimaryButton(
              label: t == null || !t.hasTrackingNumber
                  ? 'Add tracking'
                  : 'Edit tracking',
              icon: Icons.local_shipping_outlined,
              onTap: () => _showTrackingDialog(context, controller, t),
            ),
          ],
        ),
      ],
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard({required this.order});
  final AdminOrder order;

  @override
  Widget build(BuildContext context) {
    final inv = order.invoice;
    if (inv == null || inv.url.isEmpty) {
      return const SizedBox.shrink();
    }
    return CmsFormCard(
      title: 'Invoice',
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (inv.number.isNotEmpty)
                    Text(
                      'Invoice #${inv.number}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: CmsColors.textPrimary,
                      ),
                    ),
                  if (inv.generatedAt != null)
                    Text(
                      inv.generatedAt!.toLocal().toString(),
                      style: const TextStyle(
                        fontSize: 11,
                        color: CmsColors.textSecond,
                      ),
                    ),
                ],
              ),
            ),
            CmsPrimaryButton(
              label: 'Open invoice',
              icon: Icons.open_in_new_rounded,
              onTap: () => _openUrl(inv.url),
            ),
          ],
        ),
      ],
    );
  }
}

class _FulfillmentCard extends StatelessWidget {
  const _FulfillmentCard({required this.order});
  final AdminOrder order;

  @override
  Widget build(BuildContext context) {
    final f = order.fulfillment;
    if (f == null) return const SizedBox.shrink();
    return CmsFormCard(
      title: 'Fulfilment',
      children: [
        if (f.satisfied != null)
          _MetaPair(
            label: 'Satisfied',
            value: f.satisfied! ? 'Yes' : 'No',
          ),
        if (f.ratedAt != null)
          _MetaPair(
            label: 'Rated at',
            value: f.ratedAt!.toLocal().toString(),
          ),
        if (f.feedback.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            'Feedback: ${f.feedback}',
            style: const TextStyle(fontSize: 12, color: CmsColors.textPrimary),
          ),
        ],
      ],
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.controller, required this.order});
  final AdminOrdersController controller;
  final AdminOrder order;

  @override
  Widget build(BuildContext context) {
    final nextStates = OrderStatusMachine.nextAllowed(
      order.orderStatus,
      hasTrackingNumber: order.hasTracking,
    );
    final canCancel = OrderStatusMachine.canAdminCancel(order.orderStatus);
    final canFulfil = order.isPaymentPaid;
    return Obx(
      () {
        final busy = controller.mutating;
        final children = <Widget>[];
        if (canFulfil && nextStates.contains(OrderStatus.processing)) {
          children.add(
            CmsPrimaryButton(
              label: 'Mark processing',
              icon: Icons.play_arrow_rounded,
              isLoading: busy,
              onTap: () => controller.markStatus(OrderStatus.processing),
            ),
          );
        }
        if (canFulfil &&
            (nextStates.contains(OrderStatus.shipped) ||
                order.orderStatus == OrderStatus.processing)) {
          children.add(
            CmsPrimaryButton(
              label: 'Dispatch',
              icon: Icons.local_shipping_rounded,
              isLoading: busy,
              onTap: () => _showDispatchDialog(context, controller, order.tracking),
            ),
          );
        }
        if (canFulfil && nextStates.contains(OrderStatus.delivered)) {
          children.add(
            CmsPrimaryButton(
              label: 'Mark delivered',
              icon: Icons.check_circle_outline_rounded,
              isLoading: busy,
              onTap: () => controller.markStatus(OrderStatus.delivered),
            ),
          );
        }
        if (canCancel) {
          children.add(
            _OutlinedAction(
              label: 'Cancel order',
              icon: Icons.cancel_outlined,
              color: CmsColors.red,
              onTap: busy ? null : () => _showCancelDialog(context, controller),
            ),
          );
        }
        if (order.canInitiateRefund) {
          children.add(
            _OutlinedAction(
              label: 'Initiate Refund',
              icon: Icons.currency_exchange_rounded,
              color: const Color(0xFF6A1B9A),
              onTap: busy
                  ? null
                  : () => _showInitiateRefundDialog(context, controller),
            ),
          );
        }
        if (order.paymentReference.isNotEmpty) {
          children.add(
            _OutlinedAction(
              label: 'Verify payment',
              icon: Icons.refresh_rounded,
              color: CmsColors.orangeDark,
              onTap:
                  busy ? null : () => controller.verifyPayment(order.paymentReference),
            ),
          );
        }
        if (children.isEmpty) {
          return const Text(
            'No admin actions available for this order in its current state.',
            style: TextStyle(fontSize: 12, color: CmsColors.textSecond),
          );
        }
        return Wrap(spacing: 10, runSpacing: 10, children: children);
      },
    );
  }
}

class _OutlinedAction extends StatelessWidget {
  const _OutlinedAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _cmsClickableOptional(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: onTap == null ? color.withOpacity(0.05) : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── dialogs ────────────────────────────────────────────────────────
Future<void> _showTrackingDialog(
  BuildContext context,
  AdminOrdersController controller,
  Tracking? current,
) async {
  final courier = TextEditingController(text: current?.courier ?? '');
  final number = TextEditingController(text: current?.trackingNumber ?? '');
  final url = TextEditingController(text: current?.trackingUrl ?? '');
  final markShipped = ValueNotifier<bool>(false);

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (innerContext, setState) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            title: const Text(
              'Save tracking',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: CmsColors.textPrimary,
              ),
            ),
            content: SizedBox(
              width: 380,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CmsFormField(
                    label: 'Courier',
                    hint: 'e.g. DHL, Aramex, Postnet',
                    controller: courier,
                  ),
                  const SizedBox(height: 8),
                  CmsFormField(
                    label: 'Tracking number',
                    hint: 'e.g. AB123456789ZA',
                    controller: number,
                  ),
                  const SizedBox(height: 8),
                  CmsFormField(
                    label: 'Tracking URL (optional)',
                    hint: 'https://…',
                    controller: url,
                  ),
                  const SizedBox(height: 8),
                  ValueListenableBuilder<bool>(
                    valueListenable: markShipped,
                    builder: (_, v, __) => Row(
                      children: [
                        Checkbox(
                          value: v,
                          activeColor: CmsColors.orange,
                          onChanged: (val) =>
                              markShipped.value = val ?? false,
                        ),
                        const Expanded(
                          child: Text(
                            'Also mark as SHIPPED (dispatch)',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: CmsColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: CmsColors.textSecond),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: CmsColors.orange,
                  foregroundColor: Color(0xFFFCF7EF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ).copyWith(mouseCursor: _cmsButtonClickCursor),
                onPressed: () async {
                  final c = courier.text.trim();
                  final n = number.text.trim();
                  if (c.isEmpty || n.isEmpty) return;
                  Navigator.pop(dialogContext);
                  if (markShipped.value) {
                    await controller.dispatch(
                      courier: c,
                      trackingNumber: n,
                      trackingUrl: url.text.trim().isEmpty
                          ? null
                          : url.text.trim(),
                    );
                  } else {
                    await controller.saveTracking(
                      courier: c,
                      trackingNumber: n,
                      trackingUrl: url.text.trim().isEmpty
                          ? null
                          : url.text.trim(),
                    );
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<void> _showDispatchDialog(
  BuildContext context,
  AdminOrdersController controller,
  Tracking? current,
) async {
  final courier = TextEditingController(text: current?.courier ?? '');
  final number = TextEditingController(text: current?.trackingNumber ?? '');
  final url = TextEditingController(text: current?.trackingUrl ?? '');
  final note = TextEditingController();

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          'Dispatch order',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: CmsColors.textPrimary,
          ),
        ),
        content: SizedBox(
          width: 380,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Saves tracking and marks the order SHIPPED. The customer '
                  'will receive a shipping notification email.',
                  style: TextStyle(fontSize: 12, color: CmsColors.textSecond),
                ),
                const SizedBox(height: 10),
                CmsFormField(
                  label: 'Courier',
                  hint: 'e.g. DHL, Aramex, Postnet',
                  controller: courier,
                ),
                const SizedBox(height: 8),
                CmsFormField(
                  label: 'Tracking number',
                  hint: 'e.g. AB123456789ZA',
                  controller: number,
                ),
                const SizedBox(height: 8),
                CmsFormField(
                  label: 'Tracking URL (optional)',
                  hint: 'https://…',
                  controller: url,
                ),
                const SizedBox(height: 8),
                CmsFormField(
                  label: 'Note (optional)',
                  hint: 'Internal dispatch note',
                  controller: note,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Cancel',
              style: TextStyle(color: CmsColors.textSecond),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: CmsColors.orange,
              foregroundColor: Color(0xFFFCF7EF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ).copyWith(mouseCursor: _cmsButtonClickCursor),
            onPressed: () async {
              final c = courier.text.trim();
              final n = number.text.trim();
              if (c.isEmpty || n.isEmpty) return;
              Navigator.pop(dialogContext);
              await controller.dispatch(
                courier: c,
                trackingNumber: n,
                trackingUrl: url.text.trim().isEmpty ? null : url.text.trim(),
                note: note.text.trim().isEmpty ? null : note.text.trim(),
              );
            },
            child: const Text('Dispatch'),
          ),
        ],
      );
    },
  );
}

Future<void> _showInitiateRefundDialog(
  BuildContext context,
  AdminOrdersController controller,
) async {
  final reason = TextEditingController();
  final adminNote = TextEditingController();
  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          'Initiate Refund',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF6A1B9A),
          ),
        ),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Available after the order is marked Delivered. Initiates a refund '
                'on this order. Process the actual payout in PayFast when required.',
                style: TextStyle(fontSize: 12, color: CmsColors.textSecond),
              ),
              const SizedBox(height: 10),
              CmsFormField(
                label: 'Reason',
                hint: 'e.g. Customer reported damaged items',
                controller: reason,
                maxLines: 3,
              ),
              const SizedBox(height: 10),
              CmsFormField(
                label: 'Admin note',
                hint: 'e.g. Refund approved by support',
                controller: adminNote,
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Cancel',
              style: TextStyle(color: CmsColors.textSecond),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A1B9A),
              foregroundColor: Color(0xFFFCF7EF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ).copyWith(mouseCursor: _cmsButtonClickCursor),
            onPressed: () async {
              final reasonText = reason.text.trim();
              if (reasonText.isEmpty) return;
              Navigator.pop(dialogContext);
              await controller.initiateRefund(
                reason: reasonText,
                adminNote: adminNote.text.trim().isEmpty
                    ? null
                    : adminNote.text.trim(),
              );
            },
            child: const Text('Initiate Refund'),
          ),
        ],
      );
    },
  ).whenComplete(() {
    reason.dispose();
    adminNote.dispose();
  });
}

Future<void> _showCancelDialog(
  BuildContext context,
  AdminOrdersController controller,
) async {
  final reason = TextEditingController();
  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          'Cancel order',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: CmsColors.red,
          ),
        ),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Cancels the order and restocks inventory. If the order was '
                'already PAID, payment is marked REFUNDED. This cannot be '
                'undone.',
                style: TextStyle(fontSize: 12, color: CmsColors.textSecond),
              ),
              const SizedBox(height: 10),
              CmsFormField(
                label: 'Reason (optional)',
                hint: 'Why is this order being cancelled?',
                controller: reason,
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Keep order',
              style: TextStyle(color: CmsColors.textSecond),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: CmsColors.red,
              foregroundColor: Color(0xFFFCF7EF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ).copyWith(mouseCursor: _cmsButtonClickCursor),
            onPressed: () async {
              Navigator.pop(dialogContext);
              await controller.cancelOrder(
                reason: reason.text.trim().isEmpty
                    ? null
                    : reason.text.trim(),
              );
            },
            child: const Text('Cancel order'),
          ),
        ],
      );
    },
  );
}

// ── small shared widgets ───────────────────────────────────────────
class _TableHeader extends StatelessWidget {
  const _TableHeader({required this.columns});
  final List<_ColSpec> columns;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: CmsColors.bg,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          for (final col in columns) _TableHeaderCell(spec: col),
        ],
      ),
    );
  }
}

class _TableHeaderCell extends StatelessWidget {
  const _TableHeaderCell({required this.spec});
  final _ColSpec spec;

  @override
  Widget build(BuildContext context) {
    final label = Text(
      spec.label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: CmsColors.textSecond,
        letterSpacing: 0.2,
      ),
    );
    if (spec.flex != null) {
      return Expanded(
        flex: spec.flex!,
        child: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: label,
        ),
      );
    }
    return SizedBox(width: spec.width, child: label);
  }
}

class _ColSpec {
  const _ColSpec(this.label, {this.width, this.flex});
  final String label;
  final double? width;
  final int? flex;
}

class _MetaPair extends StatelessWidget {
  const _MetaPair({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: CmsColors.textSecond,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 2),
        SelectableText(
          value,
          style: const TextStyle(
            fontSize: 12.5,
            color: CmsColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _MutedPill extends StatelessWidget {
  const _MutedPill({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFEFEFEF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CmsColors.border),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: CmsColors.textSecond,
        ),
      ),
    );
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
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: CmsColors.textPrimary,
              ),
            ),
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

// ── Status badges ──────────────────────────────────────────────────
class OrderStatusBadge extends StatelessWidget {
  const OrderStatusBadge({super.key, required this.status});
  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final c = _color(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withOpacity(0.35)),
      ),
      child: Text(
        status.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: c,
        ),
      ),
    );
  }

  static Color _color(OrderStatus s) {
    switch (s) {
      case OrderStatus.placed:
        return const Color(0xFF1976D2);
      case OrderStatus.processing:
        return CmsColors.orangeDark;
      case OrderStatus.shipped:
        return const Color(0xFF6A1B9A);
      case OrderStatus.delivered:
        return CmsColors.green;
      case OrderStatus.fulfilled:
        return const Color(0xFF2E7D32);
      case OrderStatus.cancelled:
        return CmsColors.red;
      case OrderStatus.unknown:
        return Colors.grey;
    }
  }
}

class PaymentStatusBadge extends StatelessWidget {
  const PaymentStatusBadge({super.key, required this.status});
  final PaymentStatus status;

  @override
  Widget build(BuildContext context) {
    final c = _color(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withOpacity(0.35)),
      ),
      child: Text(
        status.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: c,
        ),
      ),
    );
  }

  static Color _color(PaymentStatus s) {
    switch (s) {
      case PaymentStatus.paid:
        return CmsColors.green;
      case PaymentStatus.pending:
        return CmsColors.orange;
      case PaymentStatus.failed:
        return CmsColors.red;
      case PaymentStatus.refunded:
        return const Color(0xFF6A1B9A);
      case PaymentStatus.refundInitiated:
        return CmsColors.orange;
      case PaymentStatus.refundFailed:
        return CmsColors.red;
      case PaymentStatus.unknown:
        return Colors.grey;
    }
  }
}

Future<void> _openUrl(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    // Best-effort; swallow.
  }
}
