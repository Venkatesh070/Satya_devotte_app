// lib/features/poojakit/state/user_orders_controller.dart

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/core/config/order_return_replace_config.dart';
import 'package:satya_devotte_app/core/services/media_upload_service.dart';
import 'package:satya_devotte_app/core/utils/toast_util.dart';
import 'package:satya_devotte_app/features/cms/data/models/admin_order_models.dart';
import 'package:satya_devotte_app/features/cms/data/models/admin_order_request_models.dart';
import 'package:satya_devotte_app/features/poojakit/data/repositories/poojakit_repository.dart';

class UserOrdersController extends GetxController {
  UserOrdersController(this._repo);
  final PoojaKitRepository _repo;

  final _isLoading = false.obs;
  final _error = RxnString();
  final _orders = <AdminOrder>[].obs;

  final _page = 1.obs;
  final _totalPages = 1.obs;
  final _total = 0.obs;

  final _isMutating = false.obs;
  final _refundRequestsByOrderId = <String, OrderRequest>{}.obs;
  final _replacementRequestsByOrderId = <String, OrderRequest>{}.obs;

  bool get isLoading => _isLoading.value;
  bool get isMutating => _isMutating.value;
  String? get error => _error.value;
  List<AdminOrder> get orders => _orders;
  int get page => _page.value;
  int get totalPages => _totalPages.value;
  int get total => _total.value;

  OrderRequest? refundRequestFor(String orderId) =>
      _refundRequestsByOrderId[orderId];

  OrderRequest? replacementRequestFor(String orderId) =>
      _replacementRequestsByOrderId[orderId];

  @override
  void onInit() {
    super.onInit();
    fetchOrders();
  }

  Future<void> fetchOrders({bool refresh = true}) async {
    if (refresh) {
      _page.value = 1;
    }

    _isLoading.value = true;
    _error.value = null;

    try {
      final res = await _repo.getMyOrders(page: _page.value);
      if (refresh) {
        _orders.assignAll(_dedupeOrders(res.items));
      } else {
        final seen = _orders.map((order) => order.id).toSet();
        _orders.addAll(res.items.where((order) => seen.add(order.id)));
      }
      _totalPages.value = res.totalPages;
      _total.value = res.total;
      if (kOrderReturnReplaceEnabled) {
        await Future.wait([
          _refreshRefundRequests(),
          _refreshReplacementRequests(),
        ]);
      }
    } catch (e) {
      _error.value = e.toString();
    } finally {
      _isLoading.value = false;
    }
  }

  List<AdminOrder> _dedupeOrders(List<AdminOrder> source) {
    final seen = <String>{};
    return source.where((order) => seen.add(order.id)).toList();
  }

  Future<void> loadNextPage() async {
    if (_page.value < _totalPages.value && !isLoading) {
      _page.value++;
      await fetchOrders(refresh: false);
    }
  }

  Future<bool> cancelOrder(String orderId, {required String reason}) async {
    _isMutating.value = true;
    try {
      await _repo.cancelOrder(orderId, reason: reason);
      await fetchOrders();
      return true;
    } catch (e) {
      ToastUtil.showError(e.toString());
      return false;
    } finally {
      _isMutating.value = false;
    }
  }

  Future<bool> confirmDelivery(
    String orderId, {
    required bool satisfied,
    String? feedback,
    String? collectionCode,
  }) async {
    _isMutating.value = true;
    try {
      await _repo.confirmDelivery(
        orderId,
        satisfied: satisfied,
        feedback: feedback,
        collectionCode: collectionCode,
      );
      await fetchOrders();
      return true;
    } catch (e) {
      ToastUtil.showError(e.toString());
      return false;
    } finally {
      _isMutating.value = false;
    }
  }

