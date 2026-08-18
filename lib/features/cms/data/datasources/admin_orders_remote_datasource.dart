// Remote datasource for the admin orders / requests / payments features.
//
// Wraps the endpoints defined in [ApiEndpoints]:
//   • GET    /orders/all
//   • GET    /orders/:id
//   • PATCH  /orders/:id/status
//   • PATCH  /orders/:id/payment
//   • PATCH  /orders/:id/tracking
//   • POST   /orders/:id/dispatch
//   • POST   /orders/:id/cancel-paid
//   • GET    /orders/requests
//   • GET    /admin/replacements
//   • GET    /admin/replacements/:id
//   • POST   /admin/replacements/:id/approve
//   • POST   /admin/replacements/:id/reject
//   • GET    /payments/verify/:reference   (re-used from donations flow)
import 'package:dio/dio.dart';
import 'package:satya_devotte_app/core/network/api_client.dart';
import 'package:satya_devotte_app/core/network/api_endpoints.dart';
import 'package:satya_devotte_app/features/cms/data/models/admin_order_models.dart';
import 'package:satya_devotte_app/features/cms/data/models/admin_order_request_models.dart';

class AdminOrdersRemoteDataSource {
  AdminOrdersRemoteDataSource(this._apiClient);
  final ApiClient _apiClient;

  // ────────────────────────────── Orders ──────────────────────────────

  /// `GET /orders/all` — paginated.
  Future<AdminOrdersPage> getAllOrders({
    int page = 1,
    int limit = 10,
    String? orderStatus,
    String? paymentStatus,
    String? user,
    String? search,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (orderStatus != null && orderStatus.isNotEmpty)
        'orderStatus': orderStatus,
      if (paymentStatus != null && paymentStatus.isNotEmpty)
        'paymentStatus': paymentStatus,
      if (user != null && user.isNotEmpty) 'user': user,
      if (search != null && search.isNotEmpty) 'search': search,
    };
    final res = await _apiClient.dio.get(
      ApiEndpoints.allOrders,
      queryParameters: query,
    );
    final body = _asMap(res.data);
    final rawItems = _extractItems(body);
    final orders = rawItems
        .whereType<Map<String, dynamic>>()
        .map(AdminOrder.fromJson)
        .toList(growable: false);

    final pagination = _extractPagination(body, page, limit, orders.length);

    return AdminOrdersPage(
      items: orders,
      page: pagination.page,
      limit: pagination.limit,
      total: pagination.total,
      totalPages: pagination.totalPages,
    );
  }

  /// `GET /payments/all` — paginated payments inbox (admin).
  Future<AdminOrdersPage> getAllPayments({
    int page = 1,
    int limit = 10,
    String? paymentStatus,
    String? search,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (paymentStatus != null && paymentStatus.isNotEmpty)
        'paymentStatus': paymentStatus,
      if (search != null && search.isNotEmpty) 'search': search,
    };
    final res = await _apiClient.dio.get(
      ApiEndpoints.allPayments,
      queryParameters: query,
    );
    final body = _asMap(res.data);
    final rawItems = _extractItems(body);
    final orders = rawItems
        .whereType<Map<String, dynamic>>()
        .map(_normalizePaymentListJson)
        .map(AdminOrder.fromJson)
        .toList(growable: false);

    final pagination = _extractPagination(body, page, limit, orders.length);

    return AdminOrdersPage(
      items: orders,
      page: pagination.page,
      limit: pagination.limit,
      total: pagination.total,
      totalPages: pagination.totalPages,
    );
  }

  /// `GET /orders/:id`
  Future<AdminOrder> getOrder(String id) async {
    final res = await _apiClient.dio.get(ApiEndpoints.order(id));
    return AdminOrder.fromJson(_unwrapOrder(res.data));
  }

