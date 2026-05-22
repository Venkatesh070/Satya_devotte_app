// Domain models for `OrderRequest` (cancellation / refund / replacement)
// as returned by `GET /orders/requests`.
import 'package:intl/intl.dart';

import 'package:satya_devotte_app/config/env/app_env.dart';
import 'package:satya_devotte_app/features/cms/data/models/admin_order_models.dart';

enum OrderRequestType { cancellation, refund, replacement, unknown }

/// Replacement request lifecycle (`GET /admin/replacements`).
enum OrderRequestStatus {
  requested,
  approved,
  rejected,
  processing,
  shipped,
  delivered,
  cancelled,
  unknown,
}

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
      case OrderRequestStatus.requested:
        return 'REQUESTED';
      case OrderRequestStatus.approved:
        return 'APPROVED';
      case OrderRequestStatus.rejected:
        return 'REJECTED';
      case OrderRequestStatus.processing:
        return 'PROCESSING';
      case OrderRequestStatus.shipped:
        return 'SHIPPED';
      case OrderRequestStatus.delivered:
        return 'DELIVERED';
      case OrderRequestStatus.cancelled:
        return 'CANCELLED';
      case OrderRequestStatus.unknown:
        return 'UNKNOWN';
    }
  }

  /// UI label; [OrderRequestStatus.delivered] shows as **Completed**.
  String get label {
    switch (this) {
      case OrderRequestStatus.requested:
        return 'Requested';
      case OrderRequestStatus.approved:
        return 'Approved';
      case OrderRequestStatus.rejected:
        return 'Rejected';
      case OrderRequestStatus.processing:
        return 'Processing';
      case OrderRequestStatus.shipped:
        return 'Shipped';
      case OrderRequestStatus.delivered:
        return 'Completed';
      case OrderRequestStatus.cancelled:
        return 'Cancelled';
      case OrderRequestStatus.unknown:
        return 'Unknown';
    }
  }

  static OrderRequestStatus parse(dynamic v) {
    final s = (v ?? '').toString().toUpperCase().trim();
    switch (s) {
      case 'REQUESTED':
      case 'PENDING':
        return OrderRequestStatus.requested;
      case 'APPROVED':
        return OrderRequestStatus.approved;
      case 'REJECTED':
        return OrderRequestStatus.rejected;
      case 'PROCESSING':
        return OrderRequestStatus.processing;
      case 'SHIPPED':
        return OrderRequestStatus.shipped;
      case 'DELIVERED':
      case 'COMPLETED':
        return OrderRequestStatus.delivered;
      case 'CANCELLED':
      case 'CANCELED':
        return OrderRequestStatus.cancelled;
      default:
        return OrderRequestStatus.unknown;
    }
  }
}

/// Filter chip labels for replacement status wires.
String replacementRequestStatusFilterLabel(String wire) {
  switch (wire.toUpperCase().trim()) {
    case 'ALL':
      return 'All';
    case 'REQUESTED':
      return 'Requested';
    case 'APPROVED':
      return 'Approved';
    case 'REJECTED':
      return 'Rejected';
    case 'PROCESSING':
      return 'Processing';
    case 'SHIPPED':
      return 'Shipped';
    case 'DELIVERED':
      return 'Completed';
    case 'CANCELLED':
      return 'Cancelled';
    default:
      if (wire.isEmpty) return wire;
      return wire[0] + wire.substring(1).toLowerCase();
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

  bool get isPending => status == OrderRequestStatus.requested;

  String get formattedDate => createdAt == null
      ? '—'
      : DateFormat('d MMM yyyy, h:mm a').format(createdAt!);

  factory OrderRequest.fromJson(Map<String, dynamic> json) {
    final attachments = _parseAttachmentUrls(json);

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
    final orderJson = json['order'] ?? json['originalOrder'];
    if (orderJson is Map<String, dynamic>) {
      order = AdminOrder.fromJson(orderJson);
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
      requestNumber: (json['requestNumber'] ??
              json['replacementNumber'] ??
              json['number'] ??
              '')
          .toString(),
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

  /// Parses a document from `GET /admin/replacements`.
  factory OrderRequest.fromReplacementJson(Map<String, dynamic> json) {
    final normalized = Map<String, dynamic>.from(json);
    normalized.putIfAbsent('type', () => 'REPLACEMENT');
    return OrderRequest.fromJson(normalized);
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

/// Devotee replacement uploads use multipart field `images`; the API may
/// return them as `images`, `attachments`, populated docs, or relative paths.
List<String> _parseAttachmentUrls(Map<String, dynamic> json) {
  final out = <String>[];

  void addResolved(String? raw) {
    final url = _resolveMediaUrl(raw);
    if (url != null && url.isNotEmpty && !out.contains(url)) {
      out.add(url);
    }
  }

  void addFromMap(Map<dynamic, dynamic> raw) {
    final m = Map<String, dynamic>.from(raw);
    for (final key in const [
      'url',
      'secure_url',
      'secureUrl',
      'location',
      'href',
      'src',
    ]) {
      final v = m[key];
      if (v != null && v.toString().trim().isNotEmpty) {
        addResolved(v.toString());
        return;
      }
    }
    for (final key in const ['path', 'key', 'filename', 'name']) {
      final v = m[key];
      if (v != null && v.toString().trim().isNotEmpty) {
        addResolved(v.toString());
        return;
      }
    }
  }

  void walk(dynamic value) {
    if (value == null) return;
    if (value is String) {
      addResolved(value);
      return;
    }
    if (value is List) {
      for (final item in value) {
        walk(item);
      }
      return;
    }
    if (value is Map) {
      addFromMap(value);
    }
  }

  for (final field in const [
    'images',
    'image',
    'attachments',
    'files',
    'damageImages',
    'proofImages',
    'photos',
    'imageUrls',
    'replacementImages',
  ]) {
    if (json.containsKey(field)) {
      walk(json[field]);
    }
  }

  return out;
}

String? _resolveMediaUrl(String? raw) {
  if (raw == null) return null;
  final s = raw.trim();
  if (s.isEmpty) return null;
  if (s.startsWith('http://') || s.startsWith('https://')) return s;
  final base = AppEnv.resolvedApiBaseUrl.replaceAll(RegExp(r'/+$'), '');
  if (s.startsWith('/')) return '$base$s';
  return '$base/$s';
}
