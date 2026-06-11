import 'package:dio/dio.dart' as dio;
import 'package:get/get.dart';
import 'package:satya_devotte_app/core/services/offline_service.dart';

class OfflineRepository {
  final OfflineService _offlineService = Get.find<OfflineService>();

  /// Executes a GET request with caching support.
  /// If online, it fetches from the API and caches the result.
  /// If offline, it returns the cached data.
  Future<dynamic> getCached(
    String cacheKey,
    Future<dio.Response> Function() fetcher,
  ) async {
    if (_offlineService.isOnline.value) {
      try {
        final response = await fetcher();
        final data = response.data;
        await _offlineService.cacheData(cacheKey, data);
        return data;
      } catch (e) {
        // Fallback to cache on error even if online
        final cached = _offlineService.getCachedData(cacheKey);
        if (cached != null) return cached;
        rethrow;
      }
    } else {
      final cached = _offlineService.getCachedData(cacheKey);
      if (cached != null) return cached;
      throw Exception('Offline and no cached data found for $cacheKey');
    }
  }
}
