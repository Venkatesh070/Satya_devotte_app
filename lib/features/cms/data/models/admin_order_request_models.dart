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
  awaitingReturn,
  returnReceived,
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
        return 'Return';
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
      case OrderRequestStatus.awaitingReturn:
        return 'AWAITING_RETURN';
      case OrderRequestStatus.returnReceived:
        return 'RETURN_RECEIVED';
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
      case OrderRequestStatus.awaitingReturn:
        return 'Awaiting return';
      case OrderRequestStatus.returnReceived:
        return 'Return received';
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
      case 'AWAITING_RETURN':
        return OrderRequestStatus.awaitingReturn;
      case 'RETURN_RECEIVED':
        return OrderRequestStatus.returnReceived;
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
    case 'AWAITING_RETURN':
      return 'Awaiting return';
    case 'RETURN_BOOKED':
      return 'Return booked';
    case 'RETURN_IN_TRANSIT':
      return 'Return in transit';
    case 'RETURN_RECEIVED':
      return 'Return received';
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

/// Filter chip labels for refund/return request status wires.
String orderRequestStatusFilterLabel(String wire) {
  switch (wire.toUpperCase().trim()) {
    case 'ALL':
      return 'All';
    case 'PENDING':
      return 'Pending';
    case 'APPROVED':
      return 'Approved';
    case 'REJECTED':
      return 'Rejected';
    case 'COMPLETED':
      return 'Completed';
    default:
      return replacementRequestStatusFilterLabel(wire);
  }
}

class ReturnAddressSnapshot {
  const ReturnAddressSnapshot({
    required this.label,
    required this.contactName,
    required this.contactPhone,
    required this.contactEmail,
  });

  final String label;
  final String contactName;
  final String contactPhone;
  final String contactEmail;

  bool get isEmpty =>
      label.trim().isEmpty &&
      contactName.trim().isEmpty &&
      contactPhone.trim().isEmpty;

  factory ReturnAddressSnapshot.fromJson(dynamic raw) {
    if (raw is! Map) {
      return const ReturnAddressSnapshot(
        label: '',
        contactName: '',
        contactPhone: '',
        contactEmail: '',
      );
    }
    final m = Map<String, dynamic>.from(raw);
    return ReturnAddressSnapshot(
      label: (m['label'] ?? m['enteredAddress'] ?? '').toString(),
      contactName: (m['contactName'] ?? m['name'] ?? '').toString(),
      contactPhone: (m['contactPhone'] ?? m['phone'] ?? '').toString(),
      contactEmail: (m['contactEmail'] ?? m['email'] ?? '').toString(),
    );
  }
}

class ReplacementReturnInfo {
  const ReplacementReturnInfo({
    required this.method,
    required this.status,
    required this.instructions,
    required this.waybill,
    required this.trackingUrl,
    required this.labelUrl,
    required this.receivedAt,
    this.shipmentId = '',
    this.courierStatus = '',
    this.collectionAddress = const ReturnAddressSnapshot(
      label: '',
      contactName: '',
      contactPhone: '',
      contactEmail: '',
    ),
    this.deliveryAddress = const ReturnAddressSnapshot(
      label: '',
      contactName: '',
      contactPhone: '',
      contactEmail: '',
    ),
  });

  final String method;
  final String status;
  final String instructions;
  final String waybill;
  final String trackingUrl;
  final String labelUrl;
  final DateTime? receivedAt;
  final String shipmentId;
  final String courierStatus;
  final ReturnAddressSnapshot collectionAddress;
  final ReturnAddressSnapshot deliveryAddress;

  bool get isPickupDropOff =>
      method.toUpperCase() == 'WAREHOUSE_DROP_OFF' ||
      method.toUpperCase() == 'PICKUP';

  bool get isCourierCollection =>
      method.toUpperCase() == 'COURIER_COLLECTION' ||
      method.toUpperCase() == 'DELIVERY';

  bool get isReturnReceived => status.toUpperCase() == 'RETURN_RECEIVED';

  bool get canBookReturn =>
      isCourierCollection &&
      !isReturnReceived &&
      waybill.isEmpty &&
      shipmentId.isEmpty &&
      (status.isEmpty ||
          status.toUpperCase() == 'AWAITING_RETURN' ||
          status.toUpperCase() == 'NOT_APPLICABLE');

  /// Delivery return with a booked TCG shipment that is not yet received.
  bool get canSyncReturnTracking =>
      isCourierCollection &&
      !isReturnReceived &&
      (shipmentId.isNotEmpty || waybill.isNotEmpty);

  factory ReplacementReturnInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const ReplacementReturnInfo(
        method: '',
        status: '',
        instructions: '',
        waybill: '',
        trackingUrl: '',
        labelUrl: '',
        receivedAt: null,
      );
    }
    return ReplacementReturnInfo(
      method: (json['method'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      instructions: (json['instructions'] ?? '').toString(),
      waybill: (json['waybill'] ?? '').toString(),
      trackingUrl: (json['trackingUrl'] ?? '').toString(),
      labelUrl: (json['labelUrl'] ?? '').toString(),
      receivedAt: _parseDate(json['receivedAt']),
      shipmentId: (json['shipmentId'] ?? '').toString(),
      courierStatus: (json['courierStatus'] ?? '').toString(),
      collectionAddress: ReturnAddressSnapshot.fromJson(
        json['collectionAddress'],
      ),
      deliveryAddress: ReturnAddressSnapshot.fromJson(
        json['deliveryAddress'],
      ),
    );
  }
}

