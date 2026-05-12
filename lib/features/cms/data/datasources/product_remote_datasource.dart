// lib/features/cms/data/datasources/product_remote_datasource.dart
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:satya_devotte_app/core/network/api_client.dart';
import 'package:satya_devotte_app/core/network/api_endpoints.dart';
import 'package:satya_devotte_app/core/services/media_upload_service.dart';
import 'package:satya_devotte_app/features/cms/models/product_model.dart';

class ProductRemoteDataSource {
  ProductRemoteDataSource(this._apiClient);
  final ApiClient _apiClient;

  List<dynamic> _list(Map<String, dynamic> body) {
    final d = body['data'];
    if (d is List) return d;
    if (d is Map<String, dynamic>) {
      for (final k in ['products', 'items', 'results', 'data']) {
        final v = d[k];
        if (v is List) return v;
      }
    }
    for (final k in ['products', 'items', 'results']) {
      final v = body[k];
      if (v is List) return v;
    }
    return const [];
  }

  Map<String, dynamic> _single(Map<String, dynamic> body) {
    final d = body['data'];
    if (d is Map<String, dynamic>) {
      for (final k in ['product', 'data']) {
        if (d[k] is Map<String, dynamic>) return d[k] as Map<String, dynamic>;
      }
      return d;
    }
    return body;
  }

  /// GET `/api/v1/products/all?page=&limit=` — paged product list (super-admin).
  ///
  /// Mirrors:
  /// ```
  /// curl -X GET "/api/v1/products/all?page=1&limit=10" \
  ///   -H "Authorization: Bearer <token>"
  /// ```
  ///
  /// The bearer token is attached automatically by `AuthTokenInterceptor`.
  ///
  /// The response is normalised — the backend may return any of the common
  /// pagination shapes (top-level keys, nested under `data`, or with a
  /// `pagination` envelope) and we surface the same `(items, total,
  /// totalPages)` record either way.
  Future<({List<ProductModel> items, int total, int totalPages})>
      getProducts({int page = 1, int limit = 10}) async {
    final res = await _apiClient.dio.get(
      ApiEndpoints.allProducts,
      queryParameters: {'page': page, 'limit': limit},
    );
    final body = res.data;
    if (body is! Map<String, dynamic>) {
      return (items: const <ProductModel>[], total: 0, totalPages: 1);
    }
    final items = _list(body)
        .whereType<Map<String, dynamic>>()
        .map(ProductModel.fromJson)
        .toList();

    final total = _readTotal(body, fallback: items.length);
    final totalPages = _readTotalPages(body, total: total, limit: limit);
    return (items: items, total: total, totalPages: totalPages);
  }

  int _readInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  /// Resolves `data.pagination` (most common shape for this API), falling
  /// back to a top-level `pagination` key if the envelope is flatter.
  Map<String, dynamic>? _pagination(Map<String, dynamic> body) {
    final data = body['data'];
    if (data is Map<String, dynamic>) {
      final p = data['pagination'];
      if (p is Map<String, dynamic>) return p;
    }
    final p = body['pagination'];
    if (p is Map<String, dynamic>) return p;
    return null;
  }

  int _readTotal(Map<String, dynamic> body, {required int fallback}) {
    final pag = _pagination(body);
    final candidates = <dynamic>[
      pag?['total'],
      pag?['totalCount'],
      pag?['totalItems'],
      pag?['count'],
      body['total'],
      body['totalCount'],
      body['totalItems'],
      body['count'],
      (body['data'] is Map) ? body['data']['total'] : null,
      (body['data'] is Map) ? body['data']['totalCount'] : null,
      (body['meta'] is Map) ? body['meta']['total'] : null,
    ];
    for (final c in candidates) {
      if (c != null) {
        final v = _readInt(c);
        if (v > 0) return v;
      }
    }
    return fallback;
  }

  int _readTotalPages(
    Map<String, dynamic> body, {
    required int total,
    required int limit,
  }) {
    final pag = _pagination(body);
    final candidates = <dynamic>[
      pag?['totalPages'],
      pag?['pages'],
      body['totalPages'],
      body['pages'],
      (body['data'] is Map) ? body['data']['totalPages'] : null,
      (body['meta'] is Map) ? body['meta']['totalPages'] : null,
    ];
    for (final c in candidates) {
      if (c != null) {
        final v = _readInt(c);
        if (v > 0) return v;
      }
    }
    if (total <= 0 || limit <= 0) return 1;
    return ((total - 1) ~/ limit) + 1;
  }

