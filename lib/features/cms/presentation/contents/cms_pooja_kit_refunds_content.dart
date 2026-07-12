// Pooja Kit → Replace Requests tab content for the CMS.
//
// Surfaces `GET /admin/replacements` for devotee replacement requests. The flow:
//   • LIST   — paginated requests with status (default PENDING) + type filters.
//   • DETAIL — request summary, reason, attachments, related order,
//              replacement order link (if any), Approve / Reject with
//              optional adminNote.
//
// Mirrors the section structure described in
// `Flutter-cms-refund&orders&payments.plan` §2.5 + §4.3 + §4.4.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:satya_devotte_app/core/utils/cms_search_scheduler.dart';
import 'package:satya_devotte_app/features/cms/data/models/admin_order_request_models.dart';
import 'package:satya_devotte_app/features/cms/presentation/contents/cms_pooja_kit_orders_content.dart'
    show CmsKitOrderDateCell, OrderStatusBadge, PaymentStatusBadge;
import 'package:satya_devotte_app/features/cms/presentation/controllers/admin_order_requests_controller.dart';
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

class CmsPoojaKitRefundsContent extends StatelessWidget {
  const CmsPoojaKitRefundsContent({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<AdminOrderRequestsController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!c.isLoading) c.refresh();
    });
    return Obx(() {
      if (c.selectedId != null) {
        return _RequestDetailView(controller: c);
      }
      return _RequestsListView(controller: c);
    });
  }
}

// ════════════════════════════════════════════════════════════════
// LIST
// ════════════════════════════════════════════════════════════════
class _RequestsListView extends StatelessWidget {
  const _RequestsListView({required this.controller});
  final AdminOrderRequestsController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CmsPoojaKitSectionHeader(
          title: 'Replace Requests',
          subtitle:
              'Review replacement requests from devotees. Approve to create a '
              'linked replacement order, or reject with a note.',
        ),
        const Divider(height: 1, color: CmsColors.border),
        _FiltersBar(controller: controller),
        const Divider(height: 1, color: CmsColors.border),
        Expanded(child: _RequestsBody(controller: controller)),
        _PaginationBar(controller: controller),
      ],
    );
  }
}

class _FiltersBar extends StatefulWidget {
  const _FiltersBar({required this.controller});
  final AdminOrderRequestsController controller;

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
            () => _Pills(
              label: 'Status',
              options: AdminOrderRequestsController.statusFilters,
              selected: widget.controller.status,
              onSelect: widget.controller.setStatusFilter,
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

class _Pills extends StatelessWidget {
  const _Pills({
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelect,
  });
  final String label;
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 64,
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
                  _Pill(
                    label: replacementRequestStatusFilterLabel(opt),
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

class _RequestsBody extends StatelessWidget {
  const _RequestsBody({required this.controller});
  final AdminOrderRequestsController controller;

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
          icon: Icons.assignment_return_outlined,
          title: 'No replacement requests',
          subtitle:
              'When a devotee submits a replacement request it will appear '
              'here for review.',
        );
      }
      return _ReplacementsTable(
        requests: controller.items,
        controller: controller,
      );
    });
  }
}

/// Column layout shared by header and data rows (flex = share of width).
const _kReplacementTableColumns = <_ReqColSpec>[
  _ReqColSpec('Request #', flex: 14),
  _ReqColSpec('Order #', flex: 12),
  _ReqColSpec('Customer', flex: 18),
  _ReqColSpec('Reason', flex: 22),
  _ReqColSpec('Status', flex: 10),
  _ReqColSpec('Date', flex: 14),
];

