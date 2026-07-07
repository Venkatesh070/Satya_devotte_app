/// Generic paginated API response for CMS list endpoints.
class CmsPagedResult<T> {
  const CmsPagedResult({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final List<T> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
}

/// Extracts pagination metadata from common Satya API response shapes.
class CmsPaginationParser {
  const CmsPaginationParser._();

  static int asInt(dynamic value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? fallback;
    return fallback;
  }

  static ({
    int page,
    int limit,
    int total,
    int totalPages,
  }) fromBody(
    dynamic body, {
    required int requestedPage,
    required int requestedLimit,
    required int itemCount,
  }) {
    if (body is! Map) {
      return (
        page: requestedPage,
        limit: requestedLimit,
        total: itemCount,
        totalPages: 1,
      );
    }

    final dataMap = body['data'];
    final Map<String, dynamic> paginationMap = () {
      if (dataMap is Map<String, dynamic>) {
        final nested = dataMap['pagination'];
        if (nested is Map<String, dynamic>) return nested;
      }
      final top = body['pagination'];
      if (top is Map<String, dynamic>) return top;
      return const <String, dynamic>{};
    }();

    final root = dataMap is Map<String, dynamic> ? dataMap : body;

    final page = asInt(
      paginationMap['page'] ?? root['page'] ?? body['page'],
      fallback: requestedPage,
    );
    final limit = asInt(
      paginationMap['limit'] ?? root['limit'] ?? body['limit'],
      fallback: requestedLimit,
    );
    final total = asInt(
      paginationMap['total'] ??
          paginationMap['totalItems'] ??
          root['total'] ??
          root['totalItems'] ??
          body['total'] ??
          body['totalItems'],
      fallback: itemCount,
    );
    final computedPages =
        (total <= 0 || limit <= 0) ? 1 : ((total + limit - 1) ~/ limit);
    final totalPages = asInt(
      paginationMap['totalPages'] ??
          paginationMap['pages'] ??
          root['totalPages'] ??
          body['totalPages'] ??
          body['pages'],
      fallback: computedPages,
    );

    return (
      page: page < 1 ? 1 : page,
      limit: limit < 1 ? requestedLimit : limit,
      total: total < 0 ? 0 : total,
      totalPages: totalPages < 1 ? 1 : totalPages,
    );
  }
}