  Future<bool> requestReplacement({
    required String orderId,
    required String reason,
    required List<PickedFile> images,
    List<Map<String, dynamic>> affectedItems = const [],
  }) async {
    if (!kOrderReturnReplaceEnabled) return false;
    _isMutating.value = true;
    try {
      await _repo.requestReplacement(
        orderId: orderId,
        reason: reason,
        images: images,
        affectedItems: affectedItems,
      );
      await fetchOrders();
      return true;
    } catch (e) {
      ToastUtil.showError(e.toString());
      return false;
    } finally {
      _isMutating.value = false;
    }
  }

  Future<bool> requestReturn({
    required String orderId,
    required String reason,
    List<Map<String, dynamic>> affectedItems = const [],
  }) async {
    if (!kOrderReturnReplaceEnabled) return false;
    _isMutating.value = true;
    try {
      await _repo.requestReturn(
        orderId: orderId,
        reason: reason,
        affectedItems: affectedItems,
      );
      await fetchOrders();
      return true;
    } catch (e) {
      ToastUtil.showError(e.toString());
      return false;
    } finally {
      _isMutating.value = false;
    }
  }

  Future<AdminOrder?> refreshOrderDetail(String orderId) async {
    try {
      final updated = await _repo.getOrderDetail(orderId);
      // Update the order in the list if it exists
      final idx = _orders.indexWhere((o) => o.id == orderId);
      if (idx != -1) {
        _orders[idx] = updated;
      }
      return updated;
    } catch (e) {
      debugPrint('Error refreshing order detail: $e');
      return null;
    }
  }

  Future<OrderRequest?> fetchReplacementRequestForOrder(AdminOrder order) async {
    if (!kOrderReturnReplaceEnabled) return null;
    final cached = replacementRequestFor(order.id);
    if (cached != null) return cached;

    final id = order.latestReplacementRequestId.trim();
    if (id.isEmpty) return null;
    final state = order.replacementState.toUpperCase().trim();
    if (state == 'NONE' || state == 'REJECTED') {
      // Still useful if nested summary is missing on older payloads.
      if (order.latestReplacementRequest == null) return null;
    }
    try {
      final request = await _repo.getMyReplacementRequest(id);
      _replacementRequestsByOrderId[order.id] = request;
      return request;
    } catch (e) {
      debugPrint('Error loading replacement request: $e');
      return null;
    }
  }

  Future<void> _refreshRefundRequests() async {
    try {
      final res = await _repo.getMyOrderRequests(type: 'REFUND', limit: 100);
      final next = <String, OrderRequest>{};
      for (final request in res.items) {
        if (request.type != OrderRequestType.refund) continue;
        final orderId = request.order?.id ?? '';
        if (orderId.isEmpty) continue;
        final existing = next[orderId];
        if (existing == null ||
            (request.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
                .isAfter(
                  existing.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
                )) {
          next[orderId] = request;
        }
      }
      _refundRequestsByOrderId.assignAll(next);
    } catch (e) {
      debugPrint('Error loading refund requests: $e');
    }
  }

  Future<void> _refreshReplacementRequests() async {
    try {
      final res = await _repo.getMyReplacementRequests(limit: 100);
      final next = <String, OrderRequest>{};
      for (final request in res.items) {
        if (request.type != OrderRequestType.replacement) continue;
        final orderId = request.order?.id ?? '';
        if (orderId.isEmpty) continue;
        final existing = next[orderId];
        if (existing == null ||
            (request.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
                .isAfter(
                  existing.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
                )) {
          next[orderId] = request;
        }
      }
      _replacementRequestsByOrderId.assignAll(next);
    } catch (e) {
      debugPrint('Error loading replacement requests: $e');
    }
  }

  Future<OrderRequest?> fetchRefundRequestForOrder(AdminOrder order) async {
    if (!kOrderReturnReplaceEnabled) return null;
    final cached = refundRequestFor(order.id);
    if (cached != null) return cached;
    await _refreshRefundRequests();
    return refundRequestFor(order.id);
  }
}
