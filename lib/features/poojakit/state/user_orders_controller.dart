// lib/features/poojakit/state/user_orders_controller.dart

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/core/services/media_upload_service.dart';
import 'package:satya_devotte_app/features/cms/data/models/admin_order_models.dart';
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

  bool get isLoading => _isLoading.value;
  bool get isMutating => _isMutating.value;
  String? get error => _error.value;
  List<AdminOrder> get orders => _orders;
  int get page => _page.value;
  int get totalPages => _totalPages.value;
  int get total => _total.value;

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
        _orders.assignAll(res.items);
      } else {
        _orders.addAll(res.items);
      }
      _totalPages.value = res.totalPages;
      _total.value = res.total;
    } catch (e) {
      _error.value = e.toString();
    } finally {
      _isLoading.value = false;
    }
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
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      _isMutating.value = false;
    }
  }

  Future<bool> confirmDelivery(
    String orderId, {
    required bool satisfied,
    String? feedback,
  }) async {
    _isMutating.value = true;
    try {
      await _repo.confirmDelivery(
        orderId,
        satisfied: satisfied,
        feedback: feedback,
      );
      await fetchOrders();
      return true;
    } catch (e) {
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      _isMutating.value = false;
    }
  }

  Future<bool> requestReplacement({
    required String orderId,
    required String reason,
    required List<PickedFile> images,
  }) async {
    _isMutating.value = true;
    try {
      await _repo.requestReplacement(
        orderId: orderId,
        reason: reason,
        images: images,
      );
      await fetchOrders();
      return true;
    } catch (e) {
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
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
}
