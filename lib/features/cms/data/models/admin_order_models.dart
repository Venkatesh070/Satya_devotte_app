// Domain models for the admin Orders feature. Mirrors the backend `Order`
// document shape with safe defaults so older / partial JSON does not blow
// up the UI.
//
// Source of truth: Flutter-cms-refund&orders&payments.plan §6.
import 'package:intl/intl.dart';

/// Fulfilment status from the backend `orderStatus` enum.
enum OrderStatus {
  placed,
  processing,
  shipped,
  delivered,
  fulfilled,
  cancelled,
  unknown,
}

/// Payment status from the backend `paymentStatus` enum.
enum PaymentStatus {
  pending,
  paid,
  failed,
  refunded,
  refundInitiated,
  refundFailed,
  unknown,
}

extension OrderStatusX on OrderStatus {
  String get wire {
    switch (this) {
      case OrderStatus.placed:
        return 'PLACED';
      case OrderStatus.processing:
        return 'PROCESSING';
      case OrderStatus.shipped:
        return 'SHIPPED';
      case OrderStatus.delivered:
        return 'DELIVERED';
      case OrderStatus.fulfilled:
        return 'FULFILLED';
      case OrderStatus.cancelled:
        return 'CANCELLED';
      case OrderStatus.unknown:
        return 'UNKNOWN';
    }
  }

  String get label {
    switch (this) {
      case OrderStatus.placed:
        return 'Placed';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.fulfilled:
        return 'Fulfilled';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.unknown:
        return 'Unknown';
    }
  }

  /// True once the order has left the warehouse / is terminal.
  bool get isShippedOrBeyond =>
      this == OrderStatus.shipped ||
      this == OrderStatus.delivered ||
      this == OrderStatus.fulfilled ||
      this == OrderStatus.cancelled;

  /// Devotee may cancel only before the order ships.
  bool get canUserCancel =>
      this == OrderStatus.placed || this == OrderStatus.processing;

  static OrderStatus parse(dynamic v) {
    final s = (v ?? '').toString().toUpperCase().trim();
    if (s.isEmpty) return OrderStatus.unknown;
    switch (s) {
      case 'PLACED':
      case 'PENDING':
      case 'CONFIRMED':
      case 'CREATED':
      case 'NEW':
      case 'OPEN':
      case 'ORDER_PLACED':
        return OrderStatus.placed;
      case 'PROCESSING':
      case 'IN_PROGRESS':
      case 'IN_PROCESSING':
      case 'PREPARING':
        return OrderStatus.processing;
      case 'SHIPPED':
      case 'DISPATCHED':
      case 'IN_TRANSIT':
        return OrderStatus.shipped;
      case 'DELIVERED':
        return OrderStatus.delivered;
      case 'FULFILLED':
        return OrderStatus.fulfilled;
      case 'CANCELLED':
      case 'CANCELED':
      case 'ORDER_CANCELLED':
      case 'ORDER_CANCELED':
      case 'CANCELLED_BY_USER':
      case 'CANCELED_BY_USER':
      case 'USER_CANCELLED':
      case 'USER_CANCELED':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.unknown;
    }
  }

  /// Reads fulfilment status from common API shapes (flat or nested).
  static OrderStatus parseFromOrderJson(Map<String, dynamic> json) {
    final candidates = <dynamic>[
      json['orderStatus'],
      json['status'],
      json['fulfillmentStatus'],
      json['cancelStatus'],
      json['cancellationStatus'],
      if (json['fulfillment'] is Map) (json['fulfillment'] as Map)['status'],
      if (json['cancellation'] is Map) (json['cancellation'] as Map)['status'],
      if (json['cancelOrder'] is Map) (json['cancelOrder'] as Map)['status'],
    ];

    for (final raw in candidates) {
      final parsed = parse(raw);
      if (parsed != OrderStatus.unknown) return parsed;
    }

    final hasCancellationMarker =
        json['cancelledAt'] != null ||
        json['canceledAt'] != null ||
        json['cancelReason'] != null ||
        json['cancellationReason'] != null ||
        json['cancelOrder'] is Map;
    if (hasCancellationMarker) return OrderStatus.cancelled;

    // Some create/payment responses omit orderStatus until admin processes.
    final hasStatusField = candidates.any(
      (v) => v != null && v.toString().trim().isNotEmpty,
    );
    if (!hasStatusField) {
      final pay = PaymentStatusX.parse(json['paymentStatus']);
      if (pay == PaymentStatus.pending || pay == PaymentStatus.paid) {
        return OrderStatus.placed;
      }
    }

    return OrderStatus.unknown;
  }
}

