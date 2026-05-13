// Pooja Kit → Payments tab content for the CMS.
//
// Shares the same `GET /orders/all` endpoint as the Orders tab but views the
// data through a payment-status lens:
//   • Default `paymentStatus` filter chip set: ALL / PAID / PENDING / FAILED /
//     REFUNDED.
//   • Each row exposes a "Verify now" action that calls
//     `GET /payments/verify/:reference` and refreshes the row in-place.
//   • Search by order number (server-side `search`).

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:satya_devotte_app/features/cms/data/models/admin_order_models.dart';
import 'package:satya_devotte_app/features/cms/presentation/contents/cms_pooja_kit_orders_content.dart'
    show PaymentStatusBadge;
import 'package:satya_devotte_app/features/cms/presentation/controllers/admin_payments_controller.dart';
import 'package:satya_devotte_app/features/cms/presentation/pages/cms_shell_page.dart';
import 'package:satya_devotte_app/features/cms/presentation/widgets/cms_shared_widgets.dart';

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
          title: 'Pooja Kit Payments',
          subtitle:
              'Inspect Paystack transactions tied to Pooja Kit orders. Use '
              '“Verify now” to pull the latest status straight from Paystack.',
          trailing: IconButton(
            tooltip: 'Refresh',
            onPressed: c.refresh,
            icon: const Icon(
              Icons.refresh_rounded,
              color: CmsColors.textPrimary,
            ),
          ),
        ),
        const Divider(height: 1, color: CmsColors.border),
        _FiltersBar(controller: c),
        const Divider(height: 1, color: CmsColors.border),
        Expanded(child: _Body(controller: c)),
        _PaginationBar(controller: c),
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

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(text: widget.controller.search);
  }

  @override
  void dispose() {
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
                            label: opt == 'ALL'
                                ? 'All'
                                : opt[0] + opt.substring(1).toLowerCase(),
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
                    onSubmitted: widget.controller.setSearch,
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
                              icon: const Icon(Icons.close, size: 16),
                              onPressed: () {
                                _search.clear();
                                widget.controller.setSearch('');
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
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _PageSizeDropdown(controller: widget.controller),
            ],
          ),
        ],
      ),
    );
  }
}

class _PageSizeDropdown extends StatelessWidget {
  const _PageSizeDropdown({required this.controller});
  final AdminPaymentsController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: CmsColors.bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: CmsColors.border),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: controller.limit,
            isDense: true,
            items: const [10, 20, 50]
                .map(
                  (e) => DropdownMenuItem<int>(
                    value: e,
                    child: Text(
                      '$e / page',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) controller.setLimit(v);
            },
          ),
        ),
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
    return GestureDetector(
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
            color: selected ? Colors.white : CmsColors.orangeDark,
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
      if (controller.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.error != null) {
        return _ErrorBox(
          message: controller.error!,
          onRetry: controller.refresh,
        );
      }
      if (controller.isEmpty) {
        return const CmsEmptyState(
          icon: Icons.payments_outlined,
          title: 'No Payments Yet',
          subtitle:
              'Once a devotee completes a payment for a Pooja Kit order, it '
              'will appear here with its Paystack reference and status.',
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
                  SizedBox(width: 110, child: _Hdr(label: 'Status')),
                  Expanded(child: _Hdr(label: 'Paystack reference')),
                  SizedBox(width: 130, child: _Hdr(label: 'Date')),
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              order.orderNumber.isEmpty ? '—' : order.orderNumber,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: CmsColors.textPrimary,
              ),
            ),
          ),
          SizedBox(
            width: 200,
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
          SizedBox(
            width: 110,
            child: Text(
              order.formattedTotal,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: CmsColors.textPrimary,
              ),
            ),
          ),
          SizedBox(
            width: 110,
            child: PaymentStatusBadge(status: order.paymentStatus),
          ),
          Expanded(
            child: SelectableText(
              order.paystackReference.isEmpty ? '—' : order.paystackReference,
              style: const TextStyle(
                fontSize: 11.5,
                fontFamily: 'monospace',
                color: CmsColors.textPrimary,
              ),
              maxLines: 2,
            ),
          ),
          SizedBox(
            width: 130,
            child: Text(
              order.formattedDate,
              style: const TextStyle(
                fontSize: 12,
                color: CmsColors.textSecond,
              ),
            ),
          ),
          SizedBox(
            width: 130,
            child: _VerifyButton(order: order, controller: controller),
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
                  PaymentStatusBadge(status: o.paymentStatus),
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
                'Ref: ${o.paystackReference.isEmpty ? '—' : o.paystackReference}',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontFamily: 'monospace',
                  color: CmsColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    o.formattedTotal,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: CmsColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  _VerifyButton(order: o, controller: controller),
                ],
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
      final hasRef = order.paystackReference.trim().isNotEmpty;
      return GestureDetector(
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

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({required this.controller});
  final AdminPaymentsController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.items.isEmpty || controller.isLoading) {
        return const SizedBox.shrink();
      }
      return Container(
        color: CmsColors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Row(
          children: [
            Text(
              'Page ${controller.page} of ${controller.totalPages} · '
              '${controller.total} payment${controller.total == 1 ? '' : 's'}',
              style: const TextStyle(
                fontSize: 12,
                color: CmsColors.textSecond,
              ),
            ),
            const Spacer(),
            IconButton(
              tooltip: 'Previous',
              onPressed: controller.page > 1 ? controller.prevPage : null,
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            IconButton(
              tooltip: 'Next',
              onPressed: controller.page < controller.totalPages
                  ? controller.nextPage
                  : null,
              icon: const Icon(Icons.chevron_right_rounded),
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
