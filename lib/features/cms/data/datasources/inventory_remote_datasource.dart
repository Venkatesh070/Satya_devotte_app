import 'package:dio/dio.dart';
import 'package:satya_devotte_app/core/network/api_client.dart';
import 'package:satya_devotte_app/core/network/api_endpoints.dart';
import 'package:satya_devotte_app/core/services/media_upload_service.dart';
import 'package:satya_devotte_app/features/cms/data/models/inventory_models.dart';

class InventoryRemoteDataSource {
  InventoryRemoteDataSource(this._apiClient);
  final ApiClient _apiClient;

  /// `GET /inventory/categories`
  Future<List<InventoryCategory>> getCategories({bool activeOnly = true}) async {
    final res = await _apiClient.dio.get(
      ApiEndpoints.inventoryCategories,
      queryParameters: {'activeOnly': activeOnly},
    );
    final body = _asMap(res.data);
    final raw = _extractList(body, keys: const ['categories', 'items']);
    return raw
        .whereType<Map<String, dynamic>>()
        .map(InventoryCategory.fromJson)
        .toList(growable: false);
  }

  /// `POST /inventory/categories/seed` — superadmin only.
  Future<List<InventoryCategory>> seedCategories() async {
    final res = await _apiClient.dio.get(ApiEndpoints.inventoryCategories);
    final body = _asMap(res.data);
    final raw = _extractList(
      body,
      keys: const ['categories', 'items'],
    );
    return raw
        .whereType<Map<String, dynamic>>()
        .map(InventoryCategory.fromJson)
        .toList(growable: false);
  }

  /// `GET /inventory` — paginated list.
  Future<InventoryItemsPage> getItems({
    int page = 1,
    int limit = 20,
    String? search,
    String? category,
    String? status,
    bool? lowStock,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (search != null && search.isNotEmpty) 'search': search,
      if (category != null && category.isNotEmpty) 'category': category,
      if (status != null && status.isNotEmpty) 'status': status,
      if (lowStock != null) 'lowStock': lowStock,
    };
    final res = await _apiClient.dio.get(
      ApiEndpoints.inventory,
      queryParameters: query,
    );
    final body = _asMap(res.data);
    final rawItems = _extractList(body, keys: const ['items']);
    final items = rawItems
        .whereType<Map<String, dynamic>>()
        .map(InventoryItem.fromJson)
        .toList(growable: false);
    final p = _pagination(body, page, limit, items.length);
    return InventoryItemsPage(
      items: items,
      page: p.page,
      limit: p.limit,
      total: p.total,
      totalPages: p.totalPages,
    );
  }

  /// `GET /inventory/:id`
  Future<InventoryItem> getItem(String id) async {
    final res = await _apiClient.dio.get(ApiEndpoints.inventoryItem(id));
    return InventoryItem.fromJson(_unwrapItem(res.data));
  }

  /// `POST /inventory` — multipart create.
  Future<InventoryItem> createItem({
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
    int? lowStockThreshold,
    String status = 'ACTIVE',
    PickedFile? image,
  }) async {
    final fields = <String, dynamic>{
      'name': name,
      'category': category,
      'unit': unit,
      'itemQuantity': itemQuantity.toString(),
      'price': price.toString(),
      'currency': currency,
      'stockQuantity': stockQuantity.toString(),
      if (salePrice != null) 'salePrice': salePrice.toString(),
      if (description.isNotEmpty) 'description': description,
      if (slug != null && slug.isNotEmpty) 'slug': slug,
      if (supplierName.isNotEmpty) 'supplierName': supplierName,
      if (lowStockThreshold != null)
        'lowStockThreshold': lowStockThreshold.toString(),
      'status': status,
    };
    if (image != null) {
      fields['image'] = MultipartFile.fromBytes(
        image.bytes,
        filename: image.filename,
      );
    }
    final res = await _apiClient.dio.post<Map<String, dynamic>>(
      ApiEndpoints.inventory,
      data: FormData.fromMap(fields),
    );
    return InventoryItem.fromJson(_unwrapItem(res.data));
  }

