// lib/features/cms/presentation/controllers/product_controller.dart
import 'package:get/get.dart';
import 'package:satya_devotte_app/core/services/media_upload_service.dart';
import 'package:satya_devotte_app/features/cms/data/datasources/product_remote_datasource.dart';
import 'package:satya_devotte_app/features/cms/models/product_model.dart';
import 'package:satya_devotte_app/features/cms/presentation/widgets/cms_shared_widgets.dart';

class ProductController extends GetxController {
  ProductController(this._dataSource);
  final ProductRemoteDataSource _dataSource;

  final _products = <ProductModel>[].obs;
  final _isLoading = false.obs;
  final _isSubmitting = false.obs;
  final _error = RxnString();
  final _statusPendingIds = <String>{}.obs;
  final _filter = 'All'.obs;
  final _search = ''.obs;
  // ── Pagination (server-driven via /products/all?page=&limit=) ───
  final _page = 1.obs;
  final _pageSize = 10.obs;
  final _totalRows = 0.obs;
  final _totalPages = 1.obs;
  // ── Selection (for "Bulk Edit") ─────────────────────────────────
  final _selectedIds = <String>{}.obs;

  List<ProductModel> get products => _products;
  bool get isLoading => _isLoading.value;
  bool get isSubmitting => _isSubmitting.value;
  String? get error => _error.value;
  bool isStatusPending(String id) => _statusPendingIds.contains(id);
  String get filter => _filter.value;
  void setFilter(String f) {
    _filter.value = f;
    _page.value = 1;
    loadProducts();
  }

  String get search => _search.value;
  void setSearch(String q) {
    _search.value = q;
    _page.value = 1;
    // Search filters client-side over the current page since the backend
    // does not (yet) support a `q=` parameter.
  }

  // Pagination getters / setters
  int get page => _page.value;
  int get pageSize => _pageSize.value;
  int get totalRows => _totalRows.value;
  int get totalPages => _totalPages.value < 1 ? 1 : _totalPages.value;

  void setPage(int p) {
    final tp = totalPages;
    if (p < 1) p = 1;
    if (p > tp) p = tp;
    if (p == _page.value) return;
    _page.value = p;
    loadProducts();
  }

  void setPageSize(int s) {
    if (s == _pageSize.value) return;
    _pageSize.value = s;
    _page.value = 1;
    loadProducts();
  }

