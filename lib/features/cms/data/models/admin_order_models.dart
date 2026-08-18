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
  packed,
  readyForPickup,
  collected,
  shipped,
  outForDelivery,
  delivered,
  fulfilled,
  cancelled,
  unknown,
}

/// How the order is fulfilled — delivery (TCG) or warehouse pickup.
enum FulfillmentMethod {
  delivery,
  pickup,
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
      case OrderStatus.packed:
        return 'PACKED';
      case OrderStatus.readyForPickup:
        return 'READY_FOR_PICKUP';
      case OrderStatus.collected:
        return 'COLLECTED';
      case OrderStatus.shipped:
        return 'SHIPPED';
      case OrderStatus.outForDelivery:
        return 'OUT_FOR_DELIVERY';
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
      case OrderStatus.packed:
        return 'Packed';
      case OrderStatus.readyForPickup:
        return 'Ready for pickup';
      case OrderStatus.collected:
        return 'Picked up';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.outForDelivery:
        return 'Out for delivery';
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
      this == OrderStatus.packed ||
      this == OrderStatus.readyForPickup ||
      this == OrderStatus.collected ||
      this == OrderStatus.shipped ||
      this == OrderStatus.outForDelivery ||
      this == OrderStatus.delivered ||
      this == OrderStatus.fulfilled ||
      this == OrderStatus.cancelled;

  /// Devotee may cancel only before the order ships / is ready for pickup.
  bool get canUserCancel =>
      this == OrderStatus.placed ||
      this == OrderStatus.processing ||
      this == OrderStatus.packed;

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
      case 'PACKED':
        return OrderStatus.packed;
      case 'READY_FOR_PICKUP':
      case 'READYFORPICKUP':
      case 'READY_FOR_COLLECTION':
        return OrderStatus.readyForPickup;
      case 'COLLECTED':
        return OrderStatus.collected;
      case 'SHIPPED':
      case 'DISPATCHED':
      case 'IN_TRANSIT':
        return OrderStatus.shipped;
      case 'OUT_FOR_DELIVERY':
      case 'OUTFORDELIVERY':
        return OrderStatus.outForDelivery;
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

extension FulfillmentMethodX on FulfillmentMethod {
  String get wire {
    switch (this) {
      case FulfillmentMethod.delivery:
        return 'DELIVERY';
      case FulfillmentMethod.pickup:
        return 'PICKUP';
      case FulfillmentMethod.unknown:
        return 'UNKNOWN';
    }
  }

  String get label {
    switch (this) {
      case FulfillmentMethod.delivery:
        return 'Delivery';
      case FulfillmentMethod.pickup:
        return 'Pickup';
      case FulfillmentMethod.unknown:
        return 'Unknown';
    }
  }

  bool get isPickup => this == FulfillmentMethod.pickup;
  bool get isDelivery => this == FulfillmentMethod.delivery;

