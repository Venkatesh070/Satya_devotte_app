// Domain models for `OrderRequest` (cancellation / refund / replacement)
// as returned by `GET /orders/requests`.
import 'package:intl/intl.dart';

import 'package:satya_devotte_app/features/cms/data/models/admin_order_models.dart';

enum OrderRequestType { cancellation, refund, replacement, unknown }

enum OrderRequestStatus { pending, approved, rejected, completed, unknown }

extension OrderRequestTypeX on OrderRequestType {
  String get wire {
    switch (this) {
      case OrderRequestType.cancellation:
        return 'CANCELLATION';
      case OrderRequestType.refund:
        return 'REFUND';
      case OrderRequestType.replacement:
        return 'REPLACEMENT';
      case OrderRequestType.unknown:
        return 'UNKNOWN';
    }
  }

  String get label {
    switch (this) {
      case OrderRequestType.cancellation:
        return 'Cancellation';
      case OrderRequestType.refund:
        return 'Refund';
      case OrderRequestType.replacement:
        return 'Replacement';
      case OrderRequestType.unknown:
        return 'Unknown';
    }
  }

  static OrderRequestType parse(dynamic v) {
    final s = (v ?? '').toString().toUpperCase().trim();
    switch (s) {
      case 'CANCELLATION':
      case 'CANCEL':
        return OrderRequestType.cancellation;
      case 'REFUND':
        return OrderRequestType.refund;
      case 'REPLACEMENT':
      case 'REPLACE':
        return OrderRequestType.replacement;
      default:
        return OrderRequestType.unknown;
    }
  }
}

extension OrderRequestStatusX on OrderRequestStatus {
  String get wire {
    switch (this) {
      case OrderRequestStatus.pending:
        return 'PENDING';
      case OrderRequestStatus.approved:
        return 'APPROVED';
      case OrderRequestStatus.rejected:
        return 'REJECTED';
      case OrderRequestStatus.completed:
        return 'COMPLETED';
      case OrderRequestStatus.unknown:
        return 'UNKNOWN';
    }
  }

  String get label {
    switch (this) {
      case OrderRequestStatus.pending:
        return 'Pending';
      case OrderRequestStatus.approved:
        return 'Approved';
      case OrderRequestStatus.rejected:
        return 'Rejected';
      case OrderRequestStatus.completed:
        return 'Completed';
      case OrderRequestStatus.unknown:
        return 'Unknown';
    }
  }

  static OrderRequestStatus parse(dynamic v) {
    final s = (v ?? '').toString().toUpperCase().trim();
    switch (s) {
      case 'PENDING':
        return OrderRequestStatus.pending;
      case 'APPROVED':
        return OrderRequestStatus.approved;
      case 'REJECTED':
        return OrderRequestStatus.rejected;
      case 'COMPLETED':
        return OrderRequestStatus.completed;
      default:
        return OrderRequestStatus.unknown;
    }
  }
}

class OrderRequest {
  const OrderRequest({
    required this.id,
    required this.requestNumber,
    required this.type,
    required this.status,
    required this.reason,
    required this.attachments,
    required this.adminNote,
    required this.createdAt,
    required this.resolvedAt,
    required this.order,
    required this.replacementOrder,
    required this.userId,
    required this.userName,
    required this.userEmail,
  });

  final String id;
  final String requestNumber;
  final OrderRequestType type;
  final OrderRequestStatus status;
  final String reason;
  final List<String> attachments;
  final String adminNote;
  final DateTime? createdAt;
  final DateTime? resolvedAt;
  final AdminOrder? order;
  final AdminOrder? replacementOrder;
  final String userId;
  final String userName;
  final String userEmail;

  bool get isPending => status == OrderRequestStatus.pending;

  String get formattedDate => createdAt == null
      ? '—'
      : DateFormat('d MMM yyyy, h:mm a').format(createdAt!);

  factory OrderRequest.fromJson(Map<String, dynamic> json) {
    final attachmentsRaw =
        json['attachments'] ?? json['files'] ?? const <dynamic>[];
    final attachments = <String>[];
    if (attachmentsRaw is List) {
      for (final a in attachmentsRaw) {
        if (a is String && a.isNotEmpty) {
          attachments.add(a);
        } else if (a is Map && a['url'] is String) {
          attachments.add(a['url'] as String);
        }
      }
    }

    // user may live on the request OR inside `order.user`.
    String userId = '';
    String userName = '';
    String userEmail = '';
    final user = json['user'];
    if (user is Map<String, dynamic>) {
      userId = (user['_id'] ?? user['id'] ?? '').toString();
      userName = (user['name'] ?? user['fullName'] ?? '').toString();
      userEmail = (user['email'] ?? '').toString();
    } else if (user is String) {
      userId = user;
    }

    AdminOrder? order;
    AdminOrder? replacementOrder;
    if (json['order'] is Map<String, dynamic>) {
      order = AdminOrder.fromJson(json['order'] as Map<String, dynamic>);
      if (userId.isEmpty) userId = order.userId;
      if (userName.isEmpty) userName = order.userName;
      if (userEmail.isEmpty) userEmail = order.userEmail;
    }
    if (json['replacementOrder'] is Map<String, dynamic>) {
      replacementOrder = AdminOrder.fromJson(
        json['replacementOrder'] as Map<String, dynamic>,
      );
    }

    return OrderRequest(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      requestNumber: (json['requestNumber'] ?? '').toString(),
      type: OrderRequestTypeX.parse(json['type']),
      status: OrderRequestStatusX.parse(json['status']),
      reason: (json['reason'] ?? '').toString(),
      attachments: attachments,
      adminNote: (json['adminNote'] ?? '').toString(),
      createdAt: _parseDate(json['createdAt']),
      resolvedAt: _parseDate(json['resolvedAt']),
      order: order,
      replacementOrder: replacementOrder,
      userId: userId,
      userName: userName,
      userEmail: userEmail,
    );
  }
}

class OrderRequestsPage {
  const OrderRequestsPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final List<OrderRequest> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  final s = v.toString();
  if (s.isEmpty) return null;
  return DateTime.tryParse(s)?.toLocal();
}
