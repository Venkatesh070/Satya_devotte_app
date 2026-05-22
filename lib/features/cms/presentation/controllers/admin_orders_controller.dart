// Orders inbox + detail controller for the admin CMS.
//
// Holds:
//   • Paginated, filterable list state for `GET /orders/all`.
//   • Currently-opened order id and its detail for the in-shell drill-down.
//   • All admin mutations (status / tracking / dispatch / cancel / payment /
//     verify) with success+error snackbar feedback.
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/core/routing/cms_route_paths.dart';
import 'package:satya_devotte_app/core/routing/hash_route_sync.dart';
import 'package:satya_devotte_app/features/cms/data/datasources/admin_orders_remote_datasource.dart';
import 'package:satya_devotte_app/features/cms/data/models/admin_order_models.dart';
import 'package:satya_devotte_app/features/cms/presentation/widgets/cms_shared_widgets.dart';

class AdminOrdersController extends GetxController {
  AdminOrdersController(this._ds);
  final AdminOrdersRemoteDataSource _ds;

  /// Single-list mode. The Payments tab opts into [paymentMode] = true so it
  /// can be driven by the same controller but defaults to a payment-status
  /// filter set + "All / Pending / Paid / Failed / Refunded".
  static const orderStatusFilters = <String>[
    'ALL',
    'PLACED',
    'PROCESSING',
    'SHIPPED',
    'DELIVERED',
    'FULFILLED',
    'CANCELLED',
  ];
  static const paymentStatusFilters = <String>[
    'ALL',
    'PAID',
    'PENDING',
    'FAILED',
    'REFUNDED',
    'REFUND_INITIATED',
    'REFUND_FAILED',
  ];

  // ── list state ────────────────────────────────────────────────────
  final _items = <AdminOrder>[].obs;
  final _isLoading = false.obs;
  final _error = RxnString();
  final _page = 1.obs;
  final _limit = 10.obs;
  final _total = 0.obs;
  final _totalPages = 1.obs;
  final _orderStatus = 'ALL'.obs;
  final _paymentStatus = 'ALL'.obs;
  final _search = ''.obs;

  // ── detail state ──────────────────────────────────────────────────
  final _selectedOrderId = RxnString();
  final _detail = Rxn<AdminOrder>();
  final _detailLoading = false.obs;
  final _detailError = RxnString();
  final _mutating = false.obs;

  // public getters
  List<AdminOrder> get items => _items;
  bool get isLoading => _isLoading.value;
  String? get error => _error.value;
  int get page => _page.value;
  int get limit => _limit.value;
  int get total => _total.value;
  int get totalPages => _totalPages.value;
  String get orderStatus => _orderStatus.value;
  String get paymentStatus => _paymentStatus.value;
  String get search => _search.value;
  bool get isEmpty =>
      !_isLoading.value && _error.value == null && _items.isEmpty;

  String? get selectedOrderId => _selectedOrderId.value;
  AdminOrder? get detail => _detail.value;
  bool get detailLoading => _detailLoading.value;
  String? get detailError => _detailError.value;
  bool get mutating => _mutating.value;

  // ── list actions ──────────────────────────────────────────────────
  Future<void> refresh() => _load(page: 1);
  Future<void> goToPage(int target) async {
    final p = target.clamp(1, _totalPages.value);
    if (p == _page.value && _items.isNotEmpty) return;
    await _load(page: p);
  }

  Future<void> nextPage() => goToPage(_page.value + 1);
  Future<void> prevPage() => goToPage(_page.value - 1);

  void setOrderStatusFilter(String v) {
    final u = v.toUpperCase();
    if (!orderStatusFilters.contains(u) || _orderStatus.value == u) return;
    _orderStatus.value = u;
    _load(page: 1);
  }

  void setPaymentStatusFilter(String v) {
    final u = v.toUpperCase();
    if (!paymentStatusFilters.contains(u) || _paymentStatus.value == u) return;
    _paymentStatus.value = u;
    _load(page: 1);
  }

  void setSearch(String v) {
    if (_search.value == v) return;
    _search.value = v;
    _load(page: 1);
  }

  void setLimit(int v) {
    if (v <= 0 || v == _limit.value) return;
    _limit.value = v;
    _load(page: 1);
  }

  Future<void> _load({required int page}) async {
    _isLoading.value = true;
    _error.value = null;
    try {
      final res = await _ds.getAllOrders(
        page: page,
        limit: _limit.value,
        orderStatus: _orderStatus.value == 'ALL' ? null : _orderStatus.value,
        paymentStatus:
            _paymentStatus.value == 'ALL' ? null : _paymentStatus.value,
        search: _search.value.trim().isEmpty ? null : _search.value.trim(),
      );
      _items.assignAll(res.items);
      _page.value = res.page;
      _limit.value = res.limit;
      _total.value = res.total;
      _totalPages.value = res.totalPages;
    } on DioException catch (e) {
      _error.value = _msg(e);
    } catch (_) {
      _error.value = 'Failed to load orders.';
    } finally {
      _isLoading.value = false;
    }
  }

  // ── detail actions ────────────────────────────────────────────────
  void openOrder(String id, {bool syncUrl = true}) {
    _selectedOrderId.value = id;
    _detail.value = _items.firstWhereOrNull((o) => o.id == id);
    fetchDetail();
    if (syncUrl && kIsWeb) {
      updateCmsHashRoute(CmsRoutePaths.poojaKitOrderDetail(id));
    }
  }

  void closeDetail({bool syncUrl = true}) {
    _selectedOrderId.value = null;
    _detail.value = null;
    _detailError.value = null;
    if (syncUrl && kIsWeb) {
      updateCmsHashRoute(AppRoutes.cmsPoojaKitOrders);
    }
    // Re-fetch the current list page so status / payment / totals reflect any
    // changes made on the detail screen (and so GET /orders/all runs again).
    _load(page: _page.value);
  }

