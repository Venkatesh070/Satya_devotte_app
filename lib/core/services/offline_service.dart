import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:satya_devotte_app/core/constants/app_constants.dart';
import 'package:satya_devotte_app/core/network/api_client.dart';
import 'package:satya_devotte_app/core/network/api_endpoints.dart';
import 'package:satya_devotte_app/core/network/interceptors.dart';
import 'package:satya_devotte_app/features/profile/domain/repositories/pooja_history_repository.dart';
import 'package:satya_devotte_app/features/pujas/data/datasources/favorite_deities_remote_data_source.dart';
import 'package:satya_devotte_app/features/offline/presentation/pages/no_internet_screen.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class OfflineService extends GetxService {
  late final Box _cacheBox;
  late final Box _syncQueueBox;

  final _connectivity = Connectivity();
  final isOnline = true.obs;
  final showNoInternetScreen = false.obs;
  StreamSubscription? _connectivitySubscription;

  @override
  void onInit() {
    super.onInit();
    _cacheBox = Hive.box(AppConstants.cacheBox);
    _syncQueueBox = Hive.box('sync_queue'); // New box for offline actions

    _initConnectivity();
  }

  Future<void> _initConnectivity() async {
    await checkConnectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
    );

    if (isOnline.value) {
      _proactivelyCacheAllData();
    }
  }

  Future<void> checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    await _updateConnectionStatus(result);
  }

  Future<bool> _hasRealInternetAccess() async {
    if (kIsWeb) return true;
    try {
      final lookup = await InternetAddress.lookup('google.com').timeout(
        const Duration(seconds: 3),
      );
      return lookup.isNotEmpty && lookup.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _updateConnectionStatus(List<ConnectivityResult> results) async {
    final result = results.first;
    final hasInterface = result != ConnectivityResult.none;
    bool online = hasInterface;
    if (hasInterface) {
      online = await _hasRealInternetAccess();
    }

    if (isOnline.value != online) {
      isOnline.value = online;
      if (online) {
        showNoInternetScreen.value = false;
        _processSyncQueue();
        _proactivelyCacheAllData();
      }
      debugPrint(
        'OfflineService: Connection status changed to ${isOnline.value ? 'Online' : 'Offline'}',
      );
    }
  }

  /// Shows a modal popup if there's no internet.
  /// Returns true if online, false if offline (after showing dialog).
  bool checkAndShowDialog() {
    if (isOnline.value) return true;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: const ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          child: SizedBox(height: 400, child: NoInternetScreen()),
        ),
      ),
    );
    return false;
  }

  // --- Caching Logic ---

  Future<void> cacheData(String key, dynamic data) async {
    await _cacheBox.put(key, data);
  }

  dynamic getCachedData(String key) {
    return _cacheBox.get(key);
  }

  // --- Sync Queue Logic (for Pooja steps) ---

  Future<void> queueAction(String type, Map<String, dynamic> payload) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final id = '${type}_$timestamp';
    await _syncQueueBox.put(id, {
      'type': type,
      'payload': payload,
      'timestamp': timestamp,
    });
    debugPrint('OfflineService: Action queued: $type');
  }

  Future<void> _processSyncQueue() async {
    if (!isOnline.value || _syncQueueBox.isEmpty) return;

    final keys = _syncQueueBox.keys.toList()..sort();
    debugPrint('OfflineService: Processing sync queue (${keys.length} items)');

    String? realSessionId;
    String? lastTempSessionId;

    for (final key in keys) {
      final action = _syncQueueBox.get(key);
      final payload = Map<String, dynamic>.from(action['payload']);
      final type = action['type'] as String;

      // If this action depends on a session that was started offline
      if (lastTempSessionId != null &&
          payload['sessionId'] == lastTempSessionId &&
          realSessionId != null) {
        payload['sessionId'] = realSessionId;
      }

      final result = await _dispatchAction(type, payload);

      if (result is Map && type == 'start_pooja') {
        realSessionId = (result['_id'] ?? result['id'])?.toString();
        lastTempSessionId =
            payload['tempId'] ?? 'offline_'; // Not perfect but helps
        await _syncQueueBox.delete(key);
      } else if (result == true) {
        await _syncQueueBox.delete(key);
      } else {
        break;
      }
    }
  }

  Future<dynamic> _dispatchAction(
    String type,
    Map<String, dynamic> payload,
  ) async {
    try {
      final historyRepo = Get.find<PoojaHistoryRepository>();
      switch (type) {
        case 'record_streak':
          final deviceTimeZone = payload['timezone']?.toString() ?? 'UTC';
          final apiClient = Get.find<ApiClient>();
          await apiClient.dio.post<dynamic>(
            ApiEndpoints.userStreak,
            options: Options(
              headers: {'X-Timezone': deviceTimeZone},
              extra: {kSkipApiLoaderKey: true},
            ),
          );
          return true;
        case 'start_pooja':
          final res = await historyRepo.startPooja(
            payload['poojaId'],
            scheduleId: payload['scheduleId'],
          );
          return res['data'];
        case 'update_pooja_progress':
          await historyRepo.updateProgress(
            payload['sessionId'],
            payload['currentStep'],
          );
          return true;
        case 'finish_pooja':
          if (payload.containsKey('sessionId')) {
            await historyRepo.finishPoojaBySession(payload['sessionId']);
          } else {
            await historyRepo.finishPooja(
              payload['poojaId'],
              scheduleId: payload['scheduleId'],
            );
          }
          return true;
        default:
          return true;
      }
    } catch (e) {
      debugPrint('OfflineService: Error dispatching action $type: $e');
      return false;
    }
  }

  @override
  void onClose() {
    _connectivitySubscription?.cancel();
    super.onClose();
  }

  /// Proactively caches all necessary data for full offline functionality
  Future<void> _proactivelyCacheAllData() async {
    if (!isOnline.value) return;

    debugPrint('OfflineService: Proactively caching all core data...');

    try {
      final apiClient = Get.find<ApiClient>();

      // Cache Home Page Data
      try {
        final homeResponse = await apiClient.dio.get<dynamic>(
          ApiEndpoints.home,
          options: Options(extra: {kSkipApiLoaderKey: true}),
        );
        await cacheData('home_data', homeResponse.data);
        debugPrint('OfflineService: Home data cached successfully');
      } catch (e) {
        debugPrint('OfflineService: Failed to cache home data: $e');
      }

      // Cache Deities List
      try {
        final deitiesResponse = await apiClient.dio.get<dynamic>(
          ApiEndpoints.deities,
          queryParameters: {'page': 1, 'limit': 1000},
          options: Options(extra: {kSkipApiLoaderKey: true}),
        );
        await cacheData('deities_list', deitiesResponse.data);
        debugPrint('OfflineService: Deities list cached successfully');
      } catch (e) {
        debugPrint('OfflineService: Failed to cache deities list: $e');
      }

      // Cache All Poojas (Global). API caps `limit` at 100.
      try {
        final cached = await _fetchAllPoojasForCache(apiClient);
        await cacheData('all_poojas', cached);
        debugPrint('OfflineService: All poojas cached successfully');
      } catch (e) {
        debugPrint('OfflineService: Failed to cache all poojas: $e');
      }

      // Cache All Rituals (Global)
      try {
        final ritualsResponse = await apiClient.dio.get<dynamic>(
          ApiEndpoints.rituals,
          queryParameters: {'limit': 1000},
          options: Options(extra: {kSkipApiLoaderKey: true}),
        );
        await cacheData('all_rituals', ritualsResponse.data);
        debugPrint('OfflineService: All rituals cached successfully');
      } catch (e) {
        debugPrint('OfflineService: Failed to cache all rituals: $e');
      }

      // Cache Calendar Data for Current and Next 3 Months
      try {
        final now = DateTime.now();
        for (int i = 0; i <= 3; i++) {
          final month = DateTime(now.year, now.month + i);
          final cacheKey = 'calendar_${month.year}_${month.month}';

          final calendarResponse = await apiClient.dio.get<dynamic>(
            ApiEndpoints.calendar,
            queryParameters: {'month': month.month, 'year': month.year},
            options: Options(extra: {kSkipApiLoaderKey: true}),
          );
          await cacheData(cacheKey, calendarResponse.data);
        }
        debugPrint('OfflineService: Calendar data cached successfully');
      } catch (e) {
        debugPrint('OfflineService: Failed to cache calendar data: $e');
      }

      // Cache User Streak
      try {
        final streakResponse = await apiClient.dio.get<dynamic>(
          ApiEndpoints.userStreak,
          options: Options(
            extra: {kSkipApiLoaderKey: true},
          ),
        );
        await cacheData('user_streak', streakResponse.data);
        debugPrint('OfflineService: User streak cached successfully');
      } catch (e) {
        debugPrint('OfflineService: Failed to cache user streak: $e');
      }

      // Cache Favorite Deities
      try {
        final favoriteDs = FavoriteDeitiesRemoteDataSource(apiClient);
        final favorites = await favoriteDs.fetchFavoriteDeities();
        await cacheData('favorite_deities', favorites);
        debugPrint('OfflineService: Favorite deities cached successfully');
      } catch (e) {
        debugPrint('OfflineService: Failed to cache favorite deities: $e');
      }

      // Proactively cache full details for all deities!
      try {
        final deitiesData = getCachedData('deities_list');
        List<Map> deityList = [];
        if (deitiesData is Map) {
          final data = deitiesData['data'] as Map?;
          if (data != null) {
            deityList =
                (data['deities'] ?? data['results'] ?? data['items'] ?? [])
                    .whereType<Map>()
                    .toList();
          }
          if (deityList.isEmpty) {
            deityList =
                (deitiesData['deities'] ??
                        deitiesData['results'] ??
                        deitiesData['items'] ??
                        [])
                    .whereType<Map>()
                    .toList();
          }
        } else if (deitiesData is List) {
          deityList = deitiesData.whereType<Map>().toList();
        }

        for (final deity in deityList) {
          final deityId = _entityId(deity);
          if (deityId.isNotEmpty) {
            // Skip if already cached to save network calls!
            if (getCachedData('deity_detail_$deityId') != null) continue;

            try {
              final res = await apiClient.dio.get<dynamic>(
                ApiEndpoints.deity(deityId),
                options: Options(extra: {kSkipApiLoaderKey: true}),
              );
              final fullDeity = _extractDeity(res.data);
              if (fullDeity != null) {
                await cacheData('deity_detail_$deityId', fullDeity);
                debugPrint(
                  'OfflineService: Cached details for ${fullDeity['name']}',
                );
              }
            } catch (e) {
              debugPrint('OfflineService: Failed to cache deity $deityId: $e');
            }
          }
        }
      } catch (e) {
        debugPrint('OfflineService: Error caching deity details: $e');
      }

      // Proactively cache full details for all poojas!
      try {
        final poojasData = getCachedData('all_poojas');
        List<Map> poojaList = [];
        if (poojasData is Map) {
          final data = poojasData['data'] as Map?;
          if (data != null) {
            poojaList =
                (data['poojas'] ?? data['results'] ?? data['items'] ?? [])
                    .whereType<Map>()
                    .toList();
          }
          if (poojaList.isEmpty) {
            poojaList =
                (poojasData['poojas'] ??
                        poojasData['results'] ??
                        poojasData['items'] ??
                        [])
                    .whereType<Map>()
                    .toList();
          }
        } else if (poojasData is List) {
          poojaList = poojasData.whereType<Map>().toList();
        }

        for (final p in poojaList) {
          final pId = _entityId(p);
          if (pId.isNotEmpty) {
            if (getCachedData('pooja_detail_$pId') != null) continue;
            try {
              final res = await apiClient.dio.get<dynamic>(
                ApiEndpoints.pooja(pId),
                options: Options(extra: {kSkipApiLoaderKey: true}),
              );
              final payload = res.data;
              if (payload != null) {
                await cacheData('pooja_detail_$pId', payload);
                debugPrint('OfflineService: Cached details for pooja $pId');
              }
            } catch (e) {
              debugPrint('OfflineService: Failed to cache pooja $pId: $e');
            }
          }
        }
      } catch (e) {
        debugPrint('OfflineService: Error caching pooja details: $e');
      }

      // Proactively cache full details for all rituals!
      try {
        final ritualsData = getCachedData('all_rituals');
        List<Map> ritualList = [];
        if (ritualsData is Map) {
          final data = ritualsData['data'] as Map?;
          if (data != null) {
            ritualList =
                (data['rituals'] ?? data['results'] ?? data['items'] ?? [])
                    .whereType<Map>()
                    .toList();
          }
          if (ritualList.isEmpty) {
            ritualList =
                (ritualsData['rituals'] ??
                        ritualsData['results'] ??
                        ritualsData['items'] ??
                        [])
                    .whereType<Map>()
                    .toList();
          }
        } else if (ritualsData is List) {
          ritualList = ritualsData.whereType<Map>().toList();
        }

        for (final r in ritualList) {
          final rId = _entityId(r);
          if (rId.isNotEmpty) {
            if (getCachedData('ritual_detail_$rId') != null) continue;
            try {
              final res = await apiClient.dio.get<dynamic>(
                ApiEndpoints.ritual(rId),
                options: Options(extra: {kSkipApiLoaderKey: true}),
              );
              final payload = res.data;
              if (payload != null) {
                await cacheData('ritual_detail_$rId', payload);
                debugPrint('OfflineService: Cached details for ritual $rId');
              }
            } catch (e) {
              debugPrint('OfflineService: Failed to cache ritual $rId: $e');
            }
          }
        }
      } catch (e) {
        debugPrint('OfflineService: Error caching ritual details: $e');
      }

      // Pre-cache all images for offline use
      try {
        final List<String> imageUrls = [];

        // Collect images from home data
        final homeData = getCachedData('home_data');
        if (homeData is Map) {
          final data = homeData['data'] as Map?;
          if (data != null) {
            // Collect pooja images from home page
            final poojas = data['poojas'] as List?;
            if (poojas != null) {
              for (final p in poojas) {
                if (p is Map) {
                  _collectImageUrls(p, imageUrls);
                }
              }
            }
            // Collect festival images from home page
            final festivals = data['festivals'] as List?;
            if (festivals != null) {
              for (final f in festivals) {
                if (f is Map) {
                  _collectImageUrls(f, imageUrls);
                }
              }
            }
          }
        }

        // Collect images from deities list
        final deitiesData = getCachedData('deities_list');
        if (deitiesData != null) {
          List<dynamic> deityList = [];
          if (deitiesData is Map) {
            final data = deitiesData['data'] as Map?;
            if (data != null) {
              deityList =
                  data['deities'] ?? data['results'] ?? data['items'] ?? [];
            }
            if (deityList.isEmpty) {
              deityList =
                  deitiesData['deities'] ??
                  deitiesData['results'] ??
                  deitiesData['items'] ??
                  [];
            }
          } else if (deitiesData is List) {
            deityList = deitiesData;
          }

          for (final d in deityList) {
            if (d is Map) {
              _collectImageUrls(d, imageUrls);
            }
          }
        }

        // Collect images from all poojas
        final poojasData = getCachedData('all_poojas');
        if (poojasData != null) {
          List<dynamic> poojaList = [];
          if (poojasData is Map) {
            final data = poojasData['data'] as Map?;
            if (data != null) {
              poojaList =
                  data['poojas'] ?? data['results'] ?? data['items'] ?? [];
            }
            if (poojaList.isEmpty) {
              poojaList =
                  poojasData['poojas'] ??
                  poojasData['results'] ??
                  poojasData['items'] ??
                  [];
            }
          } else if (poojasData is List) {
            poojaList = poojasData;
          }

          for (final p in poojaList) {
            if (p is Map) {
              _collectImageUrls(p, imageUrls);
            }
          }
        }

        // Pre-cache all collected images
        final cacheManager = DefaultCacheManager();
        int cachedCount = 0;
        for (final url in imageUrls) {
          if (url.isNotEmpty && url.startsWith('http')) {
            try {
              await cacheManager.downloadFile(url);
              cachedCount++;
            } catch (e) {
              debugPrint('OfflineService: Failed to cache image $url: $e');
            }
          }
        }
        debugPrint('OfflineService: Pre-cached $cachedCount images');
      } catch (e) {
        debugPrint('OfflineService: Failed to pre-cache images: $e');
      }

      debugPrint('OfflineService: Proactive caching complete!');
    } catch (e) {
      debugPrint('OfflineService: Error during proactive caching: $e');
    }
  }

  Future<Map<String, dynamic>> _fetchAllPoojasForCache(ApiClient apiClient) async {
    const pageLimit = 100;
    const maxPages = 20;
    final allPoojas = <dynamic>[];
    Map<String, dynamic> lastBody = <String, dynamic>{};

    var page = 1;
    var totalPages = 1;
    while (page <= totalPages && page <= maxPages) {
      final response = await apiClient.dio.get<dynamic>(
        ApiEndpoints.poojas,
        queryParameters: {'limit': pageLimit, 'page': page},
      );
      final raw = response.data;
      if (raw is Map<String, dynamic>) {
        lastBody = Map<String, dynamic>.from(raw);
      } else if (raw is Map) {
        lastBody = Map<String, dynamic>.from(raw);
      }

      final data = lastBody['data'];
      List<dynamic> pageItems = const [];
      Map<String, dynamic>? pagination;
      if (data is Map) {
        if (data['poojas'] is List) {
          pageItems = List<dynamic>.from(data['poojas'] as List);
        } else if (data['results'] is List) {
          pageItems = List<dynamic>.from(data['results'] as List);
        } else if (data['items'] is List) {
          pageItems = List<dynamic>.from(data['items'] as List);
        }
        if (data['pagination'] is Map) {
          pagination = Map<String, dynamic>.from(data['pagination'] as Map);
        }
      } else if (lastBody['poojas'] is List) {
        pageItems = List<dynamic>.from(lastBody['poojas'] as List);
      }
      allPoojas.addAll(pageItems);
      totalPages = (pagination?['totalPages'] as num?)?.toInt() ?? 1;
      if (totalPages < 1) totalPages = 1;
      page++;
    }

    final dataMap = lastBody['data'] is Map
        ? Map<String, dynamic>.from(lastBody['data'] as Map)
        : <String, dynamic>{};
    dataMap['poojas'] = allPoojas;
    if (dataMap['pagination'] is Map) {
      final pagination = Map<String, dynamic>.from(dataMap['pagination'] as Map);
      pagination['limit'] = allPoojas.length;
      pagination['page'] = 1;
      pagination['totalPages'] = 1;
      dataMap['pagination'] = pagination;
    }
    lastBody['data'] = dataMap;
    return lastBody;
  }

  /// Helper method to collect image URLs from a map (pooja, deity, festival, etc.)
  void _collectImageUrls(Map data, List<String> urls) {
    // Check common image fields
    if (data['imageUrl'] is String) {
      urls.add(data['imageUrl'] as String);
    }
    if (data['image'] is String) {
      urls.add(data['image'] as String);
    }

    // Check media object
    if (data['media'] is Map) {
      final media = data['media'] as Map;
      if (media['images'] is List) {
        for (final img in media['images'] as List) {
          if (img is String) {
            urls.add(img);
          }
        }
      }
    }

    // Check if there's a nested deity object
    if (data['deity'] is Map) {
      _collectImageUrls(data['deity'] as Map, urls);
    }
  }

  /// Helper method to get entity ID from a map
  String _entityId(Map map) {
    return (map['_id'] ?? map['id'] ?? '').toString().trim();
  }

  /// Helper method to extract deity from API response
  Map<String, dynamic>? _extractDeity(dynamic payload) {
    if (payload is! Map) return null;
    final data = payload['data'];
    if (data is Map) {
      final deity = data['deity'];
      if (deity is Map) return Map<String, dynamic>.from(deity);
      final deities = data['deities'];
      if (deities is List && deities.isNotEmpty && deities.first is Map) {
        return Map<String, dynamic>.from(deities.first as Map);
      }
      return Map<String, dynamic>.from(data);
    }
    final deity = payload['deity'];
    if (deity is Map) return Map<String, dynamic>.from(deity);
    return Map<String, dynamic>.from(payload);
  }
}