  // Selection helpers
  Set<String> get selectedIds => _selectedIds;
  bool isSelected(String id) => _selectedIds.contains(id);
  void toggleSelected(String id) {
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
    } else {
      _selectedIds.add(id);
    }
  }

  void selectAllOnPage(bool select) {
    final ids = pagedProducts.map((p) => p.id).toList();
    if (select) {
      _selectedIds.addAll(ids);
    } else {
      _selectedIds.removeAll(ids);
    }
  }

  void clearSelection() => _selectedIds.clear();

  /// Convenience counters for the filter chips (PENDING / QUEUED / etc.).
  int get pendingCount => _products.where((p) => p.isPending).length;
  int get queuedCount => _products.where((p) => p.isQueued).length;

  /// Products on the current page, filtered client-side by status + search.
  ///
  /// Server already paginates via `/products/all?page=&limit=`; the filter
  /// and search are applied on top of the loaded page. Re-selecting the
  /// filter triggers a reload so users still see fresh data.
  // Lifecycle filters (`productStatus`) handled separately from the
  // review-state filters (`status`).
  static const _lifecycleFilters = {'ACTIVE', 'INACTIVE'};

  List<ProductModel> get filteredProducts {
    final f = _filter.value.toUpperCase();
    final q = _search.value.trim().toLowerCase();
    Iterable<ProductModel> out = _products;
    if (f != 'ALL') {
      if (_lifecycleFilters.contains(f)) {
        out = out.where((p) => p.productStatus.toUpperCase() == f);
      } else {
        out = out.where((p) => p.status.toUpperCase() == f);
      }
    }
    if (q.isNotEmpty) {
      out = out.where(
        (p) =>
            p.title.toLowerCase().contains(q) ||
            p.slug.toLowerCase().contains(q) ||
            p.category.toLowerCase().contains(q),
      );
    }
    return out.toList();
  }

  /// Count of currently-loaded products matching the given chip label.
  int countFor(String label) {
    final f = label.toUpperCase();
    if (f == 'ALL') return _products.length;
    if (_lifecycleFilters.contains(f)) {
      return _products.where((p) => p.productStatus.toUpperCase() == f).length;
    }
    return _products.where((p) => p.status.toUpperCase() == f).length;
  }

  /// Alias kept for the existing UI — pagination is server-side now, so the
  /// "page" is whatever the server returned (after the local filter/search).
  List<ProductModel> get pagedProducts => filteredProducts;

  Future<void> loadProducts() async {
    _isLoading.value = true;
    _error.value = null;
    try {
      final res = await _dataSource.getProducts(
        page: _page.value,
        limit: _pageSize.value,
      );
      _products.assignAll(res.items);
      _totalRows.value = res.total;
      _totalPages.value = res.totalPages < 1 ? 1 : res.totalPages;
      // Guard against the server returning a smaller total than expected
      // (e.g. after a delete on the last page).
      if (_page.value > _totalPages.value) {
        _page.value = _totalPages.value;
        // Re-fetch the now-clamped page if we shifted.
        await _dataSource
            .getProducts(page: _page.value, limit: _pageSize.value)
            .then((r) {
          _products.assignAll(r.items);
          _totalRows.value = r.total;
          _totalPages.value = r.totalPages < 1 ? 1 : r.totalPages;
        });
      }
    } catch (e) {
      // List endpoint may not be deployed yet — keep UI usable.
      _error.value = _parseError(e);
      _products.clear();
      _totalRows.value = 0;
      _totalPages.value = 1;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> createProduct({
    required String title,
    required String slug,
    String description = '',
    required List<ProductItem> items,
    required num price,
    num? salePrice,
    String currency = 'ZAR',
    String category = '',
    String status = 'PENDING',
    String productStatus = 'ACTIVE',
    bool isFeatured = false,
    List<String> associatePuja = const [],
    PickedFile? image,
  }) async {
    _isSubmitting.value = true;
    _error.value = null;
    try {
      final created = await _dataSource.createProduct(
        title: title,
        slug: slug,
        description: description,
        items: items,
        price: price,
        salePrice: salePrice,
        currency: currency,
        category: category,
        status: status,
        productStatus: productStatus,
        isFeatured: isFeatured,
        associatePuja: associatePuja,
        image: image,
      );
      _ok('Puja Kit "${created.title}" created');
      // Server is the source of truth for pagination — reload so totals
      // and the current page reflect the newly-created product.
      await loadProducts();
      return true;
    } catch (e) {
      _error.value = _parseError(e);
      _err(_error.value!);
      return false;
    } finally {
      _isSubmitting.value = false;
    }
  }

  /// PATCH /products/:id — partial update via multipart. Returns true on success.
  Future<bool> updateProduct({
    required String id,
    String? title,
    String? slug,
    String? description,
    List<ProductItem>? items,
    num? price,
    num? salePrice,
    String? currency,
    String? category,
    String? status,
    String? productStatus,
    bool? isFeatured,
    List<String>? associatePuja,
    PickedFile? image,
    bool clearSalePrice = false,
  }) async {
    _isSubmitting.value = true;
    _error.value = null;
    try {
      final updated = await _dataSource.updateProduct(
        id: id,
        title: title,
        slug: slug,
        description: description,
        items: items,
        price: price,
        salePrice: salePrice,
        currency: currency,
        category: category,
        status: status,
        productStatus: productStatus,
        isFeatured: isFeatured,
        associatePuja: associatePuja,
        image: image,
        clearSalePrice: clearSalePrice,
      );
      _replaceLocal(updated);
      _ok('"${updated.title}" updated');
      return true;
    } catch (e) {
      _error.value = _parseError(e);
      _err(_error.value!);
      return false;
    } finally {
      _isSubmitting.value = false;
    }
  }

  /// DELETE /products/:id with optimistic removal.
  Future<bool> deleteProduct(String id) async {
    final index = _products.indexWhere((p) => p.id == id);
    final removed = index == -1 ? null : _products[index];
    if (index != -1) _products.removeAt(index);
    try {
      await _dataSource.deleteProduct(id);
      _ok('Puja Kit deleted');
      // Refresh from server so totals/pages stay accurate. `loadProducts`
      // clamps the page if we just removed the last item on the last page.
      await loadProducts();
      return true;
    } catch (e) {
      if (removed != null) {
        _products.insert(index, removed);
      }
      _error.value = _parseError(e);
      _err(_error.value!);
      return false;
    }
  }

  /// PUT /products/review/:id — super-admin review.
  Future<bool> approveProduct(String id, {String? reason}) =>
      _review(id, 'APPROVED', reason: reason, successMsg: 'Approved');
  Future<bool> rejectProduct(String id, String reason) =>
      _review(id, 'REJECTED', reason: reason, successMsg: 'Rejected');
  Future<bool> queueProduct(String id) =>
      _review(id, 'QUEUED', successMsg: 'Queued');

  Future<bool> _review(
    String id,
    String reviewStatus, {
    String? reason,
    required String successMsg,
  }) async {
    try {
      final updated = await _dataSource.reviewProduct(
        id: id,
        reviewStatus: reviewStatus,
        reason: reason,
      );
      _replaceLocal(updated);
      _ok(successMsg);
      return true;
    } catch (e) {
      _error.value = _parseError(e);
      _err(_error.value!);
      return false;
    }
  }

  /// Optimistic ACTIVE/INACTIVE flip with per-row pending state so the UI
  /// can render a spinner just on the affected card.
  Future<bool> setProductStatus({
    required String id,
    required String productStatus,
  }) async {
    final index = _products.indexWhere((p) => p.id == id);
    if (index == -1) return false;
    final prev = _products[index];
    if (prev.productStatus.toUpperCase() == productStatus.toUpperCase()) {
      return true;
    }
    _products[index] = prev.copyWith(productStatus: productStatus);
    _statusPendingIds.add(id);
    try {
      final updated = await _dataSource.setProductStatus(
        id: id,
        productStatus: productStatus,
      );
      _replaceLocal(updated, fallbackId: id);
      _ok(
        productStatus.toUpperCase() == 'ACTIVE'
            ? '"${prev.title}" activated'
            : '"${prev.title}" deactivated',
      );
      return true;
    } catch (e) {
      final reIndex = _products.indexWhere((p) => p.id == id);
      if (reIndex != -1) _products[reIndex] = prev;
      _error.value = _parseError(e);
      _err(_error.value!);
      return false;
    } finally {
      _statusPendingIds.remove(id);
    }
  }

  void _replaceLocal(ProductModel updated, {String? fallbackId}) {
    final id = updated.id.isNotEmpty ? updated.id : (fallbackId ?? '');
    final i = _products.indexWhere((p) => p.id == id);
    if (i != -1) {
      _products[i] = updated;
    }
  }

  void _ok(String msg) => showCmsSnackbar(title: 'Success', message: msg);
  void _err(String msg) =>
      showCmsSnackbar(title: 'Error', message: msg, isError: true);

  String _parseError(Object e) {
    final s = e.toString();
    if (s.startsWith('Exception: ')) {
      return s.substring('Exception: '.length);
    }
    if (s.contains('404')) return 'Endpoint not found.';
    if (s.contains('401') || s.contains('403')) return 'Not authorised.';
    if (s.contains('500')) return 'Server error. Try again.';
    if (s.contains('SocketException') || s.contains('connection')) {
      return 'No internet connection.';
    }
    return 'Something went wrong. Please try again.';
  }

  /// Convert an arbitrary title into a URL-friendly slug.
  static String slugify(String input) {
    final s = input.trim().toLowerCase();
    final cleaned = s.replaceAll(RegExp(r'[^a-z0-9\s-]'), '');
    final dashed = cleaned.replaceAll(RegExp(r'\s+'), '-');
    return dashed.replaceAll(RegExp(r'-+'), '-').replaceAll(RegExp(r'^-|-$'), '');
  }
}