extension PaymentStatusX on PaymentStatus {
  String get wire {
    switch (this) {
      case PaymentStatus.pending:
        return 'PENDING';
      case PaymentStatus.paid:
        return 'PAID';
      case PaymentStatus.failed:
        return 'FAILED';
      case PaymentStatus.refunded:
        return 'REFUNDED';
      case PaymentStatus.refundInitiated:
        return 'REFUND_INITIATED';
      case PaymentStatus.refundFailed:
        return 'REFUND_FAILED';
      case PaymentStatus.unknown:
        return 'UNKNOWN';
    }
  }

  String get label {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.refunded:
        return 'Refunded';
      case PaymentStatus.refundInitiated:
        return 'Refund initiated';
      case PaymentStatus.refundFailed:
        return 'Refund Failed';
      case PaymentStatus.unknown:
        return 'Unknown';
    }
  }

  static PaymentStatus parse(dynamic v) {
    final s = (v ?? '').toString().toUpperCase().trim();
    switch (s) {
      case 'PAID':
      case 'SUCCESS':
      case 'SUCCESSFUL':
        return PaymentStatus.paid;
      case 'PENDING':
        return PaymentStatus.pending;
      case 'FAILED':
      case 'FAILURE':
        return PaymentStatus.failed;
      case 'REFUNDED':
        return PaymentStatus.refunded;
      case 'REFUND_INITIATED':
      case 'REFUNDINITIATED':
        return PaymentStatus.refundInitiated;
      case 'REFUND_FAILED':
      case 'REFUNDFAILED':
        return PaymentStatus.refundFailed;
      default:
        return PaymentStatus.unknown;
    }
  }
}

/// Labels for payment-status filter chips (API wire → short title).
String paymentStatusWireChipLabel(String wire) {
  switch (wire.toUpperCase().trim()) {
    case 'ALL':
      return 'All';
    case 'PAID':
      return 'Paid';
    case 'PENDING':
      return 'Pending';
    case 'FAILED':
      return 'Failed';
    case 'REFUNDED':
      return 'Refunded';
    case 'REFUND_INITIATED':
      return 'Refund initiate';
    case 'REFUND_FAILED':
      return 'Refund Failed';
    default:
      if (wire.isEmpty) return wire;
      final u = wire.toUpperCase();
      return u[0] + wire.substring(1).toLowerCase();
  }
}

class ShippingAddress {
  const ShippingAddress({
    required this.name,
    required this.line1,
    required this.line2,
    required this.city,
    required this.region,
    required this.postalCode,
    required this.country,
    required this.phone,
    required this.email,
  });

  final String name;
  final String line1;
  final String line2;
  final String city;
  final String region;
  final String postalCode;
  final String country;
  final String phone;
  final String email;

  factory ShippingAddress.fromJson(Map<String, dynamic> json) {
    String s(dynamic v) => (v ?? '').toString();
    return ShippingAddress(
      name: s(json['name'] ?? json['fullName']),
      line1: s(json['line1'] ?? json['addressLine1'] ?? json['street']),
      line2: s(json['line2'] ?? json['addressLine2']),
      city: s(json['city']),
      region: s(json['region'] ?? json['state'] ?? json['province']),
      postalCode: s(json['postalCode'] ?? json['zip'] ?? json['pin']),
      country: s(json['country']),
      phone: s(json['phone'] ?? json['mobile']),
      email: s(json['email']),
    );
  }