  /// `PATCH /orders/:id/status`
  Future<AdminOrder> updateStatus(
    String id, {
    required OrderStatus status,
    String? note,
  }) async {
    final res = await _apiClient.dio.patch(
      ApiEndpoints.orderStatus(id),
      data: {
        'status': status.wire,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );
    return AdminOrder.fromJson(_unwrapOrder(res.data));
  }

  /// `PATCH /orders/:id/payment` — admin-only payment field overrides.
  Future<AdminOrder> updatePayment(
    String id, {
    PaymentStatus? paymentStatus,
    String? paymentMethod,
  }) async {
    final res = await _apiClient.dio.patch(
      ApiEndpoints.orderPayment(id),
      data: {
        if (paymentStatus != null) 'paymentStatus': paymentStatus.wire,
        if (paymentMethod != null && paymentMethod.isNotEmpty)
          'paymentMethod': paymentMethod,
      },
    );
    return AdminOrder.fromJson(_unwrapOrder(res.data));
  }

  /// `PATCH /orders/:id/tracking` — set tracking without flipping status.
  Future<AdminOrder> updateTracking(
    String id, {
    required String courier,
    required String trackingNumber,
    String? trackingUrl,
  }) async {
    final res = await _apiClient.dio.patch(
      ApiEndpoints.orderTracking(id),
      data: {
        'courier': courier,
        'trackingNumber': trackingNumber,
        if (trackingUrl != null && trackingUrl.isNotEmpty)
          'trackingUrl': trackingUrl,
      },
    );
    return AdminOrder.fromJson(_unwrapOrder(res.data));
  }

  /// `POST /orders/:id/dispatch` — book TCG (empty body / bookCourier) OR
  /// set manual tracking AND mark `SHIPPED`.
  Future<AdminOrder> dispatchOrder(
    String id, {
    String? courier,
    String? trackingNumber,
    String? trackingUrl,
    String? note,
    bool bookCourier = false,
  }) async {
    final hasManual = (courier ?? '').trim().isNotEmpty &&
        (trackingNumber ?? '').trim().isNotEmpty;
    final res = await _apiClient.dio.post(
      ApiEndpoints.orderDispatch(id),
      data: hasManual
          ? {
              'courier': courier!.trim(),
              'trackingNumber': trackingNumber!.trim(),
              if (trackingUrl != null && trackingUrl.isNotEmpty)
                'trackingUrl': trackingUrl,
              if (note != null && note.isNotEmpty) 'note': note,
              'bookCourier': false,
            }
          : {
              if (note != null && note.isNotEmpty) 'note': note,
              'bookCourier': bookCourier,
            },
    );
    return AdminOrder.fromJson(_unwrapOrder(res.data));
  }

  /// `POST /orders/:id/ready-for-pickup` — pickup only → READY_FOR_PICKUP.
  Future<AdminOrder> readyForPickup(String id, {String? note}) async {
    final res = await _apiClient.dio.post(
      ApiEndpoints.orderReadyForPickup(id),
      data: {
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );
    return AdminOrder.fromJson(_unwrapOrder(res.data));
  }

  /// `POST /orders/:id/packed` — pickup only → PACKED.
  Future<AdminOrder> markPacked(String id, {String? note}) async {
    final res = await _apiClient.dio.post(
      ApiEndpoints.orderPacked(id),
      data: {
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );
    return AdminOrder.fromJson(_unwrapOrder(res.data));
  }

  /// `POST /orders/:id/verify-pickup` — admin enters customer PIN → FULFILLED.
  Future<AdminOrder> verifyPickup(String id, {required String pin}) async {
    final res = await _apiClient.dio.post(
      ApiEndpoints.orderVerifyPickup(id),
      data: {'pin': pin.trim()},
    );
    return AdminOrder.fromJson(_unwrapOrder(res.data));
  }

  /// `POST /orders/:id/sync-delivery-pod` — refresh Courier Guy POD status.
  Future<AdminOrder> syncDeliveryPod(String id) async {
    final res = await _apiClient.dio.post(
      ApiEndpoints.orderSyncDeliveryPod(id),
    );
    return AdminOrder.fromJson(_unwrapOrder(res.data));
  }

  /// `GET /orders/:id/shipping-label` — PDF bytes proxied from ShipLogic.
  Future<List<int>> downloadShippingLabelPdf(String id) async {
    final res = await _apiClient.dio.get<List<int>>(
      ApiEndpoints.orderShippingLabel(id),
      options: Options(
        responseType: ResponseType.bytes,
        followRedirects: false,
        validateStatus: (status) => status != null && status >= 200 && status < 300,
      ),
    );
    final bytes = res.data;
    if (bytes == null || bytes.isEmpty) {
      throw DioException(
        requestOptions: res.requestOptions,
        message: 'Shipping label PDF was empty',
      );
    }
    final contentType = (res.headers.value('content-type') ?? '').toLowerCase();
    if (contentType.contains('json') || contentType.contains('text/html')) {
      throw DioException(
        requestOptions: res.requestOptions,
        message: 'Shipping label endpoint did not return a PDF',
      );
    }
    return bytes;
  }

  /// `GET /orders/:id/shipping-label-url` — signed Courier Guy label PDF URL.
  Future<String> fetchShippingLabelUrl(String id) async {
    final res = await _apiClient.dio.get(
      ApiEndpoints.orderShippingLabelUrl(id),
    );
    final root = res.data;
    final data = root is Map<String, dynamic>
        ? (root['data'] as Map<String, dynamic>? ?? root)
        : <String, dynamic>{};
    final url = (data['url'] ?? '').toString().trim();
    if (url.isEmpty) {
      throw DioException(
        requestOptions: res.requestOptions,
        message: 'Shipping label URL was not returned',
      );
    }
    return url;
  }

  /// `POST /orders/:id/cancel-paid` — terminal admin cancel.
  Future<AdminOrder> cancelOrder(String id, {String? reason}) async {
    final res = await _apiClient.dio.post(
      ApiEndpoints.orderCancelPaid(id),
      data: {
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      },
    );
    return AdminOrder.fromJson(_unwrapOrder(res.data));
  }

  /// `POST /orders/:id/refund` — admin initiate refund.
  Future<AdminOrder> initiateRefund(
    String orderId, {
    required String reason,
    String? adminNote,
  }) async {
    final res = await _apiClient.dio.post(
      ApiEndpoints.orderRefund(orderId),
      data: {
        'reason': reason,
        if (adminNote != null && adminNote.isNotEmpty) 'adminNote': adminNote,
      },
    );
    return AdminOrder.fromJson(_unwrapOrder(res.data));
  }

  // ───────────────────────── Order requests ───────────────────────────

  /// `GET /orders/requests` — paginated requests inbox.
  Future<OrderRequestsPage> getOrderRequests({
    int page = 1,
    int limit = 10,
    String? status,
    String? type,
    String? user,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (status != null && status.isNotEmpty) 'status': status,
      if (type != null && type.isNotEmpty) 'type': type,
      if (user != null && user.isNotEmpty) 'user': user,
    };
    final res = await _apiClient.dio.get(
      ApiEndpoints.orderRequests,
      queryParameters: query,
    );
    final body = _asMap(res.data);
    final rawItems = _extractItems(body);
    final requests = rawItems
        .whereType<Map<String, dynamic>>()
        .map(OrderRequest.fromJson)
        .toList(growable: false);

    final pagination = _extractPagination(body, page, limit, requests.length);

    return OrderRequestsPage(
      items: requests,
      page: pagination.page,
      limit: pagination.limit,
      total: pagination.total,
      totalPages: pagination.totalPages,
    );
  }

  /// `GET /orders/requests/:id`
  Future<OrderRequest> getOrderRequest(String id) async {
    final res = await _apiClient.dio.get(ApiEndpoints.orderRequestById(id));
    return OrderRequest.fromJson(_unwrapRequest(res.data));
  }

  /// `POST /orders/requests/:id/approve`
  Future<ApproveOrderRequestResult> approveOrderRequest(
    String id, {
    String? adminNote,
  }) async {
    final res = await _apiClient.dio.post(
      ApiEndpoints.approveOrderRequest(id),
      data: {
        if (adminNote != null && adminNote.isNotEmpty) 'adminNote': adminNote,
      },
    );
    final body = _asMap(res.data);
    final message = body['message']?.toString();
    return ApproveOrderRequestResult(
      request: OrderRequest.fromJson(_unwrapRequest(res.data)),
      message: message != null && message.isNotEmpty ? message : null,
    );
  }

  /// `POST /orders/requests/:id/reject`
  Future<OrderRequest> rejectOrderRequest(
    String id, {
    String? adminNote,
  }) async {
    final res = await _apiClient.dio.post(
      ApiEndpoints.rejectOrderRequest(id),
      data: {
        if (adminNote != null && adminNote.isNotEmpty) 'adminNote': adminNote,
      },
    );
    return OrderRequest.fromJson(_unwrapRequest(res.data));
  }

  /// `POST /orders/requests/:id/book-return`
  Future<OrderRequest> bookOrderRequestReturn(String id) async {
    final res = await _apiClient.dio.post(
      ApiEndpoints.bookOrderRequestReturn(id),
    );
    return OrderRequest.fromJson(_unwrapRequest(res.data));
  }

  /// `POST /orders/requests/:id/mark-return-received`
  Future<ApproveOrderRequestResult> markOrderRequestReturnReceived(
    String id,
  ) async {
    final res = await _apiClient.dio.post(
      ApiEndpoints.markOrderRequestReturnReceived(id),
    );
    final body = _asMap(res.data);
    final message = body['message']?.toString();
    return ApproveOrderRequestResult(
      request: OrderRequest.fromJson(_unwrapRequest(res.data)),
      message: message != null && message.isNotEmpty ? message : null,
    );
  }

  /// `POST /orders/requests/:id/sync-return` — refresh TCG return tracking.
  Future<ApproveOrderRequestResult> syncOrderRequestReturn(String id) async {
    final res = await _apiClient.dio.post(
      ApiEndpoints.syncOrderRequestReturn(id),
    );
    final body = _asMap(res.data);
    final message = body['message']?.toString();
    return ApproveOrderRequestResult(
      request: OrderRequest.fromJson(_unwrapRequest(res.data)),
      message: message != null && message.isNotEmpty ? message : null,
    );
  }

  /// `GET /admin/replacements` — paginated replacement requests.
  Future<OrderRequestsPage> getReplacements({
    int page = 1,
    int limit = 20,
    String? status,
    String? search,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (status != null && status.isNotEmpty) 'status': status,
      if (search != null && search.isNotEmpty) 'search': search,
    };
    final res = await _apiClient.dio.get(
      ApiEndpoints.adminReplacements,
      queryParameters: query,
    );
    final body = _asMap(res.data);
    final rawItems = _extractItems(body);
    final requests = rawItems
        .whereType<Map<String, dynamic>>()
        .map(OrderRequest.fromReplacementJson)
        .toList(growable: false);

    final pagination = _extractPagination(body, page, limit, requests.length);

    return OrderRequestsPage(
      items: requests,
      page: pagination.page,
      limit: pagination.limit,
      total: pagination.total,
      totalPages: pagination.totalPages,
    );
  }

  /// `GET /admin/replacements/:id`
  Future<OrderRequest> getReplacementRequest(String id) async {
    final res = await _apiClient.dio.get(
      ApiEndpoints.orderReplacementRequest(id),
    );
    return OrderRequest.fromReplacementJson(_unwrapRequest(res.data));
  }

  /// `POST /admin/replacements/:id/approve`
  Future<OrderRequest> approveReplacementRequest(
    String id, {
    String? adminNote,
  }) async {
    final res = await _apiClient.dio.put(
      ApiEndpoints.approveReplacementRequest(id),
      data: {
        if (adminNote != null && adminNote.isNotEmpty) 'adminNote': adminNote,
      },
    );
    return OrderRequest.fromReplacementJson(_unwrapRequest(res.data));
  }

  /// `POST /admin/replacements/:id/reject`
  Future<OrderRequest> rejectReplacementRequest(
    String id, {
    String? adminNote,
  }) async {
    final res = await _apiClient.dio.put(
      ApiEndpoints.rejectReplacementRequest(id),
      data: {
        if (adminNote != null && adminNote.isNotEmpty) 'adminNote': adminNote,
      },
    );
    return OrderRequest.fromReplacementJson(_unwrapRequest(res.data));
  }

  /// `POST /admin/replacements/:id/book-return`
  Future<OrderRequest> bookReplacementReturn(String id) async {
    final res = await _apiClient.dio.post(
      ApiEndpoints.bookReplacementReturn(id),
    );
    return OrderRequest.fromReplacementJson(_unwrapRequest(res.data));
  }

  /// `POST /admin/replacements/:id/mark-return-received`
  Future<OrderRequest> markReplacementReturnReceived(String id) async {
    final res = await _apiClient.dio.post(
      ApiEndpoints.markReplacementReturnReceived(id),
    );
    return OrderRequest.fromReplacementJson(_unwrapRequest(res.data));
  }

  // ────────────────────────────── Payments ────────────────────────────

  /// Merges a payment list row with its populated `order` for [AdminOrder.fromJson].
  Map<String, dynamic> _normalizePaymentListJson(Map<String, dynamic> json) {
    final order = json['order'];
    if (order is Map<String, dynamic>) {
      final merged = Map<String, dynamic>.from(order);
      void copyIfMissing(String key, dynamic value) {
        if (value == null) return;
        final existing = merged[key];
        if (existing == null ||
            (existing is String && existing.trim().isEmpty)) {
          merged[key] = value;
        }
      }
      copyIfMissing('paymentStatus', json['paymentStatus']);
      copyIfMissing('paymentMethod', json['paymentMethod']);
      copyIfMissing(
        'paymentReference',
        json['paymentReference'] ??
            json['payfastReference'] ??
            json['paystackReference'] ??
            json['reference'],
      );
      copyIfMissing('totalAmount', json['totalAmount'] ?? json['amount']);
      copyIfMissing('currency', json['currency']);
      copyIfMissing('createdAt', json['createdAt']);
      copyIfMissing('orderNumber', json['orderNumber']);
      return merged;
    }
    final flat = Map<String, dynamic>.from(json);
    final orderId = flat['orderId'];
    if (orderId != null) {
      final id = orderId.toString();
      if ((flat['_id'] ?? flat['id'] ?? '').toString().isEmpty) {
        flat['_id'] = id;
      }
    }
    return flat;
  }

  /// `GET /payments/verify/:reference` — admin-triggered idempotent verify.
  /// Returns the updated [AdminOrder] when the server attaches one,
  /// otherwise `null`.
  Future<AdminOrder?> verifyPayment(String reference) async {
    final res = await _apiClient.dio.get(ApiEndpoints.verifyPayment(reference));
    // The verify response can be `{ data: { order: {...} } }`, `{ order: {...} }`
    // or the order doc itself. Hand both layers to [_unwrapOrder] and bail out
    // if no order-like map is present.
    final candidate = _unwrapOrder(res.data);
    if (candidate['_id'] == null && candidate['orderNumber'] == null) {
      return null;
    }
    return AdminOrder.fromJson(candidate);
  }

  // ─────────────────────────── helpers ────────────────────────────────

  Map<String, dynamic> _asMap(dynamic v) =>
      v is Map<String, dynamic> ? v : const <String, dynamic>{};

  /// Single-resource unwrap. The Satya backend wraps single-document responses
  /// as `{ success, data: { order: {...} } }` for orders, and
  /// `{ success, data: { request: {...} } }` (or `orderRequest`) for requests.
  /// Some endpoints flatten that to `{ data: {...} }` or even return the doc
  /// inline — handle every shape here so callers receive the actual document.
  Map<String, dynamic> _unwrapOrder(dynamic raw) =>
      _peelSingleResource(raw, const ['order']);

  Map<String, dynamic> _unwrapRequest(dynamic raw) => _peelSingleResource(
        raw,
        const [
          'request',
          'orderRequest',
          'replacement',
          'replacementRequest',
        ],
      );

  Map<String, dynamic> _peelSingleResource(
    dynamic raw,
    List<String> resourceKeys,
  ) {
    final body = _asMap(raw);

    Map<String, dynamic> pickFrom(Map<String, dynamic> map) {
      for (final k in resourceKeys) {
        final v = map[k];
        if (v is Map<String, dynamic>) return v;
      }
      // Generic single-resource keys some endpoints use.
      for (final k in const ['result', 'record', 'item']) {
        final v = map[k];
        if (v is Map<String, dynamic>) return v;
      }
      return map;
    }

    final data = body['data'];
    if (data is Map<String, dynamic>) {
      return pickFrom(data);
    }
    return pickFrom(body);
  }

  /// Items may live under `data.items`, `data` (list) or top-level keys.
  List<dynamic> _extractItems(Map<String, dynamic> body) {
    final data = body['data'];
    if (data is Map<String, dynamic>) {
      if (data['items'] is List) return data['items'] as List;
      if (data['orders'] is List) return data['orders'] as List;
      if (data['requests'] is List) return data['requests'] as List;
      if (data['replacements'] is List) return data['replacements'] as List;
      if (data['payments'] is List) return data['payments'] as List;
    }
    if (data is List) return data;
    for (final k in const [
      'items',
      'orders',
      'payments',
      'requests',
      'replacements',
      'results',
    ]) {
      if (body[k] is List) return body[k] as List;
    }
    return const <dynamic>[];
  }

  _Pagination _extractPagination(
    Map<String, dynamic> body,
    int requestedPage,
    int requestedLimit,
    int itemsCount,
  ) {
    final data = body['data'];
    final dataMap =
        data is Map<String, dynamic> ? data : const <String, dynamic>{};
    final pagination = dataMap['pagination'];
    final pMap = pagination is Map<String, dynamic>
        ? pagination
        : (body['pagination'] is Map<String, dynamic>
            ? body['pagination'] as Map<String, dynamic>
            : const <String, dynamic>{});

    int asInt(dynamic v, int fallback) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? fallback;
      return fallback;
    }

    final page = asInt(
      pMap['page'] ??
          dataMap['page'] ??
          body['page'] ??
          body['currentPage'],
      requestedPage,
    );
    final limit = asInt(
      pMap['limit'] ??
          dataMap['limit'] ??
          body['limit'] ??
          body['perPage'],
      requestedLimit,
    );
    final total = asInt(
      pMap['total'] ??
          pMap['totalItems'] ??
          dataMap['total'] ??
          dataMap['totalItems'] ??
          body['total'] ??
          body['totalItems'],
      itemsCount,
    );
    final computedPages = (total == 0 || limit == 0)
        ? 1
        : ((total + limit - 1) ~/ limit);
    final totalPages = asInt(
      pMap['totalPages'] ??
          pMap['pages'] ??
          dataMap['totalPages'] ??
          body['totalPages'] ??
          body['pages'],
      computedPages,
    );

    return _Pagination(
      page: page,
      limit: limit,
      total: total,
      totalPages: totalPages < 1 ? 1 : totalPages,
    );
  }
}

class _Pagination {
  const _Pagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });
  final int page;
  final int limit;
  final int total;
  final int totalPages;
}