class _ReplacementsTable extends StatelessWidget {
  const _ReplacementsTable({
    required this.requests,
    required this.controller,
  });
  final List<OrderRequest> requests;
  final AdminOrderRequestsController controller;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: CmsColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CmsColors.border),
        ),
        child: Column(
          children: [
            const _ReqTableHeader(columns: _kReplacementTableColumns),
            const Divider(height: 1, color: CmsColors.border),
            for (final r in requests)
              _cmsClickableInk(
                onTap: () => controller.openRequest(r.id),
                child: _ReplacementTableRow(
                  request: r,
                  columns: _kReplacementTableColumns,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReplacementTableRow extends StatelessWidget {
  const _ReplacementTableRow({
    required this.request,
    required this.columns,
  });
  final OrderRequest request;
  final List<_ReqColSpec> columns;

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
          for (var i = 0; i < columns.length; i++)
            Expanded(
              flex: columns[i].flex,
              child: Padding(
                padding: const EdgeInsets.only(top: 2, right: 8),
                child: _cellForColumn(columns[i].label),
              ),
            ),
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: CmsColors.textSecond,
            ),
          ),
        ],
      ),
    );
  }

  Widget _cellForColumn(String label) {
    switch (label) {
      case 'Request #':
        return Text(
          request.requestNumber.isEmpty ? '—' : request.requestNumber,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: CmsColors.textPrimary,
          ),
          overflow: TextOverflow.ellipsis,
        );
      case 'Order #':
        return Text(
          request.order?.orderNumber.isEmpty != false
              ? '—'
              : request.order!.orderNumber,
          style: const TextStyle(
            fontSize: 12.5,
            color: CmsColors.textPrimary,
          ),
          overflow: TextOverflow.ellipsis,
        );
      case 'Customer':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              request.userName.isEmpty ? '—' : request.userName,
              style: const TextStyle(
                fontSize: 12.5,
                color: CmsColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            if (request.userEmail.isNotEmpty)
              Text(
                request.userEmail,
                style: const TextStyle(
                  fontSize: 11,
                  color: CmsColors.textSecond,
                ),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        );
      case 'Reason':
        return Text(
          request.reason.isEmpty ? '—' : request.reason,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            color: CmsColors.textPrimary,
          ),
        );
      case 'Status':
        return Align(
          alignment: Alignment.centerLeft,
          child: RequestStatusBadge(status: request.status),
        );
      case 'Date':
        return CmsKitOrderDateCell(at: request.createdAt);
      default:
        return const SizedBox.shrink();
    }
  }
}

class _ReqTableHeader extends StatelessWidget {
  const _ReqTableHeader({required this.columns});
  final List<_ReqColSpec> columns;

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
          for (final col in columns)
            Expanded(
              flex: col.flex,
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  col.label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: CmsColors.textSecond,
                    letterSpacing: 0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          const SizedBox(width: 18),
        ],
      ),
    );
  }
}