class OrderAffectedItem {
  const OrderAffectedItem({
    required this.productId,
    required this.title,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    required this.image,
  });

  final String productId;
  final String title;
  final int quantity;
  final double unitPrice;
  final double lineTotal;
  final String image;

  Map<String, dynamic> toRequestJson() => {
    'productId': productId,
    'quantity': quantity,
  };

  factory OrderAffectedItem.fromJson(Map<String, dynamic> json) {
    final qty = int.tryParse(
          (json['quantity'] ?? json['qty'] ?? '1').toString(),
        ) ??
        1;
    final unit = double.tryParse(
          (json['price'] ?? json['unitPrice'] ?? '0').toString(),
        ) ??
        0;
    final total = double.tryParse(
          (json['lineTotal'] ?? json['total'] ?? '').toString(),
        ) ??
        (unit * qty);
    final product = json['productId'] ?? json['product'];
    final productId = product is Map
        ? (product['_id'] ?? product['id'] ?? '').toString()
        : (product ?? '').toString();
    return OrderAffectedItem(
      productId: productId,
      title: (json['title'] ?? json['name'] ?? '').toString(),
      quantity: qty,
      unitPrice: unit,
      lineTotal: total,
      image: (json['image'] ?? json['imageUrl'] ?? '').toString(),
    );
  }
}

List<OrderAffectedItem> parseAffectedItems(dynamic raw) {
  if (raw is! List) return const [];
  final out = <OrderAffectedItem>[];
  for (final entry in raw) {
    if (entry is! Map) continue;
    // Dio/JSON may yield Map<dynamic, dynamic>; always normalize.
    out.add(OrderAffectedItem.fromJson(Map<String, dynamic>.from(entry)));
  }
  return out;
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
    required this.fulfillmentMethod,
    required this.returnInfo,
    required this.affectedItems,
    required this.refundAmount,
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
  final String fulfillmentMethod;
  final ReplacementReturnInfo returnInfo;
  final List<OrderAffectedItem> affectedItems;
  final double? refundAmount;
  final String userId;
  final String userName;
  final String userEmail;

  bool get isPending => status == OrderRequestStatus.requested;

  bool get isPickup => fulfillmentMethod.toUpperCase() == 'PICKUP';

  bool get isDelivery => fulfillmentMethod.toUpperCase() == 'DELIVERY';

  bool get canApproveOrReject => status == OrderRequestStatus.requested;

  bool get canBookReturnCollection =>
      (status == OrderRequestStatus.awaitingReturn ||
          (type == OrderRequestType.replacement &&
              status == OrderRequestStatus.approved)) &&
      isDelivery &&
      returnInfo.canBookReturn;

  bool get canMarkReturnReceived {
    if (returnInfo.isReturnReceived) return false;
    if (status == OrderRequestStatus.returnReceived) return false;
    if (type == OrderRequestType.refund) {
      // Refund: mark received only while awaiting physical return (triggers refund).
      return status == OrderRequestStatus.awaitingReturn;
    }
    return status == OrderRequestStatus.awaitingReturn ||
        status == OrderRequestStatus.approved ||
        returnInfo.status.toUpperCase() == 'RETURN_BOOKED';
  }

  /// Refresh TCG return tracking (delivery refunds with a booked collection).
  bool get canSyncReturnTracking =>
      type == OrderRequestType.refund &&
      status == OrderRequestStatus.awaitingReturn &&
      returnInfo.canSyncReturnTracking;

  bool get hasAdminActions =>
      canApproveOrReject ||
      canBookReturnCollection ||
      canMarkReturnReceived ||
      canSyncReturnTracking;

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
    if (orderJson is Map) {
      order = AdminOrder.fromJson(Map<String, dynamic>.from(orderJson));
      if (userId.isEmpty) userId = order.userId;
      if (userName.isEmpty) userName = order.userName;
      if (userEmail.isEmpty) userEmail = order.userEmail;
    } else if (orderJson != null) {
      final oid = orderJson.toString().trim();
      if (oid.isNotEmpty) {
        order = AdminOrder.fromJson({'_id': oid});
      }
    }
    final replacementOrderJson = json['replacementOrder'];
    if (replacementOrderJson is Map) {
      replacementOrder = AdminOrder.fromJson(
        Map<String, dynamic>.from(replacementOrderJson),
      );
    }

    final returnRaw = json['returnShipment'];
    var fulfillmentMethod = (json['fulfillmentMethod'] ?? '').toString();
    if (fulfillmentMethod.trim().isEmpty && order != null) {
      fulfillmentMethod = order.fulfillmentMethod.wire;
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
      adminNote: (json['adminNote'] ?? json['adminRemarks'] ?? '').toString(),
      createdAt: _parseDate(json['createdAt']),
      resolvedAt: _parseDate(json['resolvedAt']),
      order: order,
      replacementOrder: replacementOrder,
      fulfillmentMethod: fulfillmentMethod,
      returnInfo: ReplacementReturnInfo.fromJson(
        returnRaw is Map ? Map<String, dynamic>.from(returnRaw) : null,
      ),
      affectedItems: parseAffectedItems(json['affectedItems']),
      refundAmount: () {
        final raw = json['refundAmount'];
        if (raw == null) return null;
        return double.tryParse(raw.toString());
      }(),
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

class ApproveOrderRequestResult {
  const ApproveOrderRequestResult({
    required this.request,
    this.message,
  });

  final OrderRequest request;
  final String? message;
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