  static FulfillmentMethod parse(dynamic v) {
    final s = (v ?? '').toString().toUpperCase().trim();
    switch (s) {
      case 'PICKUP':
      case 'COLLECT':
      case 'COLLECTION':
        return FulfillmentMethod.pickup;
      case 'DELIVERY':
      case 'SHIP':
      case 'SHIPPING':
        return FulfillmentMethod.delivery;
      default:
        return s.isEmpty ? FulfillmentMethod.delivery : FulfillmentMethod.unknown;
    }
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
    final product = json['productId'] ?? json['product'];
    final productId = product is Map
        ? (product['_id'] ?? product['id'] ?? '').toString()
        : (product ?? '').toString();
    return OrderLineItem(
      productId: productId,
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

/// Snapshot of the TCG rate chosen at checkout (`order.shippingQuote`).
class OrderShippingQuote {
  const OrderShippingQuote({
    required this.provider,
    required this.serviceLevelCode,
    required this.serviceLevelName,
    required this.description,
    required this.rate,
    required this.rateExcludingVat,
    required this.customerCharged,
    required this.subsidized,
    this.expiresAt,
    this.quotedAt,
  });

  final String provider;
  final String serviceLevelCode;
  final String serviceLevelName;
  final String description;
  final double rate;
  final double rateExcludingVat;
  final double customerCharged;
  final bool subsidized;
  final DateTime? expiresAt;
  final DateTime? quotedAt;

  factory OrderShippingQuote.fromJson(Map<String, dynamic> json) {
    String s(dynamic v) => (v ?? '').toString();
    return OrderShippingQuote(
      provider: s(json['provider']).isEmpty ? 'TCG' : s(json['provider']),
      serviceLevelCode: s(json['serviceLevelCode']),
      serviceLevelName: s(json['serviceLevelName']),
      description: s(json['description']),
      rate: _toDouble(json['rate']) ?? 0,
      rateExcludingVat: _toDouble(json['rateExcludingVat']) ?? 0,
      customerCharged: _toDouble(json['customerCharged']) ??
          _toDouble(json['rate']) ??
          0,
      subsidized: json['subsidized'] == true,
      expiresAt: _parseDate(json['expiresAt']),
      quotedAt: _parseDate(json['quotedAt']),
    );
  }
}

/// Warehouse pickup verification code (`order.pickupCollection`).
class PickupCollection {
  const PickupCollection({
    required this.code,
    required this.generatedAt,
  });

  final String code;
  final DateTime? generatedAt;

  bool get hasCode => code.trim().isNotEmpty;

  factory PickupCollection.fromJson(Map<String, dynamic> json) {
    return PickupCollection(
      code: (json['code'] ?? '').toString(),
      generatedAt: _parseDate(json['generatedAt']),
    );
  }
}

/// One row from `order.orderStatusHistory`.
class OrderStatusHistoryEntry {
  const OrderStatusHistoryEntry({
    required this.status,
    required this.at,
    required this.note,
  });

  final String status;
  final DateTime? at;
  final String note;

  factory OrderStatusHistoryEntry.fromJson(Map<String, dynamic> json) {
    return OrderStatusHistoryEntry(
      status: (json['status'] ?? '').toString(),
      at: _parseDate(json['at']),
      note: (json['note'] ?? '').toString(),
    );
  }
}

/// Proof-of-delivery snapshot from Courier Guy tracking (`order.delivery.pod`).
class OrderDeliveryPod {
  const OrderDeliveryPod({
    required this.status,
    required this.message,
    required this.verifiedAt,
    required this.digitalPodUrl,
    required this.imageUrls,
    required this.lastSyncedAt,
  });

  final String status;
  final String message;
  final DateTime? verifiedAt;
  final String digitalPodUrl;
  final List<String> imageUrls;
  final DateTime? lastSyncedAt;

  bool get hasStatus => status.trim().isNotEmpty;
  bool get hasDigitalPod => digitalPodUrl.trim().isNotEmpty;
  bool get hasImages => imageUrls.isNotEmpty;

  String get displayLabel {
    switch (status) {
      case 'pin_verified':
        return 'PIN verified';
      case 'image_captured':
        return 'POD image captured';
      case 'recipient_details':
        return 'Recipient details captured';
      case 'pending':
        return 'Awaiting proof of delivery';
      default:
        return message.trim().isNotEmpty ? message : 'Not available';
    }
  }

  factory OrderDeliveryPod.fromJson(Map<String, dynamic> json) {
    String s(dynamic v) => (v ?? '').toString();
    final rawImages = json['imageUrls'] ?? json['image_urls'];
    final images = <String>[];
    if (rawImages is List) {
      for (final item in rawImages) {
        final value = s(item);
        if (value.isNotEmpty) images.add(value);
      }
    }
    return OrderDeliveryPod(
      status: s(json['status']),
      message: s(json['message']),
      verifiedAt: _parseDate(json['verifiedAt']),
      digitalPodUrl: s(json['digitalPodUrl'] ?? json['digital_pod_url']),
      imageUrls: images,
      lastSyncedAt: _parseDate(json['lastSyncedAt']),
    );
  }
}

/// One Courier Guy tracking event (`order.delivery.trackingEvents`).
class DeliveryTrackingEvent {
  const DeliveryTrackingEvent({
    required this.status,
    required this.message,
    required this.date,
    required this.eventId,
  });

  final String status;
  final String message;
  final DateTime? date;
  final String eventId;

  factory DeliveryTrackingEvent.fromJson(Map<String, dynamic> json) {
    String s(dynamic v) => (v ?? '').toString();
    return DeliveryTrackingEvent(
      status: s(json['status']),
      message: s(json['message']),
      date: _parseDate(json['date']),
      eventId: s(json['eventId'] ?? json['id']),
    );
  }
}

/// Live courier shipment / waybill (`order.delivery`).
class OrderDeliveryInfo {
  const OrderDeliveryInfo({
    required this.provider,
    required this.shipmentId,
    required this.waybill,
    required this.shortTrackingReference,
    required this.labelUrl,
    required this.stickerUrl,
    required this.status,
    this.bookedAt,
    this.lastSyncedAt,
    this.podMethod = '',
    this.pod,
    this.trackingEvents = const [],
    this.collectionAddress = const DeliveryAddressSnapshot(
      label: '',
      contactName: '',
      contactPhone: '',
      contactEmail: '',
    ),
    this.deliveryAddress = const DeliveryAddressSnapshot(
      label: '',
      contactName: '',
      contactPhone: '',
      contactEmail: '',
    ),
  });

  final String provider;
  final String shipmentId;
  final String waybill;
  final String shortTrackingReference;
  final String labelUrl;
  final String stickerUrl;
  final String status;
  final DateTime? bookedAt;
  final DateTime? lastSyncedAt;
  final String podMethod;
  final OrderDeliveryPod? pod;
  final List<DeliveryTrackingEvent> trackingEvents;
  final DeliveryAddressSnapshot collectionAddress;
  final DeliveryAddressSnapshot deliveryAddress;

  bool get hasWaybill => waybill.trim().isNotEmpty;
  bool get hasLabel =>
      labelUrl.trim().isNotEmpty ||
      (shipmentId.trim().isNotEmpty && (hasWaybill || shortTrackingReference.trim().isNotEmpty));
  bool get hasPodPin => podMethod.trim().isNotEmpty;
  bool get hasPodStatus => pod?.hasStatus == true;
  bool get showCourierSection =>
      hasWaybill || hasLabel || hasPodPin || hasPodStatus;

  factory OrderDeliveryInfo.fromJson(Map<String, dynamic> json) {
    String s(dynamic v) => (v ?? '').toString();
    return OrderDeliveryInfo(
      provider: s(json['provider']).isEmpty ? 'TCG' : s(json['provider']),
      shipmentId: s(json['shipmentId']),
      waybill: s(json['waybill'] ?? json['customTrackingReference']),
      shortTrackingReference: s(json['shortTrackingReference']),
      labelUrl: s(json['labelUrl']),
      stickerUrl: s(json['stickerUrl']),
      status: s(json['status']),
      bookedAt: _parseDate(json['bookedAt']),
      lastSyncedAt: _parseDate(json['lastSyncedAt']),
      podMethod: s(json['podMethod']),
      pod: json['pod'] is Map<String, dynamic>
          ? OrderDeliveryPod.fromJson(json['pod'] as Map<String, dynamic>)
          : null,
      trackingEvents: () {
        final raw = json['trackingEvents'];
        if (raw is! List) return const <DeliveryTrackingEvent>[];
        return raw
            .whereType<Map<String, dynamic>>()
            .map(DeliveryTrackingEvent.fromJson)
            .toList(growable: false);
      }(),
      collectionAddress: DeliveryAddressSnapshot.fromJson(
        json['collectionAddress'],
      ),
      deliveryAddress: DeliveryAddressSnapshot.fromJson(
        json['deliveryAddress'],
      ),
    );
  }
}

class DeliveryAddressSnapshot {
  const DeliveryAddressSnapshot({
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

  factory DeliveryAddressSnapshot.fromJson(dynamic raw) {
    if (raw is! Map) {
      return const DeliveryAddressSnapshot(
        label: '',
        contactName: '',
        contactPhone: '',
        contactEmail: '',
      );
    }
    final m = Map<String, dynamic>.from(raw);
    return DeliveryAddressSnapshot(
      label: (m['label'] ?? m['enteredAddress'] ?? '').toString(),
      contactName: (m['contactName'] ?? m['name'] ?? '').toString(),
      contactPhone: (m['contactPhone'] ?? m['phone'] ?? '').toString(),
      contactEmail: (m['contactEmail'] ?? m['email'] ?? '').toString(),
    );
  }
}

/// Warehouse snapshot for pickup orders (`order.pickupLocation`).
class OrderPickupLocation {
  const OrderPickupLocation({
    required this.company,
    required this.streetAddress,
    required this.localArea,
    required this.city,
    required this.zone,
    required this.postalCode,
    required this.country,
    required this.enteredAddress,
    required this.contactName,
    required this.contactPhone,
    required this.contactEmail,
    required this.hours,
    required this.instructions,
  });

  final String company;
  final String streetAddress;
  final String localArea;
  final String city;
  final String zone;
  final String postalCode;
  final String country;
  final String enteredAddress;
  final String contactName;
  final String contactPhone;
  final String contactEmail;
  final String hours;
  final String instructions;

  String get singleLine {
    if (enteredAddress.trim().isNotEmpty) return enteredAddress.trim();
    final parts = <String>[
      if (company.trim().isNotEmpty) company.trim(),
      if (streetAddress.trim().isNotEmpty) streetAddress.trim(),
      if (localArea.trim().isNotEmpty) localArea.trim(),
      if (city.trim().isNotEmpty) city.trim(),
      if (postalCode.trim().isNotEmpty) postalCode.trim(),
      if (country.trim().isNotEmpty) country.trim(),
    ];
    return parts.join(', ');
  }

  factory OrderPickupLocation.fromJson(Map<String, dynamic> json) {
    String s(dynamic v) => (v ?? '').toString();
    return OrderPickupLocation(
      company: s(json['company']),
      streetAddress: s(json['streetAddress'] ?? json['street_address']),
      localArea: s(json['localArea'] ?? json['local_area']),
      city: s(json['city']),
      zone: s(json['zone']),
      postalCode: s(json['postalCode'] ?? json['code']),
      country: s(json['country']),
      enteredAddress: s(json['enteredAddress'] ?? json['entered_address']),
      contactName: s(json['contactName']),
      contactPhone: s(json['contactPhone']),
      contactEmail: s(json['contactEmail']),
      hours: s(json['hours']),
      instructions: s(json['instructions']),
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

class OrderReplacementSummary {
  const OrderReplacementSummary({
    required this.id,
    required this.requestNumber,
    required this.status,
    required this.fulfillmentMethod,
    required this.returnStatus,
    required this.returnMethod,
    required this.returnInstructions,
    required this.returnWaybill,
    required this.returnTrackingUrl,
    this.affectedProductIds = const [],
  });

  final String id;
  final String requestNumber;
  final String status;
  final String fulfillmentMethod;
  final String returnStatus;
  final String returnMethod;
  final String returnInstructions;
  final String returnWaybill;
  final String returnTrackingUrl;
  /// Product ids selected for this replacement (empty = whole order / legacy).
  final List<String> affectedProductIds;

  factory OrderReplacementSummary.fromJson(Map<String, dynamic> json) {
    final ret = json['returnShipment'];
    final returnMap = ret is Map ? Map<String, dynamic>.from(ret) : null;
    final affected = <String>[];
    final rawAffected = json['affectedItems'];
    if (rawAffected is List) {
      for (final entry in rawAffected) {
        if (entry is! Map) continue;
        final row = Map<String, dynamic>.from(entry);
        final product = row['productId'] ?? row['product'];
        final id = product is Map
            ? (product['_id'] ?? product['id'] ?? '').toString()
            : (product ?? '').toString();
        if (id.trim().isNotEmpty) affected.add(id.trim());
      }
    }
    return OrderReplacementSummary(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      requestNumber: (json['requestNumber'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      fulfillmentMethod: (json['fulfillmentMethod'] ?? '').toString(),
      returnStatus: (returnMap?['status'] ?? '').toString(),
      returnMethod: (returnMap?['method'] ?? '').toString(),
      returnInstructions: (returnMap?['instructions'] ?? '').toString(),
      returnWaybill: (returnMap?['waybill'] ?? '').toString(),
      returnTrackingUrl: (returnMap?['trackingUrl'] ?? '').toString(),
      affectedProductIds: affected,
    );
  }

  String? get userFacingStatusLabel {
    final rs = returnStatus.toUpperCase().trim();
    if (rs == 'RETURN_RECEIVED') return 'Returned';
    if (rs == 'RETURN_BOOKED' || rs == 'RETURN_IN_TRANSIT') {
      return 'Return in transit';
    }

    switch (status.toUpperCase().trim()) {
      case 'REQUESTED':
      case 'PENDING':
        return 'Replacement requested';
      case 'APPROVED':
      case 'AWAITING_RETURN':
        return 'Awaiting return';
      case 'RETURN_RECEIVED':
        return 'Returned';
      case 'PROCESSING':
        return 'Replacement processing';
      case 'SHIPPED':
        return 'Replacement shipped';
      case 'DELIVERED':
        return 'Replacement completed';
      case 'REJECTED':
        return 'Replacement rejected';
      case 'CANCELLED':
        return 'Replacement cancelled';
      default:
        if (rs == 'AWAITING_RETURN') return 'Awaiting return';
        return null;
    }
  }

  String get userFacingStatusTone {
    final rs = returnStatus.toUpperCase().trim();
    if (rs == 'RETURN_RECEIVED' || status.toUpperCase() == 'RETURN_RECEIVED') {
      return 'returned';
    }
    if (rs == 'RETURN_BOOKED' || rs == 'RETURN_IN_TRANSIT') {
      return 'return_transit';
    }
    switch (status.toUpperCase().trim()) {
      case 'REQUESTED':
      case 'PENDING':
        return 'requested';
      case 'APPROVED':
      case 'AWAITING_RETURN':
        return 'awaiting_return';
      case 'PROCESSING':
      case 'SHIPPED':
        return 'in_progress';
      case 'DELIVERED':
        return 'completed';
      case 'REJECTED':
      case 'CANCELLED':
        return 'rejected';
      default:
        return 'in_progress';
    }
  }
}

class AdminOrder {
  const AdminOrder({
    required this.id,
    required this.orderNumber,
    required this.orderStatus,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.paymentReference,
    this.transactionId,
    this.payfastPaymentId,
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
    this.fulfillmentMethod = FulfillmentMethod.delivery,
    this.shippingQuote,
    this.delivery,
    this.pickupLocation,
    this.pickupCollection,
    this.replacementState = 'NONE',
    this.latestReplacementRequestId = '',
    this.latestReplacementRequest,
    this.orderType = 'NORMAL',
    this.parentOrderNumber = '',
    this.orderStatusHistory = const [],
  });

  final String id;
  final String orderNumber;
  final OrderStatus orderStatus;
  final PaymentStatus paymentStatus;
  final String paymentMethod;
  final String paymentReference;
  final String? transactionId;
  final String? payfastPaymentId;
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
  final FulfillmentMethod fulfillmentMethod;
  final OrderShippingQuote? shippingQuote;
  final OrderDeliveryInfo? delivery;
  final OrderPickupLocation? pickupLocation;
  final PickupCollection? pickupCollection;
  /// Original-order replacement summary: NONE | REQUESTED | IN_PROGRESS | …
  final String replacementState;
  final String latestReplacementRequestId;
  /// Populated summary from `latestReplacementRequest` when available.
  final OrderReplacementSummary? latestReplacementRequest;
  final String orderType;
  final String parentOrderNumber;
  final List<OrderStatusHistoryEntry> orderStatusHistory;

  bool get hasTracking => tracking?.hasTrackingNumber == true;
  bool get hasCourierTracking =>
      hasTracking || delivery?.hasWaybill == true;

  String get courierLabel {
    final fromTracking = tracking?.courier.trim() ?? '';
    if (fromTracking.isNotEmpty) return fromTracking;
    if (delivery?.provider == 'TCG') return 'The Courier Guy';
    return delivery?.provider.trim() ?? '';
  }

  String get courierTrackingNumber {
    final fromTracking = tracking?.trackingNumber.trim() ?? '';
    if (fromTracking.isNotEmpty) return fromTracking;
    return delivery?.waybill.trim() ?? '';
  }

  String get courierTrackingUrl => tracking?.trackingUrl.trim() ?? '';
  bool get isPickup => fulfillmentMethod.isPickup;
  bool get isDelivery => fulfillmentMethod.isDelivery;
  bool get hasPickupCollectionCode => pickupCollection?.hasCode == true;

  /// True when the customer submitted post-fulfilment feedback.
  bool get hasCustomerFulfillmentFeedback {
    final f = fulfillment;
    if (f == null) return false;
    return f.satisfied != null ||
        f.feedback.trim().isNotEmpty ||
        f.ratedAt != null;
  }

  bool get hasOpenReplacement {
    final s = replacementState.toUpperCase().trim();
    return s == 'REQUESTED' || s == 'APPROVED' || s == 'IN_PROGRESS';
  }

  /// Original order: customer still needs to return the damaged item.
  bool get needsUserReturn {
    if (isReplacementOrder) return false;
    final summary = latestReplacementRequest;
    if (summary != null) {
      final rs = summary.returnStatus.toUpperCase().trim();
      if (rs == 'RETURN_RECEIVED') return false;
      if (rs == 'AWAITING_RETURN' ||
          rs == 'RETURN_BOOKED' ||
          rs == 'RETURN_IN_TRANSIT') {
        return true;
      }
      final st = summary.status.toUpperCase().trim();
      if (st == 'AWAITING_RETURN' || st == 'APPROVED') return true;
    }
    final state = replacementState.toUpperCase().trim();
    return state == 'IN_PROGRESS' || state == 'APPROVED';
  }

  bool get isReplacementOrder =>
      orderType.toUpperCase().trim() == 'REPLACEMENT';

  /// User-facing replacement / return status for chips (null = hide).
  String? get replacementStatusLabel {
    if (isReplacementOrder) {
      final parent = parentOrderNumber.trim();
      return parent.isEmpty ? 'Replacement order' : 'Replacement of $parent';
    }
    final summary = latestReplacementRequest;
    if (summary != null) {
      final label = summary.userFacingStatusLabel;
      if (label != null) return label;
    }
    switch (replacementState.toUpperCase().trim()) {
      case 'REQUESTED':
        return 'Replacement requested';
      case 'APPROVED':
      case 'IN_PROGRESS':
        return 'Awaiting return';
      case 'COMPLETED':
        return 'Returned';
      case 'REJECTED':
        return 'Replacement rejected';
      default:
        return null;
    }
  }

  /// Wire key for tinting status chips in UI.
  String get replacementStatusTone {
    if (isReplacementOrder) return 'replacement_order';
    final summary = latestReplacementRequest;
    if (summary != null) return summary.userFacingStatusTone;
    switch (replacementState.toUpperCase().trim()) {
      case 'REQUESTED':
        return 'requested';
      case 'APPROVED':
      case 'IN_PROGRESS':
        return 'awaiting_return';
      case 'COMPLETED':
        return 'returned';
      case 'REJECTED':
        return 'rejected';
      default:
        return 'none';
    }
  }

  /// PayFast pf_payment_id (numeric), when payment has settled.
  String get resolvedPayfastPaymentId =>
      (payfastPaymentId ?? transactionId ?? '').trim();

  /// PayFast reported a successful charge; fulfilment actions apply.
  bool get isPaymentPaid => paymentStatus == PaymentStatus.paid;

  /// Admin can verify customer PIN and mark order as picked up (COLLECTED).
  bool get canAdminCompletePickup {
    if (!isPickup || !isPaymentPaid) return false;
    switch (orderStatus) {
      case OrderStatus.placed:
      case OrderStatus.processing:
      case OrderStatus.packed:
      case OrderStatus.readyForPickup:
        return true;
      default:
        return false;
    }
  }

  /// User may rate / confirm after delivery or warehouse pickup.
  bool get canUserConfirmFulfillment {
    if (orderStatus == OrderStatus.fulfilled ||
        orderStatus == OrderStatus.cancelled) {
      return false;
    }
    if (isPickup && orderStatus == OrderStatus.collected) return true;
    if (isDelivery && orderStatus == OrderStatus.delivered) return true;
    return false;
  }

  /// Post-fulfilment return / replace (pickup: after collection; delivery: after delivery).
  bool get canUserRequestReturnOrReplace {
    if (isPickup) {
      if (orderStatus != OrderStatus.collected &&
          orderStatus != OrderStatus.fulfilled) {
        return false;
      }
    } else {
      if (orderStatus != OrderStatus.delivered &&
          orderStatus != OrderStatus.fulfilled) {
        return false;
      }
    }
    if (paymentStatus == PaymentStatus.refundInitiated ||
        paymentStatus == PaymentStatus.refunded) {
      return false;
    }
    return paymentStatus == PaymentStatus.paid ||
        paymentStatus == PaymentStatus.refundFailed;
  }

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

  /// Formatted currency string using the API currency code, e.g. `ZAR 250`.
  String get formattedTotal => _formatCurrency(totalAmount, currency);
  String get formattedSubtotal => _formatCurrency(subtotalAmount, currency);
  String get formattedShipping => _formatCurrency(shippingAmount, currency);
  String get formattedTax => _formatCurrency(taxAmount, currency);

  /// TCG rate the customer selected at checkout (`shippingQuote.rate`).
  double get selectedCourierRate => shippingQuote?.rate ?? 0;

  /// What the customer actually paid for delivery (`deliveryCharge`).
  double get customerDeliveryCharge =>
      shippingQuote?.customerCharged ?? shippingAmount;

  String get formattedSelectedCourierRate =>
      _formatCurrency(selectedCourierRate, currency);

  String get formattedCustomerDeliveryCharge =>
      _formatCurrency(customerDeliveryCharge, currency);

  bool get deliveryWasSubsidized =>
      shippingQuote?.subsidized == true ||
      (selectedCourierRate > 0 && customerDeliveryCharge < selectedCourierRate);

  String get selectedCourierServiceLabel {
    final q = shippingQuote;
    if (q == null) return '';
    if (q.serviceLevelName.isNotEmpty && q.serviceLevelCode.isNotEmpty) {
      return '${q.serviceLevelName} (${q.serviceLevelCode})';
    }
    if (q.serviceLevelName.isNotEmpty) return q.serviceLevelName;
    return q.serviceLevelCode;
  }

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
    final dedupedItems = _mergeDuplicateItems(items);

    return AdminOrder(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      orderNumber: (json['orderNumber'] ?? '').toString(),
      orderStatus: OrderStatusX.parseFromOrderJson(json),
      paymentStatus: PaymentStatusX.parse(json['paymentStatus']),
      paymentMethod: (json['paymentMethod'] ?? '').toString(),
      paymentReference:
          (json['paymentReference'] ??
                  json['payfastReference'] ??
                  json['paystackReference'] ??
                  json['reference'] ??
                  '')
              .toString(),
      transactionId: _nullableStr(json['transactionId']),
      payfastPaymentId: _nullableStr(
        json['payfastPaymentId'] ?? json['transactionId'],
      ),
      currency:
          (json['currency'] ?? 'ZAR').toString().toUpperCase().trim().isEmpty
          ? 'ZAR'
          : (json['currency'] ?? 'ZAR').toString().toUpperCase().trim(),
      totalAmount: _toDouble(json['totalAmount'] ?? json['total']) ?? 0,
      subtotalAmount:
          _toDouble(json['subtotalAmount'] ?? json['subtotal']) ?? 0,
      shippingAmount:
          _toDouble(
            json['deliveryCharge'] ??
                json['delivery_charge'] ??
                json['shippingAmount'] ??
                json['shipping_charge'],
          ) ??
          0,
      taxAmount: _toDouble(json['taxAmount']) ?? 0,
      createdAt: _parseDate(json['createdAt']),
      dispatchedAt: _parseDate(json['dispatchedAt']),
      sharedWithUserAt: _parseDate(json['sharedWithUserAt']),
      items: dedupedItems,
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
      fulfillmentMethod: FulfillmentMethodX.parse(json['fulfillmentMethod']),
      shippingQuote: () {
        final raw = json['shippingQuote'];
        if (raw is! Map) return null;
        final map = Map<String, dynamic>.from(raw);
        // Ignore empty mongoose defaults with no selected service.
        final code = (map['serviceLevelCode'] ?? '').toString().trim();
        final rate = _toDouble(map['rate']) ?? 0;
        if (code.isEmpty && rate <= 0) return null;
        return OrderShippingQuote.fromJson(map);
      }(),
      delivery: json['delivery'] is Map<String, dynamic>
          ? OrderDeliveryInfo.fromJson(
              json['delivery'] as Map<String, dynamic>,
            )
          : null,
      pickupLocation: () {
        final raw = json['pickupLocation'];
        if (raw is! Map) return null;
        return OrderPickupLocation.fromJson(Map<String, dynamic>.from(raw));
      }(),
      pickupCollection: json['pickupCollection'] is Map<String, dynamic>
          ? PickupCollection.fromJson(
              json['pickupCollection'] as Map<String, dynamic>,
            )
          : null,
      replacementState: (json['replacementState'] ?? 'NONE').toString(),
      latestReplacementRequestId: () {
        final raw = json['latestReplacementRequest'];
        if (raw is Map) {
          return (raw['_id'] ?? raw['id'] ?? '').toString();
        }
        return (raw ?? '').toString();
      }(),
      latestReplacementRequest: () {
        final raw = json['latestReplacementRequest'];
        if (raw is! Map) return null;
        return OrderReplacementSummary.fromJson(
          Map<String, dynamic>.from(raw),
        );
      }(),
      orderType: (json['orderType'] ?? 'NORMAL').toString(),
      parentOrderNumber: (json['parentOrderNumber'] ?? '').toString(),
      orderStatusHistory: () {
        final raw = json['orderStatusHistory'];
        if (raw is! List) return const <OrderStatusHistoryEntry>[];
        return raw
            .whereType<Map<String, dynamic>>()
            .map(OrderStatusHistoryEntry.fromJson)
            .toList(growable: false);
      }(),
    );
  }

  DateTime? historyAt(String statusWire) {
    final target = statusWire.toUpperCase().trim();
    for (final entry in orderStatusHistory.reversed) {
      if (entry.status.toUpperCase().trim() == target && entry.at != null) {
        return entry.at;
      }
    }
    return null;
  }

  /// Some endpoints (e.g. PayFast verify) return an order without a populated
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
      paymentReference: paymentReference,
      transactionId: transactionId,
      payfastPaymentId: payfastPaymentId,
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
      fulfillmentMethod: fulfillmentMethod,
      shippingQuote: shippingQuote,
      delivery: delivery,
      pickupLocation: pickupLocation,
      pickupCollection: pickupCollection,
      replacementState: replacementState,
      latestReplacementRequestId: latestReplacementRequestId,
      latestReplacementRequest: latestReplacementRequest,
      orderType: orderType,
      parentOrderNumber: parentOrderNumber,
      orderStatusHistory: orderStatusHistory,
    );
  }
}

List<OrderLineItem> _mergeDuplicateItems(List<OrderLineItem> items) {
  final merged = <String, OrderLineItem>{};
  for (final item in items) {
    final key = [
      item.productId.trim(),
      item.title.trim().toLowerCase(),
      item.unitPrice.toStringAsFixed(2),
    ].join('|');
    final existing = merged[key];
    if (existing == null) {
      merged[key] = item;
    } else {
      merged[key] = OrderLineItem(
        productId: existing.productId,
        title: existing.title,
        qty: existing.qty + item.qty,
        unitPrice: existing.unitPrice,
        lineTotal: existing.lineTotal + item.lineTotal,
        image: existing.image.isNotEmpty ? existing.image : item.image,
      );
    }
  }
  return merged.values.toList();
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
    FulfillmentMethod fulfillmentMethod = FulfillmentMethod.delivery,
  }) {
    final isPickup = fulfillmentMethod.isPickup;
    switch (current) {
      case OrderStatus.placed:
        return const [OrderStatus.processing, OrderStatus.cancelled];
      case OrderStatus.processing:
        if (isPickup) {
          return const [
            OrderStatus.packed,
            OrderStatus.readyForPickup,
            OrderStatus.cancelled,
          ];
        }
        return [
          if (hasTrackingNumber) OrderStatus.shipped,
          OrderStatus.cancelled,
        ];
      case OrderStatus.packed:
        if (isPickup) {
          return const [OrderStatus.readyForPickup, OrderStatus.cancelled];
        }
        return const [];
      case OrderStatus.readyForPickup:
        return const [];
      case OrderStatus.collected:
        return const [];
      case OrderStatus.shipped:
        return const [OrderStatus.outForDelivery, OrderStatus.delivered];
      case OrderStatus.outForDelivery:
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
    return s == OrderStatus.placed ||
        s == OrderStatus.processing ||
        s == OrderStatus.packed;
  }
}

String? _nullableStr(dynamic v) {
  final s = (v ?? '').toString().trim();
  return s.isEmpty ? null : s;
}

String _formatCurrency(double amount, String currency) {
  final symbol = currency.trim().isEmpty ? 'ZAR' : currency.toUpperCase();
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