class _ReqColSpec {
  const _ReqColSpec(this.label, {required this.flex});
  final String label;
  final int flex;
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({required this.controller});
  final AdminOrderRequestsController controller;

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
              '${controller.total} request${controller.total == 1 ? '' : 's'}',
              style: const TextStyle(
                fontSize: 12,
                color: CmsColors.textSecond,
              ),
            ),
            const Spacer(),
            IconButton(
              style: IconButton.styleFrom().copyWith(
                mouseCursor: _cmsButtonClickCursor,
              ),
              tooltip: 'Previous',
              onPressed: controller.page > 1 ? controller.prevPage : null,
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            IconButton(
              style: IconButton.styleFrom().copyWith(
                mouseCursor: _cmsButtonClickCursor,
              ),
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

// ════════════════════════════════════════════════════════════════
// DETAIL
// ════════════════════════════════════════════════════════════════
class _RequestDetailView extends StatelessWidget {
  const _RequestDetailView({required this.controller});
  final AdminOrderRequestsController controller;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) controller.closeDetail();
      },
      child: Obx(() {
        final r = controller.detail;
        return Column(
          children: [
            _DetailHeader(controller: controller, request: r),
            const Divider(height: 1, color: CmsColors.border),
            Expanded(
              child: () {
                if (controller.detailLoading && r == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (controller.detailError != null && r == null) {
                  return _ErrorBox(
                    message: controller.detailError!,
                    onRetry: controller.fetchDetail,
                  );
                }
                if (r == null) {
                  return const CmsEmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'Request not found',
                    subtitle: 'It may have been resolved or removed.',
                  );
                }
                return _DetailBody(controller: controller, request: r);
              }(),
            ),
          ],
        );
      }),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.controller, required this.request});
  final AdminOrderRequestsController controller;
  final OrderRequest? request;

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width >= 768;
    final title = request?.requestNumber.isNotEmpty == true
        ? 'Request ${request!.requestNumber}'
        : 'Request details';
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
            tooltip: 'Back',
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
                if (request != null)
                  Text(
                    request!.formattedDate,
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

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.controller, required this.request});
  final AdminOrderRequestsController controller;
  final OrderRequest request;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummaryCard(request: request),
          const SizedBox(height: 14),
          if (request.attachments.isNotEmpty) ...[
            _AttachmentsCard(
              attachments: request.attachments,
              title: request.type == OrderRequestType.replacement
                  ? 'Damage photos (${request.attachments.length})'
                  : 'Attachments (${request.attachments.length})',
            ),
            const SizedBox(height: 14),
          ],
          if (request.order != null) ...[
            _LinkedOrderCard(title: 'Original order', order: request.order!),
            const SizedBox(height: 14),
          ],
          if (request.replacementOrder != null) ...[
            _LinkedOrderCard(
              title: 'Replacement order',
              order: request.replacementOrder!,
            ),
            const SizedBox(height: 14),
          ],
          _DecisionBar(controller: controller, request: request),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.request});
  final OrderRequest request;

  @override
  Widget build(BuildContext context) {
    return CmsFormCard(
      title: 'Request',
      children: [
        Row(
          children: [
            _TypePill(type: request.type),
            const SizedBox(width: 6),
            RequestStatusBadge(status: request.status),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 28,
          runSpacing: 12,
          children: [
            _MetaPair(
              label: 'Customer',
              value: request.userName.isEmpty
                  ? (request.userEmail.isEmpty ? '—' : request.userEmail)
                  : '${request.userName}\n${request.userEmail}',
            ),
            _MetaPair(label: 'Created', value: request.formattedDate),
            if (request.resolvedAt != null)
              _MetaPair(
                label: 'Resolved',
                value: request.resolvedAt!.toLocal().toString(),
              ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Reason',
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: CmsColors.textSecond,
          ),
        ),
        const SizedBox(height: 4),
        SelectableText(
          request.reason.isEmpty ? '—' : request.reason,
          style: const TextStyle(
            fontSize: 12.5,
            color: CmsColors.textPrimary,
          ),
        ),
        if (request.adminNote.isNotEmpty) ...[
          const SizedBox(height: 10),
          const Text(
            'Admin note',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: CmsColors.textSecond,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(
            request.adminNote,
            style: const TextStyle(
              fontSize: 12.5,
              color: CmsColors.textPrimary,
            ),
          ),
        ],
      ],
    );
  }
}

class _AttachmentsCard extends StatelessWidget {
  const _AttachmentsCard({
    required this.attachments,
    this.title = 'Attachments',
  });
  final List<String> attachments;
  final String title;

  @override
  Widget build(BuildContext context) {
    return CmsFormCard(
      title: title,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final url in attachments)
              _cmsClickable(
                onTap: () => _openUrl(url),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: CmsColors.bg,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.insert_drive_file_outlined,
                          size: 24,
                          color: CmsColors.textSecond,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _LinkedOrderCard extends StatelessWidget {
  const _LinkedOrderCard({required this.title, required this.order});
  final String title;
  final dynamic order; // AdminOrder

  @override
  Widget build(BuildContext context) {
    return CmsFormCard(
      title: title,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.orderNumber.isEmpty
                        ? '—'
                        : 'Order ${order.orderNumber}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: CmsColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${order.formattedTotal}  ·  ${order.formattedDate}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: CmsColors.textSecond,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                OrderStatusBadge(status: order.orderStatus),
                const SizedBox(height: 4),
                PaymentStatusBadge(status: order.paymentStatus),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _DecisionBar extends StatelessWidget {
  const _DecisionBar({required this.controller, required this.request});
  final AdminOrderRequestsController controller;
  final OrderRequest request;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        final busy = controller.mutating;
        if (!request.isPending) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CmsColors.bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: CmsColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_outline_rounded,
                    size: 16, color: CmsColors.textSecond),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This request is ${request.status.label.toLowerCase()}. '
                    'No further admin action is required.',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: CmsColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ApproveHelpText(type: request.type),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                CmsPrimaryButton(
                  label: 'Approve',
                  icon: Icons.check_rounded,
                  isLoading: busy,
                  onTap: () => _showDecisionDialog(
                    context,
                    isApprove: true,
                    onSubmit: (note) => controller.approve(adminNote: note),
                  ),
                ),
                _OutlinedAction(
                  label: 'Reject',
                  icon: Icons.close_rounded,
                  color: CmsColors.red,
                  onTap: busy
                      ? null
                      : () => _showDecisionDialog(
                            context,
                            isApprove: false,
                            onSubmit: (note) =>
                                controller.reject(adminNote: note),
                          ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _ApproveHelpText extends StatelessWidget {
  const _ApproveHelpText({required this.type});
  final OrderRequestType type;

  @override
  Widget build(BuildContext context) {
    final text = switch (type) {
      OrderRequestType.cancellation =>
        'Cancels the order and restocks inventory. Not allowed if the order '
            'has already shipped.',
      OrderRequestType.refund =>
        'Marks the order as REFUNDED in Satya. v1 does NOT call PayFast — '
            'process the actual refund in the PayFast dashboard.',
      OrderRequestType.replacement =>
        'Creates a new paid replacement order linked to this request. '
            'Returns an error if stock is insufficient.',
      OrderRequestType.unknown => 'Approve this request.',
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CmsColors.orange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CmsColors.orange.withOpacity(0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 16, color: CmsColors.orangeDark),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: CmsColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showDecisionDialog(
  BuildContext context, {
  required bool isApprove,
  required Future<bool> Function(String? note) onSubmit,
}) async {
  final note = TextEditingController();
  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          isApprove ? 'Approve request' : 'Reject request',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isApprove ? CmsColors.textPrimary : CmsColors.red,
          ),
        ),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isApprove
                    ? 'Add an optional internal note explaining the approval. '
                        'The user will receive a status email.'
                    : 'Add a note explaining why this request is being '
                        'rejected. The user will receive a status email.',
                style: const TextStyle(
                  fontSize: 12,
                  color: CmsColors.textSecond,
                ),
              ),
              const SizedBox(height: 10),
              CmsFormField(
                label: 'Admin note',
                hint: isApprove
                    ? 'Approved after review (optional)'
                    : 'Reason for rejection',
                controller: note,
                maxLines: 3,
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
              backgroundColor:
                  isApprove ? CmsColors.orange : CmsColors.red,
              foregroundColor: Color(0xFFFCF7EF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ).copyWith(mouseCursor: _cmsButtonClickCursor),
            onPressed: () async {
              Navigator.pop(dialogContext);
              await onSubmit(
                note.text.trim().isEmpty ? null : note.text.trim(),
              );
            },
            child: Text(isApprove ? 'Approve' : 'Reject'),
          ),
        ],
      );
    },
  );
}

// ── shared chrome ──────────────────────────────────────────────────
class _TypePill extends StatelessWidget {
  const _TypePill({required this.type});
  final OrderRequestType type;

  @override
  Widget build(BuildContext context) {
    final color = switch (type) {
      OrderRequestType.cancellation => CmsColors.red,
      OrderRequestType.refund => const Color(0xFF6A1B9A),
      OrderRequestType.replacement => const Color(0xFF1976D2),
      OrderRequestType.unknown => Colors.grey,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        type.label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class RequestStatusBadge extends StatelessWidget {
  const RequestStatusBadge({super.key, required this.status});
  final OrderRequestStatus status;

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

  static Color _color(OrderRequestStatus s) {
    switch (s) {
      case OrderRequestStatus.requested:
        return CmsColors.orange;
      case OrderRequestStatus.approved:
        return CmsColors.green;
      case OrderRequestStatus.rejected:
        return CmsColors.red;
      case OrderRequestStatus.processing:
        return CmsColors.orangeDark;
      case OrderRequestStatus.shipped:
        return const Color(0xFF1976D2);
      case OrderRequestStatus.delivered:
        return const Color(0xFF2E7D32);
      case OrderRequestStatus.cancelled:
        return Colors.grey;
      case OrderRequestStatus.unknown:
        return Colors.grey;
    }
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
          color: onTap == null
              ? color.withOpacity(0.05)
              : color.withOpacity(0.08),
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

class _MetaPair extends StatelessWidget {
  const _MetaPair({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: CmsColors.textSecond,
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

Future<void> _openUrl(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    // Best-effort; swallow.
  }
}
