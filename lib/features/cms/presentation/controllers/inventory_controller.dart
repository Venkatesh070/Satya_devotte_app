import 'package:dio/dio.dart';
import 'package:get/get.dart';

import 'package:satya_devotte_app/core/services/media_upload_service.dart';
import 'package:satya_devotte_app/features/cms/data/datasources/inventory_remote_datasource.dart';
import 'package:satya_devotte_app/features/cms/data/models/inventory_models.dart';
import 'package:satya_devotte_app/features/cms/presentation/widgets/cms_shared_widgets.dart';

class InventoryController extends GetxController {
  InventoryController(this._ds);
  final InventoryRemoteDataSource _ds;

  final _categories = <InventoryCategory>[].obs;
  final _items = <InventoryItem>[].obs;
  final _isLoading = false.obs;
  final _isSubmitting = false.obs;
  final _error = RxnString();
  final _page = 1.obs;
  final _limit = 20.obs;
  final _total = 0.obs;
  final _totalPages = 1.obs;
  final _search = ''.obs;
  final _categoryFilter = 'ALL'.obs;
  final _statusFilter = 'ALL'.obs;
  final _stockFilter = 'All'.obs;
  final _pickerItems = <InventoryItem>[].obs;
  final _isPickerLoading = false.obs;
  final _isCategoriesLoading = false.obs;
  final _statusPendingIds = <String>{}.obs;
  Future<void>? _initFuture;
  Future<void>? _categoriesLoadFuture;

  List<InventoryCategory> get categories => _categories;
  List<InventoryItem> get items => _items;
  List<InventoryItem> get pickerItems => _pickerItems;
  bool get isPickerLoading => _isPickerLoading.value;
  bool get isCategoriesLoading => _isCategoriesLoading.value;
  bool get isLoading => _isLoading.value;
  bool get isSubmitting => _isSubmitting.value;
  String? get error => _error.value;
  int get page => _page.value;
  int get limit => _limit.value;
  int get total => _total.value;
  int get totalPages => _totalPages.value;
  String get search => _search.value;
  String get categoryFilter => _categoryFilter.value;
  String get statusFilter => _statusFilter.value;
  String get stockFilter => _stockFilter.value;

  bool isStatusPending(String id) => _statusPendingIds.contains(id);

  String categoryLabel(String code) {
    for (final c in _categories) {
      if (c.code == code) return c.label;
    }
    return code.isEmpty ? '—' : code;
  }

  /// Loads categories and the first page of items in parallel (idempotent).
  Future<void> init() {
    _initFuture ??= _runInit();
    return _initFuture!;
  }

  Future<void> _runInit() async {
    await Future.wait([loadCategories(), refresh()]);
  }

  /// Active inventory rows for kit BOM picker (`GET /inventory?status=ACTIVE`).
  Future<void> loadPickerItems() async {
    _isPickerLoading.value = true;
    try {
      final res = await _ds.getItems(
        page: 1,
        limit: 100,
        status: 'ACTIVE',
      );
      _pickerItems.assignAll(res.items);
    } catch (_) {
      _pickerItems.clear();
    } finally {
      _isPickerLoading.value = false;
    }
  }

  InventoryItem? inventoryById(String id) {
    for (final i in _pickerItems) {
      if (i.id == id) return i;
    }
    return null;
  }

  Future<void> loadCategories() {
    if (_categories.isNotEmpty) return Future.value();
    return _categoriesLoadFuture ??= _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    _isCategoriesLoading.value = true;
    try {
      final list = await _ds.getCategories();
      _categories.assignAll(list);
    } catch (_) {
      // Categories are optional for listing; form will show codes only.
    } finally {
      _isCategoriesLoading.value = false;
      _categoriesLoadFuture = null;
    }
  }

  /// `POST /inventory/categories/seed` (superadmin).
  Future<bool> seedCategories() async {
    return _mutate(() async {
      final list = await _ds.seedCategories();
      _categories.assignAll(list);
      _ok('Categories seeded', '${list.length} categories available.');
      return true;
    });
  }

  @override
  Future<void> refresh() => _load(page: 1);

  Future<void> goToPage(int target) async {
    final p = target.clamp(1, _totalPages.value);
    if (p == _page.value && _items.isNotEmpty) return;
    await _load(page: p);
  }

  Future<void> nextPage() => goToPage(_page.value + 1);
  Future<void> prevPage() => goToPage(_page.value - 1);

  void setSearch(String v) {
    if (_search.value == v) return;
    _search.value = v;
    _load(page: 1);
  }

  void setCategoryFilter(String v) {
    if (_categoryFilter.value == v) return;
    _categoryFilter.value = v;
    _load(page: 1);
  }

  void setStatusFilter(String v) {
    if (_statusFilter.value == v) return;
    _statusFilter.value = v;
    _load(page: 1);
  }

  void setStockFilter(String v) {
    if (_stockFilter.value == v) return;
    _stockFilter.value = v;
    _load(page: 1);
  }

  void setLimit(int v) {
    if (v <= 0 || v == _limit.value) return;
    _limit.value = v;
    _load(page: 1);
  }

  bool? get _apiLowStock {
    switch (_stockFilter.value) {
      case 'Low stock':
        return true;
      default:
        return null;
    }
  }

  String? get _apiStatus {
    final s = _statusFilter.value.toUpperCase();
    if (s == 'ALL') return null;
    return s;
  }

  String? get _apiCategory {
    final c = _categoryFilter.value;
    if (c == 'ALL') return null;
    return c;
  }