  /// POST `/api/v1/products/create-product` — multipart/form-data.
  ///
  /// Mirrors this curl exactly:
  /// ```
  /// curl -X POST /api/v1/products/create-product \
  ///   -F title=... -F slug=... -F description=... \
  ///   -F items='[{"itemName":"...","quantity":"...","unit":"..."}]' \
  ///   -F stockQuantity=... -F price=... -F salePrice=... \
  ///   -F currency=ZAR -F category=Ganesh \
  ///   -F status=PENDING -F productStatus=ACTIVE \
  ///   -F isFeatured=true -F image=@/path/to/file.jpg
  /// ```
  ///
  /// `status` is the review state (PENDING | APPROVED | REJECTED) that the
  /// backend / super admin manages — new submissions default to PENDING.
  /// `productStatus` is the admin-controlled lifecycle (ACTIVE | INACTIVE).
  Future<ProductModel> createProduct({
    required String title,
    required String slug,
    String description = '',
    required List<ProductItem> items,
    required int stockQuantity,
    required num price,
    num? salePrice,
    String currency = 'ZAR',
    String category = '',
    String status = 'PENDING',
    String productStatus = 'ACTIVE',
    bool isFeatured = false,
    PickedFile? image,
  }) async {
    final fields = <String, dynamic>{
      'title': title,
      'slug': slug,
      'description': description,
      // The backend expects `items` as a JSON-encoded string when using
      // multipart/form-data (single -F value, identical to the curl).
      'items': jsonEncode(items.map((e) => e.toJson()).toList()),
      'stockQuantity': stockQuantity.toString(),
      'price': price.toString(),
      if (salePrice != null) 'salePrice': salePrice.toString(),
      'currency': currency,
      'category': category,
      'status': status,
      'productStatus': productStatus,
      'isFeatured': isFeatured.toString(),
    };
    if (image != null) {
      fields['image'] = MultipartFile.fromBytes(
        image.bytes,
        filename: image.filename,
      );
    }
    try {
      final res = await _apiClient.dio.post<Map<String, dynamic>>(
        ApiEndpoints.createProduct,
        data: FormData.fromMap(fields),
      );
      final body = res.data;
      if (body == null) {
        throw Exception('Empty response from server.');
      }
      if (body['success'] == false) {
        throw Exception(
          body['message']?.toString() ?? 'Could not create product.',
        );
      }
      return ProductModel.fromJson(_single(body));
    } on DioException catch (e) {
      final raw = e.response?.data;
      if (raw is Map && raw['message'] != null) {
        throw Exception(raw['message'].toString());
      }
      rethrow;
    }
  }

  /// PATCH `/api/v1/products/:id` — update product (multipart, same fields
  /// as create). Only non-null fields are sent so partial updates work.
  Future<ProductModel> updateProduct({
    required String id,
    String? title,
    String? slug,
    String? description,
    List<ProductItem>? items,
    int? stockQuantity,
    num? price,
    num? salePrice,
    String? currency,
    String? category,
    String? status,
    String? productStatus,
    bool? isFeatured,
    PickedFile? image,
  }) async {
    final fields = <String, dynamic>{
      if (title != null) 'title': title,
      if (slug != null) 'slug': slug,
      if (description != null) 'description': description,
      if (items != null)
        'items': jsonEncode(items.map((e) => e.toJson()).toList()),
      if (stockQuantity != null) 'stockQuantity': stockQuantity.toString(),
      if (price != null) 'price': price.toString(),
      if (salePrice != null) 'salePrice': salePrice.toString(),
      if (currency != null) 'currency': currency,
      if (category != null) 'category': category,
      if (status != null) 'status': status,
      if (productStatus != null) 'productStatus': productStatus,
      if (isFeatured != null) 'isFeatured': isFeatured.toString(),
    };
    if (image != null) {
      fields['image'] = MultipartFile.fromBytes(
        image.bytes,
        filename: image.filename,
      );
    }
    try {
      final res = await _apiClient.dio.patch<Map<String, dynamic>>(
        ApiEndpoints.updateProduct(id),
        data: FormData.fromMap(fields),
      );
      final body = res.data;
      if (body == null) throw Exception('Empty response from server.');
      if (body['success'] == false) {
        throw Exception(
          body['message']?.toString() ?? 'Could not update product.',
        );
      }
      return ProductModel.fromJson(_single(body));
    } on DioException catch (e) {
      final raw = e.response?.data;
      if (raw is Map && raw['message'] != null) {
        throw Exception(raw['message'].toString());
      }
      rethrow;
    }
  }

  /// DELETE `/api/v1/products/:id`.
  Future<void> deleteProduct(String id) async {
    try {
      await _apiClient.dio.delete(ApiEndpoints.deleteProduct(id));
    } on DioException catch (e) {
      final raw = e.response?.data;
      if (raw is Map && raw['message'] != null) {
        throw Exception(raw['message'].toString());
      }
      rethrow;
    }
  }

  /// PUT `/api/v1/products/review/:id` — super-admin review.
  /// `reviewStatus` is one of APPROVED | REJECTED | QUEUED.
  Future<ProductModel> reviewProduct({
    required String id,
    required String reviewStatus,
    String? reason,
  }) async {
    try {
      final res = await _apiClient.dio.put<Map<String, dynamic>>(
        ApiEndpoints.reviewProduct(id),
        data: {
          'status': reviewStatus,
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        },
      );
      final body = res.data;
      if (body == null) throw Exception('Empty response from server.');
      if (body['success'] == false) {
        throw Exception(
          body['message']?.toString() ?? 'Could not update review status.',
        );
      }
      return ProductModel.fromJson(_single(body));
    } on DioException catch (e) {
      final raw = e.response?.data;
      if (raw is Map && raw['message'] != null) {
        throw Exception(raw['message'].toString());
      }
      rethrow;
    }
  }

  /// PATCH `/api/v1/products/:id/status` — flip lifecycle ACTIVE/INACTIVE.
  Future<ProductModel> setProductStatus({
    required String id,
    required String productStatus,
  }) async {
    try {
      final res = await _apiClient.dio.patch<Map<String, dynamic>>(
        ApiEndpoints.productStatus(id),
        data: {'productStatus': productStatus},
      );
      final body = res.data;
      if (body == null) throw Exception('Empty response from server.');
      if (body['success'] == false) {
        throw Exception(
          body['message']?.toString() ?? 'Could not update product status.',
        );
      }
      return ProductModel.fromJson(_single(body));
    } on DioException catch (e) {
      final raw = e.response?.data;
      if (raw is Map && raw['message'] != null) {
        throw Exception(raw['message'].toString());
      }
      rethrow;
    }
  }
}