  Future<void> fetchDetail() async {
    final id = _selectedOrderId.value;
    if (id == null) return;
    _detailLoading.value = true;
    _detailError.value = null;
    try {
      final fresh = await _ds.getOrder(id);
      // Guard against a backend response shape that parses into an "empty"
      // AdminOrder — if the fetched copy is clearly sparser than the one
      // we already had from the list, keep the list snapshot so the user
      // still sees data instead of an apparently-blank detail screen.
      final current = _detail.value;
      final freshIsUsable =
          fresh.id.isNotEmpty || fresh.orderNumber.isNotEmpty;
      if (freshIsUsable) {
        _detail.value = fresh;
      } else if (current == null) {
        _detail.value = fresh; // nothing better available
      }
    } on DioException catch (e) {
      _detailError.value = _msg(e);
    } catch (_) {
      _detailError.value = 'Failed to load order.';
    } finally {
      _detailLoading.value = false;
    }
  }

  /// Mark `PROCESSING` (or any allowed next state without tracking).
  Future<bool> markStatus(OrderStatus next, {String? note}) async {
    final id = _selectedOrderId.value;
    if (id == null) return false;
    return _mutate(() async {
      final updated = await _ds.updateStatus(id, status: next, note: note);
      _replaceDetail(updated);
      _ok('Status updated', 'Order is now ${next.label}.');
      return true;
    });
  }

  Future<bool> updatePayment({
    PaymentStatus? paymentStatus,
    String? paymentMethod,
  }) async {
    final id = _selectedOrderId.value;
    if (id == null) return false;
    return _mutate(() async {
      final updated = await _ds.updatePayment(
        id,
        paymentStatus: paymentStatus,
        paymentMethod: paymentMethod,
      );
      _replaceDetail(updated);
      _ok('Payment updated', 'Payment fields were saved.');
      return true;
    });
  }

  Future<bool> saveTracking({
    required String courier,
    required String trackingNumber,
    String? trackingUrl,
  }) async {
    final id = _selectedOrderId.value;
    if (id == null) return false;
    return _mutate(() async {
      final updated = await _ds.updateTracking(
        id,
        courier: courier,
        trackingNumber: trackingNumber,
        trackingUrl: trackingUrl,
      );
      _replaceDetail(updated);
      _ok('Tracking saved', 'Courier and tracking number stored.');
      return true;
    });
  }

  Future<bool> dispatch({
    required String courier,
    required String trackingNumber,
    String? trackingUrl,
    String? note,
  }) async {
    final id = _selectedOrderId.value;
    if (id == null) return false;
    return _mutate(() async {
      final updated = await _ds.dispatchOrder(
        id,
        courier: courier,
        trackingNumber: trackingNumber,
        trackingUrl: trackingUrl,
        note: note,
      );
      _replaceDetail(updated);
      _ok('Order shipped', 'Tracking saved and shipping email sent.');
      return true;
    });
  }

  Future<bool> cancelOrder({String? reason}) async {
    final id = _selectedOrderId.value;
    if (id == null) return false;
    return _mutate(() async {
      final updated = await _ds.cancelOrder(id, reason: reason);
      _replaceDetail(updated);
      _ok('Order cancelled', 'The order has been cancelled and restocked.');
      return true;
    });
  }

  /// `POST /orders/:id/refund` — marks refund initiated on the order.
  Future<bool> initiateRefund({
    required String reason,
    String? adminNote,
  }) async {
    final id = _selectedOrderId.value;
    if (id == null) return false;
    return _mutate(() async {
      final updated = await _ds.initiateRefund(
        id,
        reason: reason,
        adminNote: adminNote,
      );
      _replaceDetail(updated);
      _ok(
        'Refund initiated',
        'Refund has been initiated on this order. Complete the payout in the '
        'Paystack dashboard if required.',
      );
      return true;
    });
  }

  /// Idempotent admin verify by Paystack reference.
  Future<bool> verifyPayment(String reference) async {
    if (reference.trim().isEmpty) return false;
    return _mutate(() async {
      final updated = await _ds.verifyPayment(reference.trim());
      if (updated != null) {
        final cur = _detail.value;
        final merged = (cur != null && cur.id == updated.id)
            ? updated.withCustomerFallback(cur)
            : updated;
        _replaceDetail(merged);
      } else {
        await fetchDetail();
      }
      _ok('Payment verified', 'Latest payment status pulled from Paystack.');
      return true;
    });
  }

  // ── internals ─────────────────────────────────────────────────────
  void _replaceDetail(AdminOrder updated) {
    _detail.value = updated;
    final idx = _items.indexWhere((o) => o.id == updated.id);
    if (idx != -1) {
      _items[idx] = updated;
      _items.refresh();
    }
  }

  Future<bool> _mutate(Future<bool> Function() body) async {
    if (_mutating.value) return false;
    _mutating.value = true;
    try {
      return await body();
    } on DioException catch (e) {
      _err('Action failed', _msg(e));
      return false;
    } catch (_) {
      _err('Action failed', 'Something went wrong. Please try again.');
      return false;
    } finally {
      _mutating.value = false;
    }
  }

  void _ok(String t, String m) =>
      showCmsSnackbar(title: t, message: m, isError: false);
  void _err(String t, String m) =>
      showCmsSnackbar(title: t, message: m, isError: true);

  String _msg(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final m = data['message'];
      if (m is String && m.isNotEmpty) return m;
    }
    return e.message ?? 'Network error. Please try again.';
  }
}
