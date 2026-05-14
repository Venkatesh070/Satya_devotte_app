// Pooja Kit → Replace & Cancel Requests tab content for the CMS.
//
// Surfaces `GET /orders/requests` which carries cancellation, refund and
// replacement requests raised by devotees. The flow:
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

import 'package:satya_devotte_app/features/cms/data/models/admin_order_request_models.dart';
import 'package:satya_devotte_app/features/cms/presentation/contents/cms_pooja_kit_orders_content.dart'
    show OrderStatusBadge, PaymentStatusBadge;
import 'package:satya_devotte_app/features/cms/presentation/controllers/admin_order_requests_controller.dart';
import 'package:satya_devotte_app/features/cms/presentation/pages/cms_shell_page.dart';
import 'package:satya_devotte_app/features/cms/presentation/widgets/cms_shared_widgets.dart';

class CmsPoojaKitRefundsContent extends StatelessWidget {
  const CmsPoojaKitRefundsContent({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<AdminOrderRequestsController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (c.items.isEmpty && !c.isLoading && c.error == null) {
        c.refresh();
      }
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
          title: 'Replace & Cancel Requests',
          subtitle:
              'Review cancellations, refunds and replacement requests from '
              'devotees. Approve to apply the action, or reject with a note.',
          trailing: IconButton(
            tooltip: 'Refresh',
            onPressed: controller.refresh,
            icon: const Icon(
              Icons.refresh_rounded,
              color: CmsColors.textPrimary,
            ),
          ),
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

class _FiltersBar extends StatelessWidget {
  const _FiltersBar({required this.controller});
  final AdminOrderRequestsController controller;

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
              selected: controller.status,
              onSelect: controller.setStatusFilter,
            ),
          ),
          const SizedBox(height: 8),
          Obx(
            () => _Pills(
              label: 'Type',
              options: AdminOrderRequestsController.typeFilters,
              selected: controller.type,
              onSelect: controller.setTypeFilter,
            ),
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
                    label: opt == 'ALL'
                        ? 'All'
                        : opt[0] + opt.substring(1).toLowerCase(),
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

class _RequestsBody extends StatelessWidget {
  const _RequestsBody({required this.controller});
  final AdminOrderRequestsController controller;

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
          icon: Icons.assignment_return_outlined,
          title: 'No requests',
          subtitle:
              'Devotee-raised cancellations, refunds and replacements will '
              'appear here once submitted.',
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: controller.items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final r = controller.items[i];
          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => controller.openRequest(r.id),
            child: _RequestRowCard(request: r),
          );
        },
      );
    });
  }
}

class _RequestRowCard extends StatelessWidget {
  const _RequestRowCard({required this.request});
  final OrderRequest request;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
                  request.requestNumber.isEmpty ? '—' : request.requestNumber,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: CmsColors.textPrimary,
                  ),
                ),
              ),
              _TypePill(type: request.type),
              const SizedBox(width: 6),
              RequestStatusBadge(status: request.status),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Order ${request.order?.orderNumber ?? '—'} · '
            '${request.userName.isEmpty ? '—' : request.userName} · '
            '${request.userEmail}',
            style: const TextStyle(
              fontSize: 11.5,
              color: CmsColors.textSecond,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          if (request.reason.isNotEmpty)
            Text(
              request.reason,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                color: CmsColors.textPrimary,
              ),
            ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                request.formattedDate,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: CmsColors.textSecond,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: CmsColors.textSecond,
              ),
            ],
          ),
        ],
      ),
    );
  }
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
            _AttachmentsCard(attachments: request.attachments),
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
  const _AttachmentsCard({required this.attachments});
  final List<String> attachments;

  @override
  Widget build(BuildContext context) {
    return CmsFormCard(
      title: 'Attachments (${attachments.length})',
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final url in attachments)
              GestureDetector(
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
        'Marks the order as REFUNDED in Satya. v1 does NOT call Paystack — '
            'process the actual refund in the Paystack dashboard.',
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
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
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
      case OrderRequestStatus.pending:
        return CmsColors.orange;
      case OrderRequestStatus.approved:
        return CmsColors.green;
      case OrderRequestStatus.rejected:
        return CmsColors.red;
      case OrderRequestStatus.completed:
        return const Color(0xFF2E7D32);
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
    return GestureDetector(
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
