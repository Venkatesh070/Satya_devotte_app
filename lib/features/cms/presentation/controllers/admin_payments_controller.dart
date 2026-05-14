// Payments inbox controller. Same datasource as orders but defaults to a
// payment-status-focused view: `GET /orders/all` with `paymentStatus` as the
// primary filter, plus an explicit "Verify now" action.
import 'package:dio/dio.dart';
import 'package:get/get.dart';

import 'package:satya_devotte_app/features/cms/data/datasources/admin_orders_remote_datasource.dart';
import 'package:satya_devotte_app/features/cms/data/models/admin_order_models.dart';
import 'package:satya_devotte_app/features/cms/presentation/widgets/cms_shared_widgets.dart';

class AdminPaymentsController extends GetxController {
  AdminPaymentsController(this._ds);
  final AdminOrdersRemoteDataSource _ds;

  static const filters = <String>[
    'ALL',
    'PAID',
    'PENDING',
    'FAILED',
    'REFUNDED',
  ];

  final _items = <AdminOrder>[].obs;
  final _isLoading = false.obs;
  final _error = RxnString();
  final _page = 1.obs;
  final _limit = 10.obs;
  final _total = 0.obs;
  final _totalPages = 1.obs;
  final _filter = 'ALL'.obs;
  final _search = ''.obs;
  final _verifying = <String>{}.obs;

  List<AdminOrder> get items => _items;
  bool get isLoading => _isLoading.value;
  String? get error => _error.value;
  int get page => _page.value;
  int get limit => _limit.value;
  int get total => _total.value;
  int get totalPages => _totalPages.value;
  String get filter => _filter.value;
  String get search => _search.value;
  Set<String> get verifying => _verifying;
  bool get isEmpty =>
      !_isLoading.value && _error.value == null && _items.isEmpty;

  bool isVerifying(String id) => _verifying.contains(id);

  Future<void> refresh() => _load(page: 1);
  Future<void> goToPage(int target) async {
    final p = target.clamp(1, _totalPages.value);
    if (p == _page.value && _items.isNotEmpty) return;
    await _load(page: p);
  }

  Future<void> nextPage() => goToPage(_page.value + 1);
  Future<void> prevPage() => goToPage(_page.value - 1);

  void setFilter(String v) {
    final u = v.toUpperCase();
    if (!filters.contains(u) || _filter.value == u) return;
    _filter.value = u;
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
        paymentStatus: _filter.value == 'ALL' ? null : _filter.value,
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
      _error.value = 'Failed to load payments.';
    } finally {
      _isLoading.value = false;
    }
  }

  /// Admin-triggered Paystack verify. Updates the row in-place.
  Future<void> verifyByReference(AdminOrder order) async {
    final ref = order.paystackReference;
    if (ref.trim().isEmpty) {
      showCmsSnackbar(
        title: 'No reference',
        message: 'This order has no Paystack reference yet.',
        isError: true,
      );
      return;
    }
    if (_verifying.contains(order.id)) return;
    _verifying.add(order.id);
    _verifying.refresh();
    try {
      final updated = await _ds.verifyPayment(ref.trim());
      if (updated != null) {
        final idx = _items.indexWhere((o) => o.id == updated.id);
        if (idx != -1) {
          final prev = _items[idx];
          _items[idx] = updated.withCustomerFallback(prev);
          _items.refresh();
        }
      } else {
        // No order embedded — re-fetch the single order to surface fresh state.
        final fresh = await _ds.getOrder(order.id);
        final idx = _items.indexWhere((o) => o.id == fresh.id);
        if (idx != -1) {
          final prev = _items[idx];
          _items[idx] = fresh.withCustomerFallback(prev);
          _items.refresh();
        }
      }
      showCmsSnackbar(
        title: 'Verified',
        message: 'Latest payment status pulled from Paystack.',
        isError: false,
      );
    } on DioException catch (e) {
      showCmsSnackbar(
        title: 'Verify failed',
        message: _msg(e),
        isError: true,
      );
    } catch (_) {
      showCmsSnackbar(
        title: 'Verify failed',
        message: 'Something went wrong. Please try again.',
        isError: true,
      );
    } finally {
      _verifying.remove(order.id);
      _verifying.refresh();
    }
  }

  String _msg(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final m = data['message'];
      if (m is String && m.isNotEmpty) return m;
    }
    return e.message ?? 'Network error. Please try again.';
  }
}