  /// Single-line formatted address suitable for tables.
  String get singleLine {
    final parts = <String>[
      if (line1.isNotEmpty) line1,
      if (line2.isNotEmpty) line2,
      if (city.isNotEmpty) city,
      if (region.isNotEmpty) region,
      if (postalCode.isNotEmpty) postalCode,
      if (country.isNotEmpty) country,
    ];
    return parts.join(', ');
  }
}

class OrderLineItem {
  const OrderLineItem({
    required this.productId,
    required this.title,
    required this.qty,
    required this.unitPrice,
    required this.lineTotal,
    required this.image,
  });

  final String productId;
  final String title;
  final int qty;
  final double unitPrice;
  final double lineTotal;
  final String image;

  factory OrderLineItem.fromJson(Map<String, dynamic> json) {
    final qty = _toInt(json['qty'] ?? json['quantity'] ?? 1) ?? 1;
    final unit = _toDouble(json['unitPrice'] ?? json['price']) ?? 0;
    final total = _toDouble(json['lineTotal'] ?? json['total']) ?? (unit * qty);
    return OrderLineItem(
      productId: (json['productId'] ?? json['product'] ?? '').toString(),
      title: (json['title'] ?? json['name'] ?? '').toString(),
      qty: qty,
      unitPrice: unit,
      lineTotal: total,
      image: (json['image'] ?? json['imageUrl'] ?? '').toString(),
    );
  }
}

class Tracking {
  const Tracking({
    required this.courier,
    required this.trackingNumber,
    required this.trackingUrl,
  });

  final String courier;
  final String trackingNumber;
  final String trackingUrl;

  bool get hasTrackingNumber => trackingNumber.trim().isNotEmpty;

  factory Tracking.fromJson(Map<String, dynamic> json) {
    String s(dynamic v) => (v ?? '').toString();
    return Tracking(
      courier: s(json['courier']),
      trackingNumber: s(json['trackingNumber']),
      trackingUrl: s(json['trackingUrl']),
    );
  }
}

class Invoice {
  const Invoice({
    required this.number,
    required this.url,
    required this.generatedAt,
  });

  final String number;
  final String url;
  final DateTime? generatedAt;

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      number: (json['number'] ?? '').toString(),
      url: (json['url'] ?? '').toString(),
      generatedAt: _parseDate(json['generatedAt']),
    );
  }
}

class Fulfillment {
  const Fulfillment({
    required this.satisfied,
    required this.ratedAt,
    required this.feedback,
  });

  final bool? satisfied;
  final DateTime? ratedAt;
  final String feedback;

  factory Fulfillment.fromJson(Map<String, dynamic> json) {
    return Fulfillment(
      satisfied: json['satisfied'] is bool ? json['satisfied'] as bool : null,
      ratedAt: _parseDate(json['ratedAt']),
      feedback: (json['feedback'] ?? '').toString(),
    );
  }
}

class AdminOrder {
  const AdminOrder({
    required this.id,
    required this.orderNumber,
    required this.orderStatus,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.paystackReference,
    required this.currency,
    required this.totalAmount,
    required this.subtotalAmount,
    required this.shippingAmount,
    required this.taxAmount,
    required this.createdAt,
    required this.dispatchedAt,
    required this.sharedWithUserAt,
    required this.items,
    required this.shippingAddress,
    required this.tracking,
    required this.invoice,
    required this.fulfillment,
    required this.inventoryReserved,
    required this.userId,
    required this.userName,
    required this.userEmail,
  });

