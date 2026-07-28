// Pooja Kit → Payments tab content for the CMS.
//
// Uses `GET /payments/all` (not orders/all) with payment-status filters:
//   • Default `paymentStatus` filter chip set: ALL / PAID / PENDING / FAILED /
//     REFUNDED.
//   • Each row exposes a "Verify now" action that calls
//     `GET /payments/verify/:reference` and refreshes the row in-place.
//   • Search by order number or payment reference (server-side `search`).

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:satya_devotte_app/core/utils/cms_search_scheduler.dart';
import 'package:satya_devotte_app/features/cms/data/models/admin_order_models.dart';
import 'package:satya_devotte_app/features/cms/presentation/contents/cms_pooja_kit_orders_content.dart'
    show CmsKitOrderDateCell, PaymentStatusBadge;
import 'package:satya_devotte_app/features/cms/presentation/controllers/admin_payments_controller.dart';
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

class CmsPoojaKitPaymentsContent extends StatelessWidget {
  const CmsPoojaKitPaymentsContent({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<AdminPaymentsController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (c.items.isEmpty && !c.isLoading && c.error == null) {
        c.refresh();
      }
    });
    return Column(
      children: [
        CmsPoojaKitSectionHeader(
          title: 'Payments',
          subtitle:
              'Inspect PayFast transactions tied to Puja Kit orders. Use '
              '“Verify now” to pull the latest status straight from PayFast.',
        ),
        const Divider(height: 1, color: CmsColors.border),
        _FiltersBar(controller: c),
        const Divider(height: 1, color: CmsColors.border),
        Expanded(child: _Body(controller: c)),
        Obx(() {
          final showPager =
              c.total > 0 || c.items.isNotEmpty;
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
                child: _PaymentsPaginationBar(controller: c),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _FiltersBar extends StatefulWidget {
  const _FiltersBar({required this.controller});
  final AdminPaymentsController controller;

  @override
  State<_FiltersBar> createState() => _FiltersBarState();
}

class _FiltersBarState extends State<_FiltersBar> {
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
            () => Row(
              children: [
                const SizedBox(
                  width: 92,
                  child: Text(
                    'Payment',
                    style: TextStyle(
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
                        for (final opt in AdminPaymentsController.filters) ...[
                          _Pill(
                            label: paymentStatusWireChipLabel(opt),
                            selected: opt == widget.controller.filter,
                            onTap: () => widget.controller.setFilter(opt),
                          ),
                          const SizedBox(width: 6),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
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
                      hintText: 'Search by order number or reference…',
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

class _Pill extends StatelessWidget {
  const _Pill({
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
          color: selected
              ? CmsColors.orange
              : CmsColors.orange.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? CmsColors.orange
                : CmsColors.orange.withOpacity(0.35),
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

class _Body extends StatelessWidget {
  const _Body({required this.controller});
  final AdminPaymentsController controller;

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
          icon: Icons.payments_outlined,
          title: 'No Payments Yet',
          subtitle:
              'Once a devotee completes a payment for a Puja Kit order, it '
              'will appear here with its payment reference and status.',
        );
      }
      final wide = MediaQuery.of(context).size.width >= 1000;
      return wide
          ? _PaymentsTable(controller: controller)
          : _PaymentsCards(controller: controller);
    });
  }
}

class _PaymentsTable extends StatelessWidget {
  const _PaymentsTable({required this.controller});
  final AdminPaymentsController controller;

  @override
  Widget build(BuildContext context) {
    final items = controller.items;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Container(
        decoration: BoxDecoration(
          color: CmsColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CmsColors.border),
        ),
        child: Column(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: CmsColors.bg,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: const [
                  SizedBox(
                    width: 160,
                    child: _Hdr(label: 'Order #'),
                  ),
                  SizedBox(width: 200, child: _Hdr(label: 'Customer')),
                  SizedBox(width: 110, child: _Hdr(label: 'Total')),
                  SizedBox(width: 92, child: _Hdr(label: 'Status')),
                  Expanded(child: _Hdr(label: 'Payment reference')),
                  SizedBox(width: 152, child: _Hdr(label: 'Date')),
                  SizedBox(width: 130, child: _Hdr(label: '')),
                ],
              ),
            ),
            const Divider(height: 1, color: CmsColors.border),
            for (final o in items) _PaymentRow(order: o, controller: controller),
          ],
        ),
      ),
    );
  }
}

class _Hdr extends StatelessWidget {
  const _Hdr({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: CmsColors.textSecond,
        letterSpacing: 0.2,
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.order, required this.controller});
  final AdminOrder order;
  final AdminPaymentsController controller;

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
          SizedBox(
            width: 200,
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
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
            width: 110,
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                order.formattedTotal,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: CmsColors.textPrimary,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 92,
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 88),
                  child: PaymentStatusBadge(status: order.paymentStatus),
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: SelectableText(
                (order.payfastPaymentId ?? '').trim().isEmpty
                    ? '—'
                    : order.payfastPaymentId!,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontFamily: 'monospace',
                  color: CmsColors.textPrimary,
                ),
                maxLines: 2,
              ),
            ),
          ),
          SizedBox(
            width: 152,
            child: CmsKitOrderDateCell(at: order.createdAt),
          ),
          SizedBox(
            width: 130,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: _VerifyButton(order: order, controller: controller),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentsCards extends StatelessWidget {
  const _PaymentsCards({required this.controller});
  final AdminPaymentsController controller;

  @override
  Widget build(BuildContext context) {
    final items = controller.items;
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final o = items[i];
        return Container(
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
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 88),
                      child: PaymentStatusBadge(status: o.paymentStatus),
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
              SelectableText(
                'Ref: ${(o.payfastPaymentId ?? '').trim().isEmpty ? '—' : o.payfastPaymentId!}',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontFamily: 'monospace',
                  color: CmsColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      o.formattedTotal,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: CmsColors.textPrimary,
                      ),
                    ),
                  ),
                  CmsKitOrderDateCell(at: o.createdAt, textAlign: TextAlign.end),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: _VerifyButton(order: o, controller: controller),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _VerifyButton extends StatelessWidget {
  const _VerifyButton({required this.order, required this.controller});
  final AdminOrder order;
  final AdminPaymentsController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final busy = controller.isVerifying(order.id);
      final hasRef = order.paymentReference.trim().isNotEmpty;
      return _cmsClickableOptional(
        onTap: (busy || !hasRef)
            ? null
            : () => controller.verifyByReference(order),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: hasRef
                ? CmsColors.orangeDark.withOpacity(0.10)
                : Colors.grey.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hasRef
                  ? CmsColors.orangeDark.withOpacity(0.35)
                  : Colors.grey.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (busy)
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.6,
                    valueColor: AlwaysStoppedAnimation(CmsColors.orangeDark),
                  ),
                )
              else
                Icon(
                  Icons.refresh_rounded,
                  size: 14,
                  color: hasRef ? CmsColors.orangeDark : Colors.grey,
                ),
              const SizedBox(width: 6),
              Text(
                busy ? 'Verifying…' : 'Verify now',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: hasRef ? CmsColors.orangeDark : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _PaymentsPaginationBar extends StatelessWidget {
  const _PaymentsPaginationBar({required this.controller});
  final AdminPaymentsController controller;

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
        _PaymentsPagerBtnMini(
          icon: Icons.chevron_left,
          enabled: page > 1,
          onTap: controller.prevPage,
        ),
        for (final n in _paymentsPageRange(page, tp))
          n == -1
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    '…',
                    style: TextStyle(color: CmsColors.textSecond),
                  ),
                )
              : _PaymentsPageNumberBtnMini(
                  number: n,
                  isActive: n == page,
                  onTap: () => controller.goToPage(n),
                ),
        _PaymentsPagerBtnMini(
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

List<int> _paymentsPageRange(int current, int total) {
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

class _PaymentsPagerBtnMini extends StatelessWidget {
  const _PaymentsPagerBtnMini({
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

class _PaymentsPageNumberBtnMini extends StatelessWidget {
  const _PaymentsPageNumberBtnMini({
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
