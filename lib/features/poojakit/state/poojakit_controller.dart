import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/features/cms/data/datasources/product_remote_datasource.dart';
import 'package:satya_devotte_app/features/cms/models/product_model.dart';

class PoojaKitController extends GetxController {
  PoojaKitController(this._dataSource);
  final ProductRemoteDataSource _dataSource;

  final _products = <ProductModel>[].obs;
  final _isLoading = false.obs;
  final _error = RxnString();

  final _page = 1.obs;
  final _pageSize = 20.obs;
  final _totalRows = 0.obs;
  final _totalPages = 1.obs;
  final _searchQuery = ''.obs;

  List<ProductModel> get products => _products;
  bool get isLoading => _isLoading.value;
  String? get error => _error.value;

  int get page => _page.value;
  int get totalPages => _totalPages.value;
  String get searchQuery => _searchQuery.value;

  @override
  void onInit() {
    super.onInit();
    fetchProducts();
  }

  void setSearchQuery(String query) {
    if (_searchQuery.value == query) return;
    _searchQuery.value = query;
    fetchProducts(refresh: true);
  }

  Future<void> fetchProducts({bool refresh = false}) async {
    if (refresh) {
      _page.value = 1;
    }

    if (_isLoading.value && !refresh) return;

    _isLoading.value = true;
    _error.value = null;

    try {
      final result = await _dataSource.getPublicProducts(
        page: _page.value,
        limit: _pageSize.value,
      );

      final items = _searchQuery.value.isEmpty
          ? result.items
          : result.items
                .where(
                  (p) => p.title.toLowerCase().contains(
                    _searchQuery.value.toLowerCase(),
                  ),
                )
                .toList();

      if (refresh) {
        _products.assignAll(items);
      } else {
        _products.addAll(items);
      }

      _totalRows.value = result.total;
      _totalPages.value = result.totalPages;
    } catch (e) {
      _error.value = e.toString();
      debugPrint('Error fetching products: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  void loadNextPage() {
    if (_page.value < _totalPages.value && !_isLoading.value) {
      _page.value++;
      fetchProducts();
    }
  }
}