  /// `PATCH /inventory/:id` — multipart partial update.
  Future<InventoryItem> updateItem({
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
    final fields = <String, dynamic>{
      if (name != null) 'name': name,
      if (category != null) 'category': category,
      if (unit != null) 'unit': unit,
      if (itemQuantity != null) 'itemQuantity': itemQuantity.toString(),
      if (price != null) 'price': price.toString(),
      if (salePrice != null) 'salePrice': salePrice.toString(),
      if (clearSalePrice) 'salePrice': '',
      if (currency != null) 'currency': currency,
      if (stockQuantity != null) 'stockQuantity': stockQuantity.toString(),
      if (description != null) 'description': description,
      if (slug != null) 'slug': slug,
      if (supplierName != null) 'supplierName': supplierName,
      if (lowStockThreshold != null)
        'lowStockThreshold': lowStockThreshold.toString(),
      if (status != null) 'status': status,
    };
    if (image != null) {
      fields['image'] = MultipartFile.fromBytes(
        image.bytes,
        filename: image.filename,
      );
    }
    final res = await _apiClient.dio.patch<Map<String, dynamic>>(
      ApiEndpoints.inventoryItem(id),
      data: FormData.fromMap(fields),
    );
    return InventoryItem.fromJson(_unwrapItem(res.data));
  }

  /// `POST /inventory/:id/adjust-stock` — `{ delta, reason }`.
  Future<InventoryItem> adjustStock(
    String id, {
    required int delta,
    String? reason,
  }) async {
    final res = await _apiClient.dio.post<Map<String, dynamic>>(
      ApiEndpoints.inventoryAdjustStock(id),
      data: {
        'delta': delta,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      },
    );
    final body = _asMap(res.data);
    final data = body['data'];
    if (data is Map<String, dynamic> && data['item'] is Map<String, dynamic>) {
      return InventoryItem.fromJson(data['item'] as Map<String, dynamic>);
    }
    return InventoryItem.fromJson(_unwrapItem(res.data));
  }

  /// `DELETE /inventory/:id` — soft-delete by default.
  Future<void> deleteItem(String id, {bool hard = false}) async {
    await _apiClient.dio.delete(
      ApiEndpoints.inventoryItem(id),
      queryParameters: hard ? {'hard': 'true'} : null,
    );
  }

  Map<String, dynamic> _asMap(dynamic v) =>
      v is Map<String, dynamic> ? v : <String, dynamic>{};

  List<dynamic> _extractList(
    Map<String, dynamic> body, {
    required List<String> keys,
  }) {
    final data = body['data'];
    if (data is Map<String, dynamic>) {
      for (final k in keys) {
        final v = data[k];
        if (v is List) return v;
      }
    }
    if (data is List) return data;
    for (final k in keys) {
      final v = body[k];
      if (v is List) return v;
    }
    return const [];
  }

  Map<String, dynamic> _unwrapItem(dynamic raw) {
    final body = _asMap(raw);
    final data = body['data'];
    if (data is Map<String, dynamic>) {
      if (data['item'] is Map<String, dynamic>) {
        return data['item'] as Map<String, dynamic>;
      }
      return data;
    }
    return body;
  }

  _Pagination _pagination(
    Map<String, dynamic> body,
    int requestedPage,
    int requestedLimit,
    int itemsCount,
  ) {
    final data = body['data'];
    final dataMap = data is Map<String, dynamic> ? data : <String, dynamic>{};
    final pagination = dataMap['pagination'] is Map<String, dynamic>
        ? dataMap['pagination'] as Map<String, dynamic>
        : (body['pagination'] is Map<String, dynamic>
            ? body['pagination'] as Map<String, dynamic>
            : <String, dynamic>{});

    int asInt(dynamic v, int fallback) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? fallback;
      return fallback;
    }

    final page = asInt(
      pagination['page'] ?? dataMap['page'] ?? body['page'],
      requestedPage,
    );
    final limit = asInt(
      pagination['limit'] ?? dataMap['limit'] ?? body['limit'],
      requestedLimit,
    );
    final total = asInt(
      pagination['total'] ??
          pagination['totalItems'] ??
          dataMap['total'] ??
          body['total'],
      itemsCount,
    );
    final computedPages =
        (total == 0 || limit == 0) ? 1 : ((total + limit - 1) ~/ limit);
    final totalPages = asInt(
      pagination['totalPages'] ?? pagination['pages'] ?? dataMap['totalPages'],
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