  final String id;
  final String orderNumber;
  final OrderStatus orderStatus;
  final PaymentStatus paymentStatus;
  final String paymentMethod;
  final String paystackReference;
  final String currency;
  final double totalAmount;
  final double subtotalAmount;
  final double shippingAmount;
  final double taxAmount;
  final DateTime? createdAt;
  final DateTime? dispatchedAt;
  final DateTime? sharedWithUserAt;
  final List<OrderLineItem> items;
  final ShippingAddress? shippingAddress;
  final Tracking? tracking;
  final Invoice? invoice;
  final Fulfillment? fulfillment;
  final bool inventoryReserved;
  final String userId;
  final String userName;
  final String userEmail;

  bool get hasTracking => tracking?.hasTrackingNumber == true;

  /// Paystack reported a successful charge; fulfilment actions apply.
  bool get isPaymentPaid => paymentStatus == PaymentStatus.paid;

  /// Admin may start a refund request only after fulfilment is **Delivered**.
  bool get canInitiateRefund {
    if (orderStatus != OrderStatus.delivered) return false;
    if (paymentStatus == PaymentStatus.refunded ||
        paymentStatus == PaymentStatus.refundInitiated) {
      return false;
    }
    return paymentStatus == PaymentStatus.paid ||
        paymentStatus == PaymentStatus.refundFailed;
  }

  /// Formatted currency string, e.g. `R 250` for ZAR or `R 250.50`.
  String get formattedTotal => _formatCurrency(totalAmount, currency);
  String get formattedSubtotal => _formatCurrency(subtotalAmount, currency);
  String get formattedShipping => _formatCurrency(shippingAmount, currency);
  String get formattedTax => _formatCurrency(taxAmount, currency);

  /// e.g. `12 Aug 2026` for tables.
  String get formattedDate =>
      createdAt == null ? '—' : DateFormat('d MMM yyyy').format(createdAt!);

  /// e.g. `12 Aug 2026, 4:32 pm` for the detail screen.
  String get formattedDateTime => createdAt == null
      ? '—'
      : DateFormat('d MMM yyyy, h:mm a').format(createdAt!);

  factory AdminOrder.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    String userId = '';
    String userName = '';
    String userEmail = '';
    if (user is Map<String, dynamic>) {
      userId = (user['_id'] ?? user['id'] ?? '').toString();
      userName = (user['name'] ?? user['fullName'] ?? '').toString();
      userEmail = (user['email'] ?? '').toString();
    } else if (user is String) {
      userId = user;
    }

    final rawItems = json['items'] ?? json['lineItems'] ?? const <dynamic>[];
    final items = <OrderLineItem>[];
    if (rawItems is List) {
      for (final raw in rawItems) {
        if (raw is Map<String, dynamic>) {
          items.add(OrderLineItem.fromJson(raw));
        }
      }
    }