  Future<void> _load({required int page}) async {
    _isLoading.value = true;
    _error.value = null;
    try {
      final res = await _ds.getItems(
        page: page,
        limit: _limit.value,
        search: _search.value.trim().isEmpty ? null : _search.value.trim(),
        category: _apiCategory,
        status: _apiStatus,
        lowStock: _apiLowStock,
      );
      var list = res.items;
      switch (_stockFilter.value) {
        case 'In stock':
          list = list
              .where((i) => !i.isOutOfStock && !i.isLowStock)
              .toList(growable: false);
          break;
        case 'Out of stock':
          list = list.where((i) => i.isOutOfStock).toList(growable: false);
          break;
      }
      _items.assignAll(list);
      _page.value = res.page;
      _limit.value = res.limit;
      _total.value = res.total;
      _totalPages.value = res.totalPages;
    } on DioException catch (e) {
      _error.value = _msg(e);
    } catch (_) {
      _error.value = 'Failed to load inventory.';
    } finally {
      _isLoading.value = false;
    }
  }

  Future<InventoryItem?> fetchItem(String id) async {
    try {
      return await _ds.getItem(id);
    } on DioException catch (e) {
      _err('Load failed', _msg(e));
    } catch (_) {
      _err('Load failed', 'Could not load inventory item.');
    }
    return null;
  }

  Future<bool> createItem({
    required String name,
    required String category,
    required String unit,
    required num itemQuantity,
    required num price,
    required String currency,
    num? salePrice,
    int stockQuantity = 0,
    String description = '',
    String? slug,
    String supplierName = '',
    int lowStockThreshold = 10,
    String status = 'ACTIVE',
    PickedFile? image,
  }) async {
    return _mutate(() async {
      await _ds.createItem(
        name: name,
        category: category,
        unit: unit,
        itemQuantity: itemQuantity,
        price: price,
        currency: currency,
        salePrice: salePrice,
        stockQuantity: stockQuantity,
        description: description,
        slug: slug,
        supplierName: supplierName,
        lowStockThreshold: lowStockThreshold,
        status: status,
        image: image,
      );
      _ok('Created', 'Inventory item added.');
      await _load(page: 1);
      return true;
    });
  }

  Future<bool> updateItem({
    required String id,
    String? name,
    String? category,
    String? unit,
    num? itemQuantity,
    num? price,
    num? salePrice,
    String? currency,
    int? stockQuantity,
    String? description,
    String? slug,
    String? supplierName,
    int? lowStockThreshold,
    String? status,
    PickedFile? image,
    bool clearSalePrice = false,
  }) async {
    return _mutate(() async {
      await _ds.updateItem(
        id: id,
        name: name,
        category: category,
        unit: unit,
        itemQuantity: itemQuantity,
        price: price,
        salePrice: salePrice,
        currency: currency,
        stockQuantity: stockQuantity,
        description: description,
        slug: slug,
        supplierName: supplierName,
        lowStockThreshold: lowStockThreshold,
        status: status,
        image: image,
        clearSalePrice: clearSalePrice,
      );
      _ok('Updated', 'Inventory item saved.');
      await _load(page: _page.value);
      return true;
    });
  }

  /// Optimistic ACTIVE / INACTIVE toggle for list row switch.
  Future<bool> setItemStatus({required String id, required bool active}) async {
    final index = _items.indexWhere((e) => e.id == id);
    if (index == -1) return false;
    final prev = _items[index];
    final nextStatus = active ? 'ACTIVE' : 'INACTIVE';
    if (prev.status.toUpperCase() == nextStatus) return true;

    _items[index] = prev.copyWith(status: nextStatus);
    _statusPendingIds.add(id);
    try {
      final updated = await _ds.updateItem(id: id, status: nextStatus);
      final i = _items.indexWhere((e) => e.id == id);
      if (i != -1) _items[i] = updated;
      _ok(
        active ? 'Activated' : 'Deactivated',
        '"${prev.name}" is now ${active ? 'active' : 'inactive'}.',
      );
      return true;
    } on DioException catch (e) {
      final i = _items.indexWhere((e) => e.id == id);
      if (i != -1) _items[i] = prev;
      _err('Status update failed', _msg(e));
      return false;
    } catch (_) {
      final i = _items.indexWhere((e) => e.id == id);
      if (i != -1) _items[i] = prev;
      _err('Status update failed', 'Something went wrong. Please try again.');
      return false;
    } finally {
      _statusPendingIds.remove(id);
    }
  }

  Future<bool> adjustStock(
    String id, {
    required int delta,
    String? reason,
  }) async {
    if (delta == 0) {
      _err('Invalid adjustment', 'Delta must not be zero.');
      return false;
    }
    return _mutate(() async {
      await _ds.adjustStock(id, delta: delta, reason: reason);
      _ok('Stock adjusted', 'Quantity updated.');
      await _load(page: _page.value);
      return true;
    });
  }

  Future<bool> deleteItem(String id) async {
    return _mutate(() async {
      await _ds.deleteItem(id);
      _ok('Deleted', 'Inventory item removed.');
      await _load(page: _page.value);
      return true;
    });
  }

  Future<bool> _mutate(Future<bool> Function() body) async {
    if (_isSubmitting.value) return false;
    _isSubmitting.value = true;
    try {
      return await body();
    } on DioException catch (e) {
      _err('Action failed', _msg(e));
      return false;
    } catch (_) {
      _err('Action failed', 'Something went wrong. Please try again.');
      return false;
    } finally {
      _isSubmitting.value = false;
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
