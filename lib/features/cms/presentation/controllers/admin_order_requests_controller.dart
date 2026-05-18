// Replacement-requests inbox + detail controller.
// Backs the "Replace Requests" tab (`GET /admin/replacements`).
import 'package:dio/dio.dart';
import 'package:get/get.dart';

import 'package:satya_devotte_app/features/cms/data/datasources/admin_orders_remote_datasource.dart';
import 'package:satya_devotte_app/features/cms/data/models/admin_order_request_models.dart';
import 'package:satya_devotte_app/features/cms/presentation/widgets/cms_shared_widgets.dart';

class AdminOrderRequestsController extends GetxController {
  AdminOrderRequestsController(this._ds);
  final AdminOrdersRemoteDataSource _ds;

  static const statusFilters = <String>[
    'ALL',
    'REQUESTED',
    'APPROVED',
    'REJECTED',
    'PROCESSING',
    'SHIPPED',
    'DELIVERED',
    'CANCELLED',
  ];

  final _items = <OrderRequest>[].obs;
  final _isLoading = false.obs;
  final _error = RxnString();
  final _page = 1.obs;
  final _limit = 20.obs;
  final _total = 0.obs;
  final _totalPages = 1.obs;
  final _status = 'ALL'.obs;

  final _selectedId = RxnString();
  final _detail = Rxn<OrderRequest>();
  final _detailLoading = false.obs;
  final _detailError = RxnString();
  final _mutating = false.obs;

  List<OrderRequest> get items => _items;
  bool get isLoading => _isLoading.value;
  String? get error => _error.value;
  int get page => _page.value;
  int get limit => _limit.value;
  int get total => _total.value;
  int get totalPages => _totalPages.value;
  String get status => _status.value;
  bool get isEmpty =>
      !_isLoading.value && _error.value == null && _items.isEmpty;

  String? get selectedId => _selectedId.value;
  OrderRequest? get detail => _detail.value;
  bool get detailLoading => _detailLoading.value;
  String? get detailError => _detailError.value;
  bool get mutating => _mutating.value;

  Future<void> refresh() => _load(page: 1);
  Future<void> goToPage(int target) async {
    final p = target.clamp(1, _totalPages.value);
    if (p == _page.value && _items.isNotEmpty) return;
    await _load(page: p);
  }

  Future<void> nextPage() => goToPage(_page.value + 1);
  Future<void> prevPage() => goToPage(_page.value - 1);

  void setStatusFilter(String v) {
    final u = v.toUpperCase();
    if (!statusFilters.contains(u) || _status.value == u) return;
    _status.value = u;
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
      final res = await _ds.getReplacements(
        page: page,
        limit: _limit.value,
        status: _status.value == 'ALL' ? null : _status.value,
      );
      _items.assignAll(res.items);
      _page.value = res.page;
      _limit.value = res.limit;
      _total.value = res.total;
      _totalPages.value = res.totalPages;
    } on DioException catch (e) {
      _error.value = _msg(e);
    } catch (_) {
      _error.value = 'Failed to load requests.';
    } finally {
      _isLoading.value = false;
    }
  }

  // ── detail / actions ──────────────────────────────────────────────
  void openRequest(String id) {
    _selectedId.value = id;
    _detail.value = _items.firstWhereOrNull((r) => r.id == id);
    fetchDetail();
  }

  void closeDetail() {
    _selectedId.value = null;
    _detail.value = null;
    _detailError.value = null;
    _load(page: _page.value);
  }

  Future<void> fetchDetail() async {
    final id = _selectedId.value;
    if (id == null) return;
    _detailLoading.value = true;
    _detailError.value = null;
    try {
      final fresh = await _ds.getReplacementRequest(id);
      final current = _detail.value;
      final freshIsUsable =
          fresh.id.isNotEmpty || fresh.requestNumber.isNotEmpty;
      if (freshIsUsable) {
        _detail.value = fresh;
      } else if (current == null) {
        _detail.value = fresh;
      }
    } on DioException catch (e) {
      _detailError.value = _msg(e);
    } catch (_) {
      _detailError.value = 'Failed to load request.';
    } finally {
      _detailLoading.value = false;
    }
  }

  Future<bool> approve({String? adminNote}) async {
    final id = _selectedId.value;
    if (id == null) return false;
    return _mutate(() async {
      final updated =
          await _ds.approveReplacementRequest(id, adminNote: adminNote);
      _replaceDetail(updated);
      _ok('Request approved', 'Replacement order created and linked.');
      return true;
    });
  }

  Future<bool> reject({String? adminNote}) async {
    final id = _selectedId.value;
    if (id == null) return false;
    return _mutate(() async {
      final updated =
          await _ds.rejectReplacementRequest(id, adminNote: adminNote);
      _replaceDetail(updated);
      _ok('Request rejected', 'The devotee will be notified by email.');
      return true;
    });
  }

  void _replaceDetail(OrderRequest updated) {
    _detail.value = updated;
    final idx = _items.indexWhere((r) => r.id == updated.id);
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