    return AdminOrder(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      orderNumber: (json['orderNumber'] ?? '').toString(),
      orderStatus: OrderStatusX.parseFromOrderJson(json),
      paymentStatus: PaymentStatusX.parse(json['paymentStatus']),
      paymentMethod: (json['paymentMethod'] ?? '').toString(),
      paystackReference:
          (json['paystackReference'] ??
                  json['paymentReference'] ??
                  json['reference'] ??
                  '')
              .toString(),
      currency:
          (json['currency'] ?? 'ZAR').toString().toUpperCase().trim().isEmpty
          ? 'ZAR'
          : (json['currency'] ?? 'ZAR').toString().toUpperCase().trim(),
      totalAmount: _toDouble(json['totalAmount'] ?? json['total']) ?? 0,
      subtotalAmount:
          _toDouble(json['subtotalAmount'] ?? json['subtotal']) ?? 0,
      shippingAmount: _toDouble(json['shippingAmount']) ?? 0,
      taxAmount: _toDouble(json['taxAmount']) ?? 0,
      createdAt: _parseDate(json['createdAt']),
      dispatchedAt: _parseDate(json['dispatchedAt']),
      sharedWithUserAt: _parseDate(json['sharedWithUserAt']),
      items: items,
      shippingAddress: json['shippingAddress'] is Map<String, dynamic>
          ? ShippingAddress.fromJson(
              json['shippingAddress'] as Map<String, dynamic>,
            )
          : null,
      tracking: json['tracking'] is Map<String, dynamic>
          ? Tracking.fromJson(json['tracking'] as Map<String, dynamic>)
          : null,
      invoice: json['invoice'] is Map<String, dynamic>
          ? Invoice.fromJson(json['invoice'] as Map<String, dynamic>)
          : null,
      fulfillment: json['fulfillment'] is Map<String, dynamic>
          ? Fulfillment.fromJson(json['fulfillment'] as Map<String, dynamic>)
          : null,
      inventoryReserved: json['inventoryReserved'] == true,
      userId: userId,
      userName: userName,
      userEmail: userEmail,
    );
  }

  /// Some endpoints (e.g. Paystack verify) return an order without a populated
  /// `user` map. When merging into a list row that already had customer data,
  /// copy [fallback]'s customer fields so the UI does not blank out.
  AdminOrder withCustomerFallback(AdminOrder fallback) {
    final stripped = userName.trim().isEmpty && userEmail.trim().isEmpty;
    if (!stripped) return this;
    final fbHas =
        fallback.userName.trim().isNotEmpty ||
        fallback.userEmail.trim().isNotEmpty ||
        fallback.userId.trim().isNotEmpty;
    if (!fbHas) return this;
    return AdminOrder(
      id: id,
      orderNumber: orderNumber,
      orderStatus: orderStatus,
      paymentStatus: paymentStatus,
      paymentMethod: paymentMethod,
      paystackReference: paystackReference,
      currency: currency,
      totalAmount: totalAmount,
      subtotalAmount: subtotalAmount,
      shippingAmount: shippingAmount,
      taxAmount: taxAmount,
      createdAt: createdAt,
      dispatchedAt: dispatchedAt,
      sharedWithUserAt: sharedWithUserAt,
      items: items,
      shippingAddress: shippingAddress,
      tracking: tracking,
      invoice: invoice,
      fulfillment: fulfillment,
      inventoryReserved: inventoryReserved,
      userId: userId.trim().isNotEmpty ? userId : fallback.userId,
      userName: fallback.userName,
      userEmail: fallback.userEmail,
    );
  }
}

/// One page of `GET /orders/all` results.
class AdminOrdersPage {
  const AdminOrdersPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final List<AdminOrder> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
}

/// Allowed next states for the contextual action bar in the detail screen.
class OrderStatusMachine {
  static List<OrderStatus> nextAllowed(
    OrderStatus current, {
    required bool hasTrackingNumber,
  }) {
    switch (current) {
      case OrderStatus.placed:
        return const [OrderStatus.processing, OrderStatus.cancelled];
      case OrderStatus.processing:
        return [
          if (hasTrackingNumber) OrderStatus.shipped,
          OrderStatus.cancelled,
        ];
      case OrderStatus.shipped:
        return const [OrderStatus.delivered];
      case OrderStatus.delivered:
      case OrderStatus.fulfilled:
      case OrderStatus.cancelled:
      case OrderStatus.unknown:
        return const [];
    }
  }

  /// `POST /orders/:id/cancel-paid` is only valid before the order ships and
  /// the order has not already terminated.
  static bool canAdminCancel(OrderStatus s) {
    return s == OrderStatus.placed || s == OrderStatus.processing;
  }
}

String _formatCurrency(double amount, String currency) {
  final symbol = currency == 'ZAR' ? 'R' : currency;
  final decimals = amount.truncateToDouble() == amount ? 0 : 2;
  final f = NumberFormat.currency(
    name: currency,
    symbol: '$symbol ',
    decimalDigits: decimals,
  );
  return f.format(amount);
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  final s = v.toString();
  if (s.isEmpty) return null;
  return DateTime.tryParse(s)?.toLocal();
}

int? _toInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}
