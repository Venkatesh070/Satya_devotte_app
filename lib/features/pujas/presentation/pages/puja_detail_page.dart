import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:satya_devotte_app/core/network/api_client.dart';
import 'package:satya_devotte_app/core/network/api_endpoints.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/features/profile/presentation/controllers/pooja_history_controller.dart';
import 'package:satya_devotte_app/shared/widgets/custom_button.dart';
import 'package:satya_devotte_app/shared/widgets/chakra_loading_indicator.dart';
import 'package:video_player/video_player.dart';
import 'package:satya_devotte_app/features/pujas/presentation/models/pooja_view_model.dart';
import 'package:satya_devotte_app/features/pujas/presentation/widgets/puja_shared_widgets.dart';
import 'package:satya_devotte_app/features/pujas/presentation/pages/pooja_step_wizard.dart';
import 'package:satya_devotte_app/features/pujas/data/datasources/favorite_deities_remote_data_source.dart';
import 'package:satya_devotte_app/core/services/offline_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:satya_devotte_app/core/utils/toast_util.dart';
import 'package:satya_devotte_app/shared/widgets/rich_text_display.dart';
import 'package:satya_devotte_app/shared/widgets/step_rich_text_display.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;

/// Pooja / Ritual detail page – pixel-aligned to the Sathya Devotee
/// Figma reference (saffron temple header, circular deity portrait,
/// pill segmented tabs, white section cards, gradient \"Get Started\"
/// CTA at the bottom).
///
/// Loads `GET /api/v1/poojas/:id` and segregates every server field
/// (`purpose`, `deitySummary`, `preparation`, `steps`, `mantra`,
/// `spiritualMeaning`, `guidance`, `completion`, `blessings`) under
/// four scrollable tabs:
///
///   • Calender Puja's        – schedule / status / festivals
///   • About the Deity        – deitySummary + populated `deity` doc
///   • Rituals and Remedies   – purpose / preparation / steps / mantra /
///                              spiritualMeaning / guidance / completion
///   • Stories of Deity       – narrative sections from the deity doc
class RitualDetailPage extends StatefulWidget {
  const RitualDetailPage({super.key});

  @override
  State<RitualDetailPage> createState() => _RitualDetailPageState();
}

class _RitualDetailPageState extends State<RitualDetailPage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _pooja;
  Map<String, dynamic>? _selectedDeity;
  List<Map<String, dynamic>> _deityPoojas = const [];
  List<Map<String, dynamic>> _deityRituals = const [];
  final Map<String, String> _festivalNames = const {};
  Set<String> _favoriteDeityIds = <String>{};
  late final FavoriteDeitiesRemoteDataSource _favoriteDeitiesApi;

  late final TabController _tabController;
  late final PoojaHistoryController _historyController;
  static const _tabs = <String>[
    'Calendar Puja\'s',
    'About the Deity',
    'Stories of Deity',
  ];

  @override
  void initState() {
    super.initState();
    _favoriteDeitiesApi = FavoriteDeitiesRemoteDataSource(
      Get.find<ApiClient>(),
    );
    _loadFavoritesFromApi();
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: 0,
    );
    _tabController.addListener(_onTabChanged);
    _historyController = Get.find<PoojaHistoryController>();
    _historyController.fetchHistory();

    final args = Get.arguments;
    debugPrint('[Detail] initState args type=${args.runtimeType}');
    if (args is Map) {
      debugPrint(
        '[Detail] initState args keys=${args.keys} type=${args['type']}',
      );
      if (args.containsKey('deity')) {
        debugPrint(
          '[Detail] args["deity"] type=${args['deity'].runtimeType} value=${args['deity'].toString().length > 100 ? "${args['deity'].toString().substring(0, 100)}..." : args['deity']}',
        );
      }
    }
    if (args is Map && args['type'] == 'deity') {
      _selectedDeity = Map<String, dynamic>.from(args);
      _isLoading = true;
      final id = _entityId(args);
      if (id.isNotEmpty) {
        _loadDeityDetailAndPoojas(id);
      } else {
        _isLoading = false;
        _error = 'No deity selected.';
      }
    } else if (args is Map) {
      _pooja = Map<String, dynamic>.from(args);
      final id = args['_id']?.toString() ?? args['id']?.toString();
      debugPrint('[Detail] initState path=home/search pooja id=$id');
      if (id != null && id.isNotEmpty) _loadDetail(id);
    } else if (args is String && args.isNotEmpty) {
      debugPrint('[Detail] initState path=string id=$args');
      _loadDetail(args);
    } else {
      _error = 'No pooja selected.';
    }
  }

  Future<void> _loadFavoritesFromApi() async {
    final offlineService = Get.find<OfflineService>();
    const cacheKey = 'favorite_deities';

    try {
      List<dynamic> raw;
      if (offlineService.isOnline.value) {
        raw = await _favoriteDeitiesApi.fetchFavoriteDeities();
        await offlineService.cacheData(cacheKey, raw);
      } else {
        final cached = offlineService.getCachedData(cacheKey);
        raw = cached is List ? cached : const [];
      }

      if (!mounted) return;
      final ids = <String>{};
      for (final m in raw) {
        final id = (m['_id'] ?? m['id'] ?? '').toString();
        if (id.isNotEmpty) ids.add(id);
      }
      setState(() => _favoriteDeityIds = ids);
    } catch (_) {
      final offlineService = Get.find<OfflineService>();
      final cached = offlineService.getCachedData(cacheKey);
      if (cached is List) {
        final ids = <String>{};
        for (final m in cached) {
          final id = (m['_id'] ?? m['id'] ?? '').toString();
          if (id.isNotEmpty) ids.add(id);
        }
        if (mounted) setState(() => _favoriteDeityIds = ids);
      }
    }
  }

  Future<void> _toggleFavorite(String deityId) async {
    final id = deityId.trim();
    if (id.isEmpty) return;

    final wasFavorite = _favoriteDeityIds.contains(id);
    try {
      if (wasFavorite) {
        await _favoriteDeitiesApi.removeFavorite(id);
      } else {
        await _favoriteDeitiesApi.addFavorite(id);
      }
    } on DioException catch (e) {
      if (!mounted) return;
      final msg =
          (e.response?.data is Map
              ? (e.response!.data['message'] ?? e.message)?.toString()
              : null) ??
          e.message ??
          'Could not update favorites.';
      ToastUtil.showInfo(msg);
      return;
    } catch (e) {
      if (!mounted) return;
      ToastUtil.showInfo(e.toString());
      return;
    }

    if (!mounted) return;
    setState(() {
      final next = {..._favoriteDeityIds};
      if (wasFavorite) {
        next.remove(id);
      } else {
        next.add(id);
      }
      _favoriteDeityIds = next;
    });
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  // ───────────────────────── networking ──────────────────────────
  Future<void> _loadDeityDetailAndPoojas(String deityId) async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    } else {
      _isLoading = true;
      _error = null;
    }

    final offlineService = Get.find<OfflineService>();
    final deityCacheKey = 'deity_detail_$deityId';
    final poojasCacheKey = 'deity_poojas_$deityId';
    final ritualsCacheKey = 'deity_rituals_$deityId';

    Map<String, dynamic>? deity = _selectedDeity;
    try {
      if (offlineService.isOnline.value) {
        final res = await Get.find<ApiClient>().dio.get<dynamic>(
          ApiEndpoints.deity(deityId),
        );
        deity = _extractDeity(res.data) ?? deity;
        if (deity != null) await offlineService.cacheData(deityCacheKey, deity);
      } else {
        final cached = offlineService.getCachedData(deityCacheKey);
        if (cached is Map) deity = Map<String, dynamic>.from(cached);
      }
    } catch (e) {
      debugPrint('Deity detail fetch failed: $e');
      final cached = offlineService.getCachedData(deityCacheKey);
      if (cached is Map) deity = Map<String, dynamic>.from(cached);
    }

    List<Map<String, dynamic>> poojas = const [];
    try {
      poojas = await _loadPoojasForDeity(deityId, deity);
      if (offlineService.isOnline.value) {
        await offlineService.cacheData(poojasCacheKey, poojas);
      }
    } catch (e) {
      debugPrint('Associated pujas fetch failed: $e');
      final cached = offlineService.getCachedData(poojasCacheKey);
      if (cached is List) {
        poojas = cached.map((e) => Map<String, dynamic>.from(e)).toList();
      } else if (mounted) {
        setState(() => _error = 'Failed to load calendar pujas.');
      }
    }

    List<Map<String, dynamic>> rituals = const [];
    try {
      if (offlineService.isOnline.value) {
        final res = await Get.find<ApiClient>().dio.get<dynamic>(
          ApiEndpoints.rituals,
          queryParameters: {'deity': deityId, 'limit': 50},
        );
        rituals = _extractList(res.data);
        rituals = rituals
            .where((r) => _poojaBelongsToDeity(r, deityId, deity))
            .toList(growable: false);
        rituals = await _hydrateRitualsWithDetails(rituals);
        await offlineService.cacheData(ritualsCacheKey, rituals);
      } else {
        final cached = offlineService.getCachedData(ritualsCacheKey);
        if (cached is List) {
          rituals = cached.map((e) => Map<String, dynamic>.from(e)).toList();
        }
      }
    } catch (e) {
      debugPrint('Associated rituals fetch failed: $e');
      final cached = offlineService.getCachedData(ritualsCacheKey);
      if (cached is List) {
        rituals = cached.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    }

    if (!mounted) return;
    setState(() {
      _selectedDeity = deity;
      _deityPoojas = poojas
          .map((p) => _mergeDeityIntoPooja(p, deity))
          .toList(growable: false);
      _deityRituals = rituals;
      _pooja = _deityPoojas.isNotEmpty
          ? _deityPoojas.first
          : _deityShellPooja(deity ?? <String, dynamic>{'_id': deityId});
      debugPrint(
        '[Detail] _loadDeityDetailAndPoojas done: _pooja["deity"] type=${_pooja?['deity'].runtimeType} value=${(_pooja?['deity']?.toString() ?? '').length > 100 ? "${_pooja?['deity'].toString().substring(0, 100)}..." : _pooja?['deity']}',
      );
      _isLoading = false;
    });
  }

  Future<List<Map<String, dynamic>>> _loadPoojasForDeity(
    String deityId,
    Map<String, dynamic>? deity,
  ) async {
    final offlineService = Get.find<OfflineService>();
    final poojasCacheKey = 'deity_poojas_$deityId';

    Future<List<Map<String, dynamic>>> request({String? deityQuery}) async {
      if (!offlineService.isOnline.value) return const [];
      final res = await Get.find<ApiClient>().dio.get<dynamic>(
        ApiEndpoints.poojas,
        queryParameters: {
          if (deityQuery != null && deityQuery.isNotEmpty) 'deity': deityQuery,
          'limit': 100,
        },
      );
      return _extractList(res.data);
    }

    try {
      List<Map<String, dynamic>> list = [];
      if (offlineService.isOnline.value) {
        final queried = await request(deityQuery: deityId);
        list = queried
            .where((p) => _poojaBelongsToDeity(p, deityId, deity))
            .toList(growable: false);
      }

      final associated = await _loadPoojasFromDeityAssociation(deity);
      list = _mergePoojaListsById(list, associated);

      // If online returned nothing or we are offline, try caches
      if (list.isEmpty) {
        final associatedIds = _poojaIdsFromDeity(deity).toSet();

        bool matchesDeity(Map<String, dynamic> p) {
          if (_poojaBelongsToDeity(p, deityId, deity)) return true;
          final id = _entityId(p);
          return id.isNotEmpty && associatedIds.contains(id);
        }

        // 1. Try specific deity cache first (most accurate)
        final specificCache = offlineService.getCachedData(poojasCacheKey);
        if (specificCache is List && specificCache.isNotEmpty) {
          return specificCache
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }

        // 2. Try global cache as fallback
        final globalCache = offlineService.getCachedData('all_poojas');
        if (globalCache != null) {
          final globalList = _extractList(globalCache);
          final filtered = globalList
              .where(matchesDeity)
              .toList(growable: false);
          if (filtered.isNotEmpty) return filtered;
        }
      }
      return list;
    } catch (e) {
      debugPrint('Associated pujas fetch failed: $e');

      // Error occurred (likely network), try all available caches
      final specificCache = offlineService.getCachedData(poojasCacheKey);
      if (specificCache is List && specificCache.isNotEmpty) {
        return specificCache.map((e) => Map<String, dynamic>.from(e)).toList();
      }

      final globalCache = offlineService.getCachedData('all_poojas');
      if (globalCache != null) {
        final globalList = _extractList(globalCache);
        final associatedIds = _poojaIdsFromDeity(deity).toSet();
        return globalList
            .where((p) {
              if (_poojaBelongsToDeity(p, deityId, deity)) return true;
              final id = _entityId(p);
              return id.isNotEmpty && associatedIds.contains(id);
            })
            .toList(growable: false);
      }
      rethrow;
    }
  }

  Future<void> _loadDetail(String id) async {
    if (_isLoading) return;
    setState(() {
      _isLoading = _pooja == null;
      _error = null;
    });

    final offlineService = Get.find<OfflineService>();
    final cacheKey = 'pooja_detail_$id';

    try {
      Map<String, dynamic>? pooja;
      if (offlineService.isOnline.value) {
        final res = await Get.find<ApiClient>().dio.get<dynamic>(
          ApiEndpoints.pooja(id),
        );
        final payload = res.data;
        final data = (payload is Map) ? payload['data'] : null;
        if (data is Map) {
          final inner = data['pooja'];
          pooja = inner is Map
              ? Map<String, dynamic>.from(inner)
              : Map<String, dynamic>.from(data);
        } else if (payload is Map) {
          pooja = Map<String, dynamic>.from(payload);
        }
        if (pooja != null) await offlineService.cacheData(cacheKey, pooja);
      } else {
        // Load pooja from cache!
        final cached = offlineService.getCachedData(cacheKey);
        if (cached is Map) {
          pooja = Map<String, dynamic>.from(cached);
        } else {
          final allCached = offlineService.getCachedData('all_poojas');
          if (allCached != null) {
            final list = _extractList(allCached);
            for (final item in list) {
              if ((item['_id'] ?? item['id'])?.toString() == id) {
                pooja = item;
                break;
              }
            }
          }
        }
      }

      if (!mounted) return;

      debugPrint(
        '[Detail] _loadDetail: raw API pooja["deity"] type=${pooja?['deity'].runtimeType} value=${(pooja?['deity']?.toString() ?? '').length > 100 ? "${pooja?['deity'].toString().substring(0, 100)}..." : pooja?['deity']}',
      );

      // Update state with the loaded pooja!
      setState(() => _pooja = pooja ?? _pooja);

      // CRITICAL: Always call _hydrateDeityIfNeeded after loading pooja, even from cache!
      await _hydrateDeityIfNeeded();
      debugPrint(
        '[Detail] _loadDetail: after hydration _pooja["deity"] type=${_pooja?['deity'].runtimeType}',
      );
    } on DioException catch (e) {
      // On network error, try to load from cache!
      final cached = offlineService.getCachedData(cacheKey);
      if (cached is Map) {
        setState(() => _pooja = Map<String, dynamic>.from(cached));
        // Still call _hydrateDeityIfNeeded to get deity info!
        await _hydrateDeityIfNeeded();
      } else if (mounted) {
        setState(() => _error = e.message ?? 'Failed to load pooja.');
      }
    } catch (_) {
      if (!mounted) return;
      // Fallback to cache on any error!
      final cached = offlineService.getCachedData(cacheKey);
      if (cached is Map) {
        setState(() => _pooja = Map<String, dynamic>.from(cached));
        await _hydrateDeityIfNeeded();
      } else {
        setState(() => _error = 'Failed to load pooja.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  static Map<String, dynamic>? _extractSingleRitual(dynamic payload) {
    if (payload is! Map) return null;
    final map = Map<String, dynamic>.from(payload);
    final data = map['data'];
    if (data is Map) {
      final nested = Map<String, dynamic>.from(data);
      if (nested['ritual'] is Map) {
        return Map<String, dynamic>.from(nested['ritual'] as Map);
      }
      return nested;
    }
    if (map['ritual'] is Map) {
      return Map<String, dynamic>.from(map['ritual'] as Map);
    }
    return map;
  }

  Future<List<Map<String, dynamic>>> _hydrateRitualsWithDetails(
    List<Map<String, dynamic>> rituals,
  ) async {
    if (rituals.isEmpty || !Get.find<OfflineService>().isOnline.value) {
      return rituals;
    }

    final api = Get.find<ApiClient>().dio;
    final hydrated = await Future.wait(
      rituals.map((ritual) async {
        final id = _entityId(ritual);
        if (id.isEmpty) return ritual;
        try {
          final res = await api.get<dynamic>(ApiEndpoints.ritual(id));
          return _extractSingleRitual(res.data) ?? ritual;
        } catch (e) {
          debugPrint('Ritual detail fetch failed for $id: $e');
          return ritual;
        }
      }),
    );
    return hydrated;
  }

  static List<Map<String, dynamic>> _extractList(dynamic payload) {
    dynamic data = payload;
    if (payload is Map<String, dynamic>) {
      data = payload['data'] ?? payload;
      if (data is Map) {
        data =
            data['poojas'] ??
            data['results'] ??
            data['items'] ??
            data['docs'] ??
            data['data'] ??
            data['rituals'] ??
            data['ritual'] ??
            data;
      }
      if (data is Map) {
        data =
            data['poojas'] ??
            data['results'] ??
            data['items'] ??
            data['rituals'] ??
            data['ritual'] ??
            payload['poojas'] ??
            payload['results'] ??
            payload['items'] ??
            payload['rituals'] ??
            payload['ritual'];
      }
    }
    if (data is! List) {
      if (data is Map) return [Map<String, dynamic>.from(data)];
      return const [];
    }
    return data
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList(growable: false);
  }

  static Map<String, dynamic>? _extractDeity(dynamic payload) {
    if (payload is! Map<String, dynamic>) return null;
    final data = payload['data'];
    if (data is Map<String, dynamic>) {
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

  static Map<String, dynamic>? _extractPooja(dynamic payload) {
    if (payload is! Map) return null;
    final data = payload['data'];
    if (data is Map) {
      final inner = data['pooja'];
      if (inner is Map) return Map<String, dynamic>.from(inner);
      return Map<String, dynamic>.from(data);
    }
    final pooja = payload['pooja'];
    if (pooja is Map) return Map<String, dynamic>.from(pooja);
    return Map<String, dynamic>.from(payload);
  }

  static List<String> _poojaIdsFromDeity(Map<String, dynamic>? deity) {
    if (deity == null) return const [];
    final rawPujas = deity['pujas'];
    if (rawPujas is! List) return const [];
    final ids = <String>[];
    for (final item in rawPujas) {
      if (item is Map) {
        final id = _entityId(item);
        if (id.isNotEmpty) ids.add(id);
      } else {
        final id = item.toString().trim();
        if (id.isNotEmpty) ids.add(id);
      }
    }
    return ids;
  }

  static List<Map<String, dynamic>> _mergePoojaListsById(
    List<Map<String, dynamic>> primary,
    List<Map<String, dynamic>> secondary,
  ) {
    final byId = <String, Map<String, dynamic>>{};
    for (final pooja in [...primary, ...secondary]) {
      final id = _entityId(pooja);
      if (id.isEmpty) continue;
      byId[id] = pooja;
    }
    return byId.values.toList(growable: false);
  }

  static bool _isApprovedPooja(Map<String, dynamic> pooja) {
    final status = (pooja['status'] ?? 'APPROVED').toString().trim();
    return status.isEmpty || status == 'APPROVED';
  }

  Future<Map<String, dynamic>?> _fetchPoojaById(String id) async {
    final offlineService = Get.find<OfflineService>();
    final cacheKey = 'pooja_detail_$id';

    if (!offlineService.isOnline.value) {
      final cached = offlineService.getCachedData(cacheKey);
      if (cached is Map) return Map<String, dynamic>.from(cached);
      return null;
    }

    try {
      final res = await Get.find<ApiClient>().dio.get<dynamic>(
        ApiEndpoints.pooja(id),
      );
      final pooja = _extractPooja(res.data);
      if (pooja != null) {
        await offlineService.cacheData(cacheKey, pooja);
      }
      return pooja;
    } catch (e) {
      debugPrint('Fetch pooja $id failed: $e');
      final cached = offlineService.getCachedData(cacheKey);
      if (cached is Map) return Map<String, dynamic>.from(cached);
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _loadPoojasFromDeityAssociation(
    Map<String, dynamic>? deity,
  ) async {
    final ids = _poojaIdsFromDeity(deity);
    if (ids.isEmpty) return const [];

    final fetched = await Future.wait(ids.map(_fetchPoojaById));
    return fetched
        .whereType<Map<String, dynamic>>()
        .where(_isApprovedPooja)
        .toList(growable: false);
  }

  static Map<String, dynamic> _mergeDeityIntoPooja(
    Map<String, dynamic> pooja,
    Map<String, dynamic>? deity,
  ) {
    final current = Map<String, dynamic>.from(pooja);
    if (deity == null || deity.isEmpty) return current;
    final existing = current['deity'];
    if (existing is Map) {
      current['deity'] = {
        ...existing.map((k, v) => MapEntry(k.toString(), v)),
        ...deity,
      };
    } else {
      current['deity'] = deity;
    }
    return current;
  }

  static Map<String, dynamic> _deityShellPooja(Map<String, dynamic> deity) {
    String _extractString(dynamic v) {
      if (v == null) return '';
      if (v is String) return v.trim();
      if (v is List) {
        return v
            .map((e) => _extractString(e))
            .where((s) => s.isNotEmpty)
            .join(', ');
      }
      if (v is Map) {
        final name = v['name'] ?? v['title'] ?? '';
        return _extractString(name);
      }
      return v.toString().trim();
    }

    final name = _extractString(deity['name'] ?? deity['title'] ?? '');
    final description = _extractString(
      deity['description'] ?? deity['about'] ?? '',
    );
    return {
      'title': name,
      'description': description,
      'deity': deity,
      'deitySummary': {
        'about': description,
        'blessings': deity['blessings'] ?? const [],
      },
      'media':
          deity['media'] ??
          {
            if (deity['imageUrl'] != null) 'images': [deity['imageUrl']],
          },
    };
  }

  static bool _poojaBelongsToDeity(
    Map<String, dynamic> pooja,
    String deityId,
    Map<String, dynamic>? deity,
  ) {
    final expectedId = deityId.trim();
    final expectedName = (deity?['name'] ?? deity?['title'] ?? '')
        .toString()
        .trim()
        .toLowerCase();

    bool matches(dynamic raw) {
      if (raw == null) return false;
      if (raw is Map) {
        final id = _entityId(raw);
        if (id == expectedId) return true;
        final name = (raw['name'] ?? raw['title'] ?? '')
            .toString()
            .trim()
            .toLowerCase();
        return expectedName.isNotEmpty && name == expectedName;
      }
      if (raw is List) {
        return raw.any((item) => matches(item));
      }
      final value = raw.toString().trim();
      if (value == expectedId) return true;
      return expectedName.isNotEmpty && value.toLowerCase() == expectedName;
    }

    final rawDeity = pooja['deity'] ?? pooja['deityId'] ?? pooja['deity_id'];
    return matches(rawDeity);
  }

  static String _entityId(Map<dynamic, dynamic> map) {
    return (map['_id'] ?? map['id'] ?? '').toString().trim();
  }

  /// Same list logic as [_CalendarTab] — used to decide if Get Started is shown.
  List<Map<String, dynamic>> _calendarPoojasFor(PoojaView pooja) {
    final activePoojaId = _entityId(pooja.raw);
    if (_deityPoojas.isNotEmpty) return _deityPoojas;
    if (activePoojaId.isNotEmpty) return [_pooja!];
    return const [];
  }

  /// When the populated `deity` field is just an ObjectId string we hit
  /// `/api/v1/deities/:id` so the About / Stories tabs can render the
  /// full set of cards (family, posture, description, weapons, chakra,
  /// astrology, …) shown in the Figma.
  Future<void> _hydrateDeityIfNeeded() async {
    final p = _pooja;
    if (p == null) return;
    final d = p['deity'];
    debugPrint(
      '[Detail] _hydrateDeityIfNeeded: p["deity"] type=${d.runtimeType} value=${d.toString().length > 100 ? "${d.toString().substring(0, 100)}..." : d}',
    );

    // Get deity ID from populated field or pooja reference.
    // Also try from a list (some API endpoints return deity as [])
    dynamic deityIdFromList;
    if (d is List && d.isNotEmpty) {
      final first = d.first;
      if (first is Map) deityIdFromList = first['_id'] ?? first['id'];
      if (first is String) deityIdFromList = first;
    }
    final rawId = d is String
        ? d
        : (d is Map ? (d['_id'] ?? d['id']) : null) ??
              deityIdFromList ??
              p['deityId'] ??
              p['deity_id'];
    final id = rawId?.toString().trim() ?? '';
    debugPrint(
      '[Detail] _hydrateDeityIfNeeded: extracted rawId=$rawId id="$id" p.deityId=${p['deityId']} p.deity_id=${p['deity_id']} p.keys=${p.keys.take(10).toList()}',
    );
    if (id.isEmpty) return;

    // Verify it's a valid ObjectID!
    final isObjectId =
        id.length == 24 && RegExp(r'^[0-9a-fA-F]+$').hasMatch(id);
    if (!isObjectId) return;

    final offlineService = Get.find<OfflineService>();
    final deityCacheKey = 'deity_detail_$id';
    final ritualsCacheKey = 'deity_rituals_$id';

    void applyDeity(
      Map<String, dynamic> deity, {
      List<Map<String, dynamic>>? rituals,
    }) {
      _pooja = _mergeDeityIntoPooja(_pooja!, deity);
      if (rituals != null) {
        // Filter rituals to only those belonging to this deity
        final filteredRituals = rituals
            .where((r) => _poojaBelongsToDeity(r, id, deity))
            .toList(growable: false);
        _deityRituals = filteredRituals;
      }
    }

    // Offline: use cached deity/rituals only.
    if (!offlineService.isOnline.value) {
      final cachedDeity = offlineService.getCachedData(deityCacheKey);
      if (cachedDeity is! Map || !mounted) return;

      // Cast cachedDeity to Map<String, dynamic>
      final deityMap = Map<String, dynamic>.from(cachedDeity);

      final cachedRituals = offlineService.getCachedData(ritualsCacheKey);
      setState(() {
        applyDeity(deityMap);
        if (cachedRituals is List) {
          final ritualsList = cachedRituals
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          // Filter cached rituals as well
          final filteredRituals = ritualsList
              .where((r) => _poojaBelongsToDeity(r, id, deityMap))
              .toList(growable: false);
          _deityRituals = filteredRituals;
        }
      });
      return;
    }

    // Online: always fetch fresh deity data (embedded pooja deity may be stale).
    try {
      final res = await Get.find<ApiClient>().dio.get<dynamic>(
        ApiEndpoints.deity(id),
      );
      final deity = _extractDeity(res.data);
      if (!mounted || deity == null) return;

      await offlineService.cacheData(deityCacheKey, deity);

      List<Map<String, dynamic>>? rituals;
      try {
        final ritRes = await Get.find<ApiClient>().dio.get<dynamic>(
          ApiEndpoints.rituals,
          queryParameters: {'deity': id, 'limit': 50},
        );
        rituals = _extractList(ritRes.data);
        rituals = await _hydrateRitualsWithDetails(rituals);
        await offlineService.cacheData(ritualsCacheKey, rituals);
      } catch (e) {
        debugPrint('Hydration: rituals fetch failed: $e');
      }

      if (!mounted) return;
      setState(() => applyDeity(deity, rituals: rituals));
    } catch (e) {
      debugPrint('Hydration: deity fetch failed: $e');
      final cachedDeity = offlineService.getCachedData(deityCacheKey);
      if (cachedDeity is! Map || !mounted) return;

      // Cast cachedDeity to Map<String, dynamic>
      final deityMap = Map<String, dynamic>.from(cachedDeity);

      final cachedRituals = offlineService.getCachedData(ritualsCacheKey);
      setState(() {
        applyDeity(deityMap);
        if (cachedRituals is List) {
          final ritualsList = cachedRituals
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          // Filter cached rituals as well
          final filteredRituals = ritualsList
              .where((r) => _poojaBelongsToDeity(r, id, deityMap))
              .toList(growable: false);
          _deityRituals = filteredRituals;
        }
      });
    }
  }

  // ───────────────────────── build ───────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isLoading && _pooja == null) {
      return const Scaffold(
        backgroundColor: AppColors.appBgColor,
        body: Center(child: ChakraLoadingIndicator()),
      );
    }
    if (_pooja == null) {
      return Scaffold(
        backgroundColor: AppColors.appBgColor,
        appBar: AppBar(
          backgroundColor: AppColors.appBgColor,
          elevation: 0,
          foregroundColor: AppColors.textColor,
        ),
        body: Center(
          child: Text(
            _error ?? 'No ritual found',
            style: AppTypography.inter(color: AppColors.textColor),
          ),
        ),
      );
    }

    final activePooja = _pooja!;
    final p = PoojaView(activePooja);
    debugPrint(
      '[Detail] build: p.deityDoc=${p.deityDoc} p.deityName="${p.deityName}"',
    );
    final hasCalendarPujas = _calendarPoojasFor(p).isNotEmpty;
    final showGetStartedButton =
        _tabController.index == 0 &&
        hasCalendarPujas &&
        _entityId(activePooja).isNotEmpty;

    return Scaffold(
      backgroundColor: Color(0XFFFFF4E0),
      body: Stack(
        children: [
          NestedScrollView(
            headerSliverBuilder: (_, __) => [
              SliverToBoxAdapter(child: _HeroHeader(pooja: p)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const HeaderDivider(),
                      const SizedBox(height: 14),

                      if (p.deityDescription.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: RichTextDisplay(
                            p.deityDescription,
                            textAlign: TextAlign.justify,
                            style: AppTypography.inter(
                              fontSize: 14,
                              height: 1.55,
                              color: const Color(0xFF1C1917),
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      const SizedBox(height: 14),
                      const HeaderDivider(),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _PinnedHeaderDelegate(
                  minExtentHeight: 92,
                  maxExtentHeight: 92,
                  child: Container(
                    color: Color(0xFFFAECD2),
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'More Options',
                          style: AppTypography.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF4A1C00),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _SegmentedTabs(controller: _tabController, tabs: _tabs),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            body: Container(
              color: Color(0xFFFAECD2),
              child: TabBarView(
                controller: _tabController,
                children: [
                  Obx(() {
                    final pending =
                        _historyController.history['pending'] as List? ??
                        const [];
                    final finished =
                        _historyController.history['finished'] as List? ??
                        const [];
                    return _CalendarTab(
                      key: ValueKey('cal_${p.title}'),
                      pooja: p,
                      poojas: _deityPoojas,
                      festivalNames: _festivalNames,
                      favoriteDeityIds: _favoriteDeityIds,
                      onToggleFavoriteDeity: _toggleFavorite,
                      statusForPooja: (pooja) =>
                          _statusForPooja(pooja, pending, finished),
                      onSelectPooja: (pooja) {
                        final merged = _mergeDeityIntoPooja(
                          pooja,
                          _selectedDeity,
                        );
                        setState(() => _pooja = merged);
                        _showPujaPreviewModal(context, PoojaView(merged));
                      },
                    );
                  }),
                  _AboutDeityTab(key: ValueKey('abt_${p.deityName}'), pooja: p),
                  _StoriesTab(
                    key: ValueKey(
                      'story_${p.deityName}_${p.deityStories.length}',
                    ),
                    pooja: p,
                  ),
                ],
              ),
            ),
          ),
          // Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            child: Material(
              color: Color(0xFFFCF7EF),
              shape: const CircleBorder(),
              elevation: 2,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: Get.back,
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(
                    Icons.arrow_back,
                    size: 18,
                    color: Color(0xFF1F1F1F),
                  ),
                ),
              ),
            ),
          ),
          if (showGetStartedButton) const SizedBox.shrink(),
        ],
      ),
    );
  }

  String? _statusForPooja(
    Map<String, dynamic> pooja,
    List<dynamic> pendingSessions,
    List<dynamic> finishedSessions,
  ) {
    final pending = pendingSessions.whereType<Map>().any(
      (session) => _sessionMatchesPooja(session, pooja),
    );
    if (pending) return 'In Progress';

    final finished = finishedSessions.whereType<Map>().any(
      (session) => _sessionMatchesPooja(session, pooja),
    );
    if (finished) return 'Finished';

    return null;
  }

  bool _sessionMatchesPooja(Map session, Map<String, dynamic> pooja) {
    final sessionPooja = session['pooja'];
    if (sessionPooja is! Map) return false;

    // 1. Basic match: ID or Title must match
    bool basicMatch = false;
    final sessionPoojaId = _entityId(sessionPooja);
    final poojaId = _entityId(pooja);
    if (sessionPoojaId.isNotEmpty && poojaId.isNotEmpty) {
      basicMatch = sessionPoojaId == poojaId;
    } else {
      final sessionTitle = (sessionPooja['title'] ?? '')
          .toString()
          .trim()
          .toLowerCase();
      final title = (pooja['title'] ?? '').toString().trim().toLowerCase();
      basicMatch = sessionTitle.isNotEmpty && sessionTitle == title;
    }
    if (!basicMatch) return false;

    // 2. Schedule ID or Date matching
    final isDaily = pooja['daily'] == true || pooja['isDaily'] == true;
    final rawSchedules = pooja['schedules'];
    final hasSchedules = rawSchedules is List && rawSchedules.isNotEmpty;

    if (isDaily || hasSchedules) {
      // Try scheduleId match first (most accurate)
      final pScheduleId = pooja['scheduleId'] ?? pooja['selectedScheduleId'];
      final sScheduleId =
          session['scheduleId'] ??
          session['schedule'] ??
          session['pooja']?['scheduleId'];
      if (pScheduleId != null &&
          sScheduleId != null &&
          pScheduleId.toString().isNotEmpty &&
          sScheduleId.toString().isNotEmpty) {
        return pScheduleId.toString() == sScheduleId.toString();
      }

      // Fallback: Try date match
      final sId = (session['_id'] ?? session['id'] ?? '').toString();
      final localSavedDate = _historyController.sessionDates[sId];

      DateTime? sDate;
      if (localSavedDate != null) {
        sDate = DateTime.tryParse(localSavedDate);
      }
      sDate ??= _extractSessionDate(session);

      final pDate = _extractPoojaDate(pooja);
      if (sDate != null && pDate != null) {
        final localS = sDate.toLocal();
        final localP = pDate.toLocal();
        return localS.year == localP.year &&
            localS.month == localP.month &&
            localS.day == localP.day;
      }

      // If we are a scheduled or daily puja but could not match by ID or date, return false
      // to avoid highlighting every occurrence as completed.
      return false;
    }

    return true;
  }

  DateTime? _extractSessionDate(Map session) {
    final dateFields = [
      'poojaDate',
      'scheduledDate',
      'date',
      'scheduledAt',
      'finishedAt',
      'createdAt',
    ];
    for (final field in dateFields) {
      final raw = session[field] ?? session['pooja']?[field];
      if (raw != null) {
        try {
          return DateTime.parse(raw.toString());
        } catch (_) {}
      }
    }
    return null;
  }

  DateTime? _extractPoojaDate(Map<String, dynamic> pooja) {
    final customDate = pooja['customDate'];
    if (customDate != null) {
      try {
        return DateTime.parse(customDate.toString());
      } catch (_) {}
    }
    final d = pooja['date'] ?? pooja['scheduledDate'] ?? pooja['scheduledAt'];
    if (d != null) {
      try {
        return DateTime.parse(d.toString());
      } catch (_) {}
    }
    final schedules = pooja['schedules'];
    if (schedules is List && schedules.isNotEmpty && schedules.first is Map) {
      final s = (schedules.first as Map)['date'];
      if (s != null) {
        try {
          return DateTime.parse(s.toString());
        } catch (_) {}
      }
    }
    return null;
  }

  void _showPujaPreviewModal(BuildContext context, PoojaView pooja) {
    showPujaPreviewModal(context, pooja);
  }
}

// ════════════════════════════════════════════════════════════════
//  Hero Header  (saffron decorative top + circular deity portrait)
// ════════════════════════════════════════════════════════════════

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.pooja});
  final PoojaView pooja;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFFF4E0),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              SizedBox(
                width: double.infinity,
                height: 220,
                child: _ShapedHeaderBanner(networkUrl: pooja.heroImage),
              ),
              Positioned(
                bottom: -40,
                child: _DeityPortrait(imageUrl: pooja.heroImage),
              ),
            ],
          ),
          const SizedBox(height: 50),
          Text(
            pooja.deityName,
            style: AppTypography.lora(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF3B1E08),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

/// Draws the network hero image clipped to the shape (alpha) of appHeaderImg.png.
/// Falls back to the raw asset if the network image is missing or still loading.
class _ShapedHeaderBanner extends StatefulWidget {
  final String? networkUrl;
  const _ShapedHeaderBanner({this.networkUrl});

  @override
  State<_ShapedHeaderBanner> createState() => _ShapedHeaderBannerState();
}

class _ShapedHeaderBannerState extends State<_ShapedHeaderBanner> {
  ui.Image? _maskImage;

  @override
  void initState() {
    super.initState();
    _loadMask();
  }

  Future<void> _loadMask() async {
    final ByteData data = await rootBundle.load(
      'assets/images/appHeaderImg.png',
    );
    final ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
    );
    final ui.FrameInfo fi = await codec.getNextFrame();
    if (mounted) setState(() => _maskImage = fi.image);
  }

  @override
  Widget build(BuildContext context) {
    final hasNetwork =
        widget.networkUrl != null && widget.networkUrl!.isNotEmpty;

    // Until the mask asset is decoded OR when no network image → show the raw asset.
    if (_maskImage == null || !hasNetwork) {
      return Image.asset('assets/images/appHeaderImg.png', fit: BoxFit.fill);
    }

    return ShaderMask(
      blendMode: BlendMode.dstIn, // keep only the pixels where mask is opaque
      shaderCallback: (Rect bounds) {
        final double sx = bounds.width / _maskImage!.width;
        final double sy = bounds.height / _maskImage!.height;
        final matrix = Matrix4.identity().scaled(sx, sy, 1.0).storage;
        return ImageShader(_maskImage!, TileMode.clamp, TileMode.clamp, matrix);
      },
      child: CachedNetworkImage(
        imageUrl: widget.networkUrl!,
        fit: BoxFit.cover,
        alignment: const Alignment(0, -0.6),
        placeholder: (_, __) =>
            Image.asset('assets/images/appHeaderImg.png', fit: BoxFit.cover),
        errorWidget: (_, __, ___) =>
            Image.asset('assets/images/appHeaderImg.png', fit: BoxFit.cover),
      ),
    );
  }
}

class _DeityPortrait extends StatelessWidget {
  const _DeityPortrait({required this.imageUrl});
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.appBgColor,
        border: Border.all(color: Color(0xFFFCF7EF), width: 4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipOval(
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _fallback(),
                placeholder: (_, __) => _fallback(),
              )
            : _fallback(),
      ),
    );
  }

  Widget _fallback() {
    return Image.asset('assets/images/default_img.png', fit: BoxFit.cover);
  }
}

// ════════════════════════════════════════════════════════════════
//  Segmented Pill Tabs
// ════════════════════════════════════════════════════════════════
class _SegmentedTabs extends StatefulWidget {
  const _SegmentedTabs({required this.controller, required this.tabs});
  final TabController controller;
  final List<String> tabs;

  @override
  State<_SegmentedTabs> createState() => _SegmentedTabsState();
}

class _SegmentedTabsState extends State<_SegmentedTabs> {
  final _scrollController = ScrollController();
  final _keys = <GlobalKey>[];

  @override
  void initState() {
    super.initState();
    _keys.addAll(List.generate(widget.tabs.length, (_) => GlobalKey()));
    widget.controller.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTabChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (mounted && !widget.controller.indexIsChanging) {
      Future.delayed(const Duration(milliseconds: 50), () {
        if (_keys[widget.controller.index].currentContext != null) {
          Scrollable.ensureVisible(
            _keys[widget.controller.index].currentContext!,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: 0.5,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: AnimatedBuilder(
        animation: widget.controller,
        builder: (_, __) {
          return ListView.separated(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            itemCount: widget.tabs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final selected = widget.controller.index == i;
              return GestureDetector(
                key: _keys[i],
                onTap: () => widget.controller.animateTo(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: selected
                        ? const LinearGradient(
                            colors: [
                              AppColors.gradientStart,
                              AppColors.gradientEnd,
                            ],
                          )
                        : null,
                    color: selected ? null : Color(0xFFFCF7EF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? Colors.transparent
                          : const Color(0x33B07A3A),
                    ),
                    boxShadow: selected
                        ? const [
                            BoxShadow(
                              color: Color(0x33ED5A00),
                              blurRadius: 10,
                              offset: Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    widget.tabs[i],
                    style: AppTypography.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? Color(0xFFFCF7EF)
                          : const Color(0xFF3B1E08),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _PinnedHeaderDelegate extends SliverPersistentHeaderDelegate {
  _PinnedHeaderDelegate({
    required this.minExtentHeight,
    required this.maxExtentHeight,
    required this.child,
  });

  final double minExtentHeight;
  final double maxExtentHeight;
  final Widget child;

  @override
  double get minExtent => minExtentHeight;

  @override
  double get maxExtent => maxExtentHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _PinnedHeaderDelegate oldDelegate) {
    return minExtentHeight != oldDelegate.minExtentHeight ||
        maxExtentHeight != oldDelegate.maxExtentHeight ||
        child != oldDelegate.child;
  }
}

// ════════════════════════════════════════════════════════════════
//  Tab: About the Deity
// ════════════════════════════════════════════════════════════════
// ════════════════════════════════════════════════════════════════
//  Tab: About the Deity
// ════════════════════════════════════════════════════════════════
class _AboutDeityTab extends StatelessWidget {
  const _AboutDeityTab({super.key, required this.pooja});
  final PoojaView pooja;

  String _extractString(dynamic v) {
    if (v == null) return '';
    if (v is String) return v.trim();
    if (v is List) {
      return v
          .map((e) => _extractString(e))
          .where((s) => s.isNotEmpty)
          .join(', ');
    }
    if (v is Map) {
      // Try to get name or title from map
      final name = v['name'] ?? v['title'] ?? '';
      return _extractString(name);
    }
    return v.toString().trim();
  }

  List<String> _list(dynamic v) {
    if (v == null) return const [];
    if (v is List) {
      return v
          .map((e) => _extractString(e))
          .where((s) => s.isNotEmpty)
          .toList();
    }
    if (v is String && v.trim().isNotEmpty) {
      return v
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    final summary = pooja.deitySummary;
    final purpose = pooja.purpose;
    final deityDoc = pooja.deityDoc;

    // Field resolution — every label tries multiple possible API paths
    // so the same widget renders whether the server returns a sparse
    // deitySummary or a fully populated deity document.
    final altNames = _list(
      deityDoc?['alternate_names'] ??
          deityDoc?['otherNames'] ??
          deityDoc?['names'] ??
          deityDoc?['derivation'],
    );
    final roles = _list(deityDoc?['roles'] ?? deityDoc?['role']);
    final divineRole =
        _extractString(
          deityDoc?['divine_role'] ??
              deityDoc?['divineRole'] ??
              deityDoc?['description'] ??
              summary['about'],
        ).isEmpty
        ? _list(deityDoc?['roles']).join(', ')
        : _extractString(
            deityDoc?['divine_role'] ??
                deityDoc?['divineRole'] ??
                deityDoc?['description'] ??
                summary['about'],
          );

    final family = _extractString(
      deityDoc?['family'] ??
          deityDoc?['family_associations'] ??
          deityDoc?['lineage'],
    );
    final posture = _extractString(
      deityDoc?['posture'] ?? deityDoc?['seating'] ?? deityDoc?['iconography'],
    );
    final physicalItems = _meaningList(
      deityDoc?['physical_description'] ??
          deityDoc?['physicalDescription'] ??
          deityDoc?['appearance'],
    );
    final physical =
        _extractString(
          deityDoc?['physical_description'] ??
              deityDoc?['physicalDescription'] ??
              deityDoc?['appearance'],
        ).isEmpty
        ? _list(deityDoc?['appearance']).join(', ')
        : _extractString(
            deityDoc?['physical_description'] ??
                deityDoc?['physicalDescription'] ??
                deityDoc?['appearance'],
          );
    final whyPray = _extractString(
      deityDoc?['why_pray'] ?? deityDoc?['whyPray'],
    );
    final keyQualities = _list(
      deityDoc?['key_qualities'] ??
          deityDoc?['qualities'] ??
          deityDoc?['energies'] ??
          summary['blessings'],
    );
    final weapons = _meaningList(
      deityDoc?['weapons'] ?? deityDoc?['adornments'] ?? deityDoc?['symbols'],
    );
    final chakra = _extractString(deityDoc?['chakra'] ?? deityDoc?['chakras']);
    final astrology = _extractString(
      deityDoc?['vedic_astrology'] ??
          deityDoc?['astrology'] ??
          deityDoc?['numerology'],
    );
    final blessings = _list(summary['blessings'] ?? deityDoc?['blessings']);
    final deityNameDisplay = pooja.deityName.isNotEmpty
        ? pooja.deityName
        : pooja.title; // Always show *something*.

    final connecting = deityDoc?['connecting'] as Map?;
    final chanting = deityDoc?['chanting'] as Map?;
    final homePractice = deityDoc?['home_practice'] as Map?;
    final devotionalExp = deityDoc?['devotional_experience'] as Map?;
    final structure = deityDoc?['structure'] as List?;
    final spiritualSignificance = _meaningList(
      deityDoc?['spiritual_significance'],
    );

    // Check if sections have content
    final bool hasConnectingContent =
        connecting != null &&
        (_extractString(connecting['how_to_pray']).isNotEmpty ||
            _list(connecting['what_pleases']).isNotEmpty ||
            _list(connecting['displeases']).isNotEmpty ||
            _list(connecting['ideal_time']).isNotEmpty);

    final bool hasChantingContent =
        chanting != null &&
        (_extractString(chanting['mantra']).isNotEmpty ||
            _extractString(chanting['repetitions']).isNotEmpty ||
            _list(chanting['benefits']).isNotEmpty ||
            _list(chanting['preferred_days']).isNotEmpty ||
            _list(chanting['associated_colors']).isNotEmpty);

    final bool hasHomePracticeContent =
        homePractice != null &&
        ((homePractice['do_and_dont'] is Map &&
                (_list((homePractice['do_and_dont'] as Map)['do']).isNotEmpty ||
                    _list(
                      (homePractice['do_and_dont'] as Map)['dont'],
                    ).isNotEmpty)) ||
            _extractString(homePractice['placement']).isNotEmpty ||
            _list(homePractice['offerings']).isNotEmpty);

    final bool hasDevotionalExpContent =
        devotionalExp != null &&
        (_extractString(devotionalExp['sign_of_connection']).isNotEmpty ||
            _extractString(devotionalExp['notes']).isNotEmpty);

    // Debug prints
    debugPrint('AboutDeityTab: deityDoc keys: ${deityDoc?.keys.toList()}');
    debugPrint('AboutDeityTab: homePractice: $homePractice');
    debugPrint('AboutDeityTab: devotionalExp: $devotionalExp');
    debugPrint(
      'AboutDeityTab: hasHomePracticeContent: $hasHomePracticeContent',
    );
    debugPrint(
      'AboutDeityTab: hasDevotionalExpContent: $hasDevotionalExpContent',
    );
    debugPrint(
      'AboutDeityTab: spiritualSignificance length: ${spiritualSignificance.length}',
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 140),
      children: [
        const SectionHeader(title: 'Deity Information'),
        const SizedBox(height: 10),
        LabeledField(label: 'Deity Name', value: deityNameDisplay),
        if (altNames.isNotEmpty)
          LabeledChipsField(
            label: 'Derivation/ Other Names / Forms (if applicable)',
            items: altNames,
          ),
        if (roles.isNotEmpty) LabeledChipsField(label: 'Roles', items: roles),
        // if (divineRole.isNotEmpty)
        //   LabeledField(
        //     label: 'Divine Role (God/ Goddess of)',
        //     value: divineRole,
        //     multiline: true,
        //   ),

        // 5. Divine Structure (Modern or Legacy)
        if (structure != null && structure.isNotEmpty) ...[
          const SizedBox(height: 14),
          const SectionHeader(
            title: 'Family/ Divine association and Iconography',
          ),
          const SizedBox(height: 10),
          for (final s in structure.whereType<Map>())
            DeitySectionCard(section: s.cast<String, dynamic>()),
          // Render physical items / appearance even if we have structure
          if (physicalItems.isNotEmpty) ...[
            const SizedBox(height: 14),
            const SectionHeader(title: 'Appearance & Symbolism'),
            const SizedBox(height: 10),
            _LabeledTitleDescriptionList(
              label: 'Physical Description',
              items: physicalItems,
            ),
          ],
          // Render symbols & weapons even if we have structure
          if (weapons.isNotEmpty) ...[
            const SizedBox(height: 4),
            const SectionHeader(title: 'Symbols & Weapons'),
            const SizedBox(height: 10),
            for (final w in weapons)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: LabeledField(
                  label: w.title,
                  value: w.description,
                  multiline: true,
                ),
              ),
          ],
        ] else if (family.isNotEmpty ||
            posture.isNotEmpty ||
            physicalItems.isNotEmpty ||
            weapons.isNotEmpty) ...[
          // Legacy/Fallback Structure
          if (family.isNotEmpty) ...[
            const SizedBox(height: 4),
            const SectionHeader(
              title: 'Family/ Divine association and Iconography',
            ),
            const SizedBox(height: 10),
            LabeledField(
              label: 'Family / Divine Associations',
              value: family,
              multiline: true,
            ),
          ],
          if (posture.isNotEmpty)
            LabeledField(
              label: 'Seating / Posture (Iconography)',
              value: posture,
              multiline: true,
            ),
          if (physicalItems.isNotEmpty) ...[
            const SizedBox(height: 14),
            const SectionHeader(title: 'Appearance & Symbolism'),
            const SizedBox(height: 10),
            _LabeledTitleDescriptionList(
              label: 'Physical Description',
              items: physicalItems,
            ),
          ],
          if (weapons.isNotEmpty) ...[
            const SizedBox(height: 4),
            const SectionHeader(title: 'Symbols & Weapons'),
            const SizedBox(height: 10),
            for (final w in weapons)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: LabeledField(
                  label: w.title,
                  value: w.description,
                  multiline: true,
                ),
              ),
          ],
        ],

        // Spiritual Significance
        if (spiritualSignificance.isNotEmpty) ...[
          const SizedBox(height: 14),
          const SectionHeader(title: 'Spiritual Significance'),
          const SizedBox(height: 10),
          for (final item in spiritualSignificance)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: LabeledField(
                label: item.title,
                value: item.description,
                multiline: true,
              ),
            ),
        ],

        // 1. Connecting with the Divine
        if (hasConnectingContent) ...[
          const SizedBox(height: 14),
          const SectionHeader(title: 'Connecting with the Divine'),
          const SizedBox(height: 10),
          if (_extractString(connecting!['how_to_pray']).isNotEmpty)
            LabeledField(
              label: 'How to Pray / Connect',
              value: _extractString(connecting['how_to_pray']),
              multiline: true,
            ),
          if (_list(connecting['what_pleases']).isNotEmpty)
            LabeledChipsField(
              label: 'What Pleases the Deity',
              items: _list(connecting['what_pleases']),
              positive: true,
            ),
          if (_list(connecting['displeases']).isNotEmpty)
            LabeledChipsField(
              label: 'What Displeases the Deity',
              items: _list(connecting['displeases']),
              positive: false,
            ),
          if (_list(connecting['ideal_time']).isNotEmpty)
            LabeledChipsField(
              label: 'Ideal Time for Connection',
              items: _list(connecting['ideal_time']),
            ),
        ],

        // 2. Mantras & Chanting
        if (hasChantingContent) ...[
          const SizedBox(height: 14),
          const SectionHeader(title: 'Mantras & Chanting'),
          const SizedBox(height: 10),
          if (_extractString(chanting!['mantra']).isNotEmpty)
            LabeledField(
              label: 'Main Mantra',
              value: _extractString(chanting['mantra']),
              multiline: true,
            ),
          if (_extractString(chanting['repetitions']).isNotEmpty)
            LabeledField(
              label: 'Repetitions',
              value: _extractString(chanting['repetitions']),
            ),
          if (_list(chanting['benefits']).isNotEmpty)
            LabeledChipsField(
              label: 'Benefits of Chanting',
              items: _list(chanting['benefits']),
              positive: true,
            ),
          if (_list(chanting['preferred_days']).isNotEmpty)
            LabeledChipsField(
              label: 'Preferred Days',
              items: _list(chanting['preferred_days']),
            ),
          if (_list(chanting['associated_colors']).isNotEmpty)
            LabeledChipsField(
              label: 'Associated Colors',
              items: _list(chanting['associated_colors']),
            ),
        ],

        // 3. Home Practice
        if (hasHomePracticeContent) ...[
          const SizedBox(height: 14),
          const SectionHeader(title: 'Home Practice'),
          const SizedBox(height: 10),
          if (homePractice!['do_and_dont'] is Map) ...[
            if (_list((homePractice['do_and_dont'] as Map)['do']).isNotEmpty)
              LabeledChipsField(
                label: 'Do\'s',
                items: _list((homePractice['do_and_dont'] as Map)['do']),
                positive: true,
              ),
            if (_list((homePractice['do_and_dont'] as Map)['dont']).isNotEmpty)
              LabeledChipsField(
                label: 'Don\'ts',
                items: _list((homePractice['do_and_dont'] as Map)['dont']),
                positive: false,
              ),
          ],
          if (_extractString(homePractice['placement']).isNotEmpty)
            LabeledField(
              label: 'Idol / Murthi placement in the home',
              value: _extractString(homePractice['placement']),
              multiline: true,
            ),
          if (_list(homePractice['offerings']).isNotEmpty)
            LabeledChipsField(
              label: 'Offerings',
              items: _list(homePractice['offerings']),
              positive: true,
            ),
        ],

        // 4. Devotional Experience
        if (hasDevotionalExpContent) ...[
          const SizedBox(height: 14),
          const SectionHeader(title: 'Devotional Experience'),
          const SizedBox(height: 10),
          if (_extractString(devotionalExp!['sign_of_connection']).isNotEmpty)
            LabeledField(
              label: 'Signs of Connection',
              value: _extractString(devotionalExp['sign_of_connection']),
              multiline: true,
            ),
          if (_extractString(devotionalExp['notes']).isNotEmpty)
            LabeledField(
              label: 'Special Notes',
              value: _extractString(devotionalExp['notes']),
              multiline: true,
            ),
        ],

        if (divineRole.isNotEmpty ||
            whyPray.isNotEmpty ||
            keyQualities.isNotEmpty ||
            chakra.isNotEmpty ||
            astrology.isNotEmpty) ...[
          const SizedBox(height: 4),
          // const SectionHeader(title: 'Purpose of the Ritual'),
          const SizedBox(height: 10),
          if (whyPray.isNotEmpty)
            LabeledField(
              label: 'Why Pray to This Deity',
              value: whyPray,
              multiline: true,
            ),
          if (keyQualities.isNotEmpty)
            LabeledChipsField(
              label: 'Key Qualities / Energies Represented',
              items: keyQualities,
              positive: true,
            ),
          if (chakra.isNotEmpty)
            LabeledField(
              label: 'Associated Chakras',
              value: chakra,
              multiline: true,
            ),
          if (astrology.isNotEmpty)
            LabeledField(
              label: 'Astrological Connection',
              value: astrology,
              multiline: true,
            ),
          if (blessings.isNotEmpty)
            LabeledChipsField(
              label: 'Blessings',
              items: blessings,
              positive: true,
            ),
        ],
        // Render any structured \"sections\" array provided by the deity doc.
        if (deityDoc != null && deityDoc['sections'] is List) ...[
          for (final s in (deityDoc['sections'] as List).whereType<Map>())
            DeitySectionCard(section: s.cast<String, dynamic>()),
        ],
      ],
    );
  }

  List<MeaningItem> _meaningList(dynamic raw) {
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((m) {
      return MeaningItem(
        title: _extractString(m['title'] ?? m['name'] ?? ''),
        description: _extractString(
          m['description'] ?? m['meaning'] ?? m['symbolism'] ?? '',
        ),
      );
    }).toList();
  }
}

class _LabeledTitleDescriptionList extends StatelessWidget {
  const _LabeledTitleDescriptionList({
    required this.label,
    required this.items,
  });

  final String label;
  final List<MeaningItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Color(0xFFFCF7EF),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF8A6B4A),
            ),
          ),
          const SizedBox(height: 8),
          for (int i = 0; i < items.length; i++) ...[
            if (items[i].title.isNotEmpty)
              RichTextDisplay(
                items[i].title,
                style: AppTypography.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF3B1E08),
                ),
              ),
            if (items[i].description.isNotEmpty) ...[
              if (items[i].title.isNotEmpty) const SizedBox(height: 4),
              RichTextDisplay(
                items[i].description,
                style: AppTypography.inter(
                  fontSize: 13.5,
                  height: 1.5,
                  color: const Color(0xFF3B1E08),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            if (i != items.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  Tab: Rituals & Remedies
// ════════════════════════════════════════════════════════════════
class _RitualsTab extends StatelessWidget {
  const _RitualsTab({super.key, required this.pooja, this.rituals = const []});
  final PoojaView pooja;
  final List<Map<String, dynamic>> rituals;

  @override
  Widget build(BuildContext context) {
    if (rituals.isEmpty) {
      return const _EmptyView(
        icon: Icons.event_note_outlined,
        message: 'No rituals posted',
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 140),
      children: [
        Text(
          'Deity Information',
          style: AppTypography.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF4A1C00),
          ),
        ),
        const SizedBox(height: 12),
        for (final rit in rituals) ...[
          _RitualCard(ritual: rit),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  static List<String> _stringList(dynamic raw) {
    if (raw is List) {
      return raw
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList();
    }
    if (raw is String && raw.trim().isNotEmpty) {
      return raw
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const [];
  }

  static List<MeaningItem> _meaningList(dynamic raw) {
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((m) {
      return MeaningItem(
        title: (m['title'] ?? '').toString(),
        description: (m['description'] ?? '').toString(),
      );
    }).toList();
  }
}

// ════════════════════════════════════════════════════════════════
//  Tab: Stories of Deity
// ════════════════════════════════════════════════════════════════
class _StoriesTab extends StatelessWidget {
  const _StoriesTab({super.key, required this.pooja});
  final PoojaView pooja;

  @override
  Widget build(BuildContext context) {
    final deityDoc = pooja.deityDoc;
    final stories = pooja.deityStories;
    final sections = pooja.deitySections;

    debugPrint('StoriesTab build: Found ${stories.length} stories in array');

    final storySections = sections.where((m) {
      final key = (m['key'] ?? '').toString().toLowerCase();
      final title = (m['title'] is Map)
          ? (m['title']['value'] ?? '').toString().toLowerCase()
          : (m['title'] ?? '').toString().toLowerCase();

      final keywords = [
        'story',
        'legend',
        'lineage',
        'origin',
        'history',
        'narrative',
        'background',
        'creation',
        'structure',
      ];

      return keywords.any((k) => key.contains(k) || title.contains(k));
    }).toList();

    // Primary narrative from the deity object itself
    final deityNarrative = (deityDoc?['story'] ?? '').toString();

    // If we have actual deity stories or sections, we DON'T want to show the
    // generic pooja summary "old story" at the top.
    final hasRealDeityContent = stories.isNotEmpty || storySections.isNotEmpty;

    // The fallback is only used if we have absolutely no other narrative.
    final fallbackSummary = (!hasRealDeityContent && deityNarrative.isEmpty)
        ? pooja.deitySummary['about']?.toString() ?? ''
        : '';

    if (stories.isEmpty &&
        storySections.isEmpty &&
        deityNarrative.isEmpty &&
        fallbackSummary.isEmpty) {
      return _EmptyView(
        icon: Icons.menu_book_outlined,
        message: 'No stories available for this deity yet.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 140),
      children: [
        // 1. Render actual stories from the 'stories' array (this is the long story you provided)
        for (final s in stories) ...[
          StoryCard(
            title: (s['title'] ?? s['name'] ?? '').toString(),
            description: (s['description'] ?? s['content'] ?? s['text'] ?? '')
                .toString(),
          ),
          const SizedBox(height: 16),
        ],

        // 2. If no 'stories' array, fallback to deity description/narrative
        if (stories.isEmpty && deityNarrative.isNotEmpty) ...[
          QuoteCard(text: deityNarrative),
          if (storySections.isNotEmpty) const SizedBox(height: 16),
        ],

        // 3. Last resort fallback (Pooja summary)
        if (stories.isEmpty &&
            deityNarrative.isEmpty &&
            fallbackSummary.isNotEmpty) ...[
          QuoteCard(text: fallbackSummary),
        ],

        // 4. Render other story-related sections (lineage, origin, etc.)
        // for (final s in storySections) ...[
        //   DeitySectionCard(section: s),
        //   const SizedBox(height: 12),
        // ],
      ],
    );
  }
}

class _StoryCard extends StatelessWidget {
  const _StoryCard({required this.title, required this.description});
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    if (description.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFFFCF7EF),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            Text(
              title,
              style: AppTypography.lora(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF3B1E08),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 2,
              width: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFE69138).withOpacity(0.3),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            const SizedBox(height: 16),
          ],
          RichTextDisplay(
            description,
            style: AppTypography.inter(
              fontSize: 14,
              height: 1.6,
              color: const Color(0xFF4A1C00),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  Tab: Calender Puja's
// ════════════════════════════════════════════════════════════════
class _CalendarTab extends StatelessWidget {
  const _CalendarTab({
    super.key,
    required this.pooja,
    required this.poojas,
    required this.festivalNames,
    required this.statusForPooja,
    required this.onSelectPooja,
    required this.favoriteDeityIds,
    required this.onToggleFavoriteDeity,
  });

  final PoojaView pooja;
  final List<Map<String, dynamic>> poojas;
  final Map<String, String> festivalNames;
  final String? Function(Map<String, dynamic> pooja) statusForPooja;
  final ValueChanged<Map<String, dynamic>> onSelectPooja;
  final Set<String> favoriteDeityIds;
  final ValueChanged<String> onToggleFavoriteDeity;

  @override
  Widget build(BuildContext context) {
    final activePoojaId = (pooja.raw['_id'] ?? pooja.raw['id'] ?? '')
        .toString()
        .trim();
    final rawList = poojas.isNotEmpty
        ? poojas
        : activePoojaId.isNotEmpty
        ? [pooja.raw]
        : const <Map<String, dynamic>>[];

    final List<Map<String, dynamic>> calendarPoojas = [];
    for (final raw in rawList) {
      final isDaily = raw['daily'] == true || raw['isDaily'] == true;
      if (isDaily) {
        final copy = Map<String, dynamic>.from(raw);
        final todayStr = DateTime.now().toIso8601String().split('T').first;
        copy['customDate'] = todayStr;
        calendarPoojas.add(copy);
      } else {
        final schedules = raw['schedules'];
        if (schedules is List && schedules.isNotEmpty) {
          for (final s in schedules) {
            if (s is Map) {
              final dateVal = s['date']?.toString() ?? '';
              final timeVal = s['time']?.toString() ?? '';
              if (dateVal.isNotEmpty) {
                String combined = dateVal;
                try {
                  final dateOnly = dateVal.split('T').first.trim();
                  if (timeVal.isNotEmpty) {
                    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dateOnly)) {
                      combined = '${dateOnly}T$timeVal:00';
                    } else if (RegExp(
                      r'^\d{2}-\d{2}-\d{4}$',
                    ).hasMatch(dateOnly)) {
                      final parts = dateOnly.split('-');
                      combined =
                          '${parts[2]}-${parts[1]}-${parts[0]}T$timeVal:00';
                    } else {
                      final parsedDate = DateTime.tryParse(dateVal);
                      if (parsedDate != null) {
                        final parts = timeVal.split(':');
                        final hour = int.tryParse(parts.first) ?? 0;
                        final minute = parts.length > 1
                            ? (int.tryParse(parts[1]) ?? 0)
                            : 0;
                        final combinedDt = DateTime(
                          parsedDate.year,
                          parsedDate.month,
                          parsedDate.day,
                          hour,
                          minute,
                        );
                        combined = combinedDt.toIso8601String();
                      }
                    }
                  }
                } catch (_) {}
                final copy = Map<String, dynamic>.from(raw);
                copy['customDate'] = combined;
                copy['scheduleId'] = (s['_id'] ?? s['id'])?.toString();
                calendarPoojas.add(copy);
              }
            }
          }
        } else {
          calendarPoojas.add(raw);
        }
      }
    }

    if (calendarPoojas.isEmpty) {
      return _EmptyView(
        icon: Icons.calendar_month_outlined,
        message: 'No calendar pujas available for this deity yet.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(5, 16, 5, 20),
      children: [
        for (final raw in calendarPoojas) ...[
          Builder(
            builder: (context) {
              final pView = PoojaView(raw);
              final dDoc = pView.deityDoc;
              final dId = dDoc != null
                  ? (dDoc['_id'] ?? dDoc['id'] ?? '').toString()
                  : '';

              return _CalendarPujaCard(
                pooja: pView,
                festivals: pView.festivalIds
                    .map((id) => festivalNames[id] ?? id)
                    .where((name) => name.trim().isNotEmpty)
                    .toList(),
                selected: _samePooja(raw, pooja.raw),
                statusLabel: statusForPooja(raw),
                onTap: () => onSelectPooja(raw),
                isFavorite: dId.isNotEmpty && favoriteDeityIds.contains(dId),
                onFavoriteTap: dId.isNotEmpty
                    ? () => onToggleFavoriteDeity(dId)
                    : null,
              );
            },
          ),
          if (raw != calendarPoojas.last) const SizedBox(height: 18),
        ],
      ],
    );
  }

  static bool _samePooja(Map<String, dynamic> a, Map<String, dynamic> b) {
    final aId = (a['_id'] ?? a['id'] ?? '').toString();
    final bId = (b['_id'] ?? b['id'] ?? '').toString();
    if (aId.isNotEmpty && bId.isNotEmpty) {
      if (aId != bId) return false;

      // Try scheduleId match first
      final aSchedId = a['scheduleId'] ?? a['selectedScheduleId'];
      final bSchedId = b['scheduleId'] ?? b['selectedScheduleId'];
      if (aSchedId != null &&
          bSchedId != null &&
          aSchedId.toString().isNotEmpty &&
          bSchedId.toString().isNotEmpty) {
        return aSchedId.toString() == bSchedId.toString();
      }

      final aDate = a['customDate'] ?? a['date'] ?? a['scheduledDate'];
      final bDate = b['customDate'] ?? b['date'] ?? b['scheduledDate'];
      return aDate == bDate;
    }
    return identical(a, b);
  }
}

class _CalendarPujaCard extends StatelessWidget {
  const _CalendarPujaCard({
    required this.pooja,
    required this.festivals,
    required this.selected,
    this.statusLabel,
    required this.onTap,
    this.isFavorite = false,
    this.onFavoriteTap,
  });

  final PoojaView pooja;
  final List<String> festivals;
  final bool selected;
  final String? statusLabel;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback? onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    final title = pooja.title.isNotEmpty ? pooja.title : pooja.deityName;
    final subtitle = pooja.deityName.isNotEmpty
        ? pooja.deityName
        : pooja.category;
    final duration = pooja.duration.isNotEmpty ? pooja.duration : '45 min';
    final date = pooja.daily
        ? pooja.dailyTimeText
        : _formatCalendarDate(pooja.date);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF7E8) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFFE69138) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CalendarThumb(
                  imageUrl: pooja.poojaImage,
                  isFavorite: isFavorite,
                  onFavoriteTap: onFavoriteTap,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.lora(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1C1917),
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        if (subtitle.isNotEmpty)
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.inter(
                              fontSize: 11,
                              color: const Color(0xFF78716C),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        if (statusLabel != null) ...[
                          const SizedBox(height: 8),
                          PujaSessionStatusBadge(label: statusLabel!),
                        ],
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            if (date != null) ...[
                              const Icon(
                                Icons.calendar_month_outlined,
                                size: 15,
                                color: Color(0xFF1C1917),
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  date,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF1C1917),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                            ],
                            const Icon(
                              Icons.access_time,
                              size: 15,
                              color: Color(0xFF1C1917),
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                duration,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF1C1917),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String? _formatCalendarDate(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;

    DateTime? parsed = DateTime.tryParse(value);
    parsed ??= _parseDayMonthYear(value);
    if (parsed == null) {
      final beforeTime = value.split(RegExp(r'\s+')).first.trim();
      return beforeTime.isEmpty ? null : beforeTime;
    }

    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final day = parsed.day.toString().padLeft(2, '0');
    final monthStr = months[parsed.month - 1];
    if (parsed.hour != 0 || parsed.minute != 0) {
      final hour = parsed.hour.toString().padLeft(2, '0');
      final minute = parsed.minute.toString().padLeft(2, '0');
      return '$day $monthStr ${parsed.year} at $hour:$minute';
    }
    return '$day $monthStr ${parsed.year}';
  }

  static DateTime? _parseDayMonthYear(String value) {
    final match = RegExp(r'^(\d{1,2})-(\d{1,2})-(\d{4})$').firstMatch(value);
    if (match == null) return null;
    final day = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    final year = int.tryParse(match.group(3)!);
    if (day == null || month == null || year == null) return null;
    try {
      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }
}

class _CalendarThumb extends StatelessWidget {
  const _CalendarThumb({
    required this.imageUrl,
    this.isFavorite = false,
    this.onFavoriteTap,
  });
  final String? imageUrl;
  final bool isFavorite;
  final VoidCallback? onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 78,
      height: 78,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imageUrl != null && imageUrl!.isNotEmpty
                  ? Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _fallback(),
                    )
                  : _fallback(),
            ),
          ),
          Positioned(
            right: -10,
            bottom: -6,
            child: GestureDetector(
              onTap: onFavoriteTap,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Color(0xFFFCF7EF),
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFEAD9BC), width: 1),
                ),
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF183EA4), Color(0xFFE35600)],
                  ).createShader(bounds),
                  child: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    size: 20,
                    color: Color(0xFFFCF7EF),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallback() {
    return Image.asset('assets/images/default_img.png', fit: BoxFit.cover);
  }
}

// ════════════════════════════════════════════════════════════════
//  Reusable building blocks
// ════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, top: 4),
      child: Text(
        title,
        style: AppTypography.inter(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF3B1E08),
        ),
      ),
    );
  }
}

class _MantraCard extends StatefulWidget {
  const _MantraCard({required this.mantra, this.audioUrl});
  final MantraView mantra;
  final String? audioUrl;

  @override
  State<_MantraCard> createState() => _MantraCardState();
}

class _MantraCardState extends State<_MantraCard> {
  VideoPlayerController? _audio;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    final url = widget.audioUrl;
    if (url != null && url.isNotEmpty) {
      _audio = VideoPlayerController.networkUrl(Uri.parse(url))
        ..initialize()
            .then((_) {
              if (!mounted) return;
              setState(() => _ready = true);
            })
            .catchError((_) {})
        ..addListener(_onAudioTick);
    }
  }

  void _onAudioTick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _audio?.removeListener(_onAudioTick);
    _audio?.dispose();
    super.dispose();
  }

  void _toggle() {
    final c = _audio;
    if (c == null || !_ready) return;
    if (c.value.isPlaying) {
      c.pause();
    } else {
      if (c.value.position >= c.value.duration) {
        c.seekTo(Duration.zero);
      }
      c.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = _audio?.value.isPlaying ?? false;
    final hasAudio = _audio != null;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        color: Color(0xFFFCF7EF),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.mantra.primary,
                      style: AppTypography.lora(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF3B1E08),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.repeat,
                          size: 12,
                          color: Color(0xFFB07A3A),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.mantra.repetitions.isEmpty
                              ? 'Sacred Mantra'
                              : widget.mantra.repetitions,
                          style: AppTypography.inter(
                            fontSize: 12,
                            color: const Color(0xFFB07A3A),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: hasAudio ? _toggle : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppColors.gradientStart, AppColors.gradientEnd],
                    ),
                    boxShadow: hasAudio
                        ? const [
                            BoxShadow(
                              color: Color(0x33ED5A00),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    !hasAudio
                        ? Icons.volume_off
                        : (isPlaying ? Icons.pause : Icons.play_arrow),
                    color: Color(0xFFFCF7EF),
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
          if (hasAudio && _ready) ...[
            const SizedBox(height: 12),
            _AudioProgressBar(controller: _audio!),
          ],
          if (widget.mantra.meaning.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              widget.mantra.meaning,
              style: AppTypography.inter(
                fontSize: 12.5,
                height: 1.45,
                color: const Color(0xFF6A4423),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (widget.mantra.additional.isNotEmpty) ...[
            const SizedBox(height: 10),
            _ChipWrap(items: widget.mantra.additional, positive: true),
          ],
        ],
      ),
    );
  }
}

class _AudioProgressBar extends StatelessWidget {
  const _AudioProgressBar({required this.controller});
  final VideoPlayerController controller;

  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inMinutes)}:${two(d.inSeconds.remainder(60))}';
  }

  @override
  Widget build(BuildContext context) {
    final v = controller.value;
    final total = v.duration.inMilliseconds == 0
        ? 1
        : v.duration.inMilliseconds;
    final progress = (v.position.inMilliseconds / total).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor: const Color(0x22B07A3A),
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppColors.gradientEnd,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _fmt(v.position),
              style: AppTypography.inter(
                fontSize: 10.5,
                color: const Color(0xFF8A6B4A),
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              _fmt(v.duration),
              style: AppTypography.inter(
                fontSize: 10.5,
                color: const Color(0xFF8A6B4A),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });
  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Color(0xFFFCF7EF),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.gradientStart, AppColors.gradientEnd],
                  ),
                ),
                child: Icon(icon, size: 16, color: Color(0xFFFCF7EF)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.lora(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF3B1E08),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _Paragraph extends StatelessWidget {
  const _Paragraph({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: AppTypography.inter(
          fontSize: 13.5,
          height: 1.5,
          color: const Color(0xFF4A1C00),
        ),
      ),
    );
  }
}

class _BulletList extends StatelessWidget {
  const _BulletList({
    required this.heading,
    required this.items,
    this.asChips = false,
    this.positive = true,
  });
  final String heading;
  final List<String> items;
  final bool asChips;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading,
            style: AppTypography.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF7A4621),
            ),
          ),
          const SizedBox(height: 8),
          if (asChips)
            _ChipWrap(items: items, positive: positive)
          else
            ...items.map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 7, right: 10),
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Color(0xFFB07A3A),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        t,
                        style: AppTypography.inter(
                          fontSize: 13.5,
                          height: 1.5,
                          color: const Color(0xFF4A1C00),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChipWrap extends StatelessWidget {
  const _ChipWrap({required this.items, required this.positive});
  final List<String> items;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final bg = positive ? const Color(0xFFFFF1DD) : const Color(0xFFFFE3DC);
    final fg = positive ? const Color(0xFF7A4621) : const Color(0xFF8E2A12);
    final border = positive ? const Color(0x44B07A3A) : const Color(0x44B0432A);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .map(
            (t) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: border),
              ),
              child: Text(
                t,
                style: AppTypography.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({required this.step});
  final StepView step;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(right: 12, top: 2),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.gradientStart, AppColors.gradientEnd],
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              '${step.number}',
              style: AppTypography.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFFFCF7EF),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: AppTypography.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF3B1E08),
                  ),
                ),
                if (step.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  StepRichTextDisplay.detail(step.description),
                ],
                if (step.subSteps.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...step.subSteps.map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(bottom: 4, left: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 5, right: 8),
                            child: Icon(
                              Icons.check_circle,
                              size: 12,
                              color: Color(0xFFB07A3A),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              s,
                              style: AppTypography.inter(
                                fontSize: 12.5,
                                height: 1.45,
                                color: const Color(0xFF6A4423),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MeaningGroup extends StatelessWidget {
  const _MeaningGroup({required this.heading, required this.items});
  final String heading;
  final List<MeaningItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading,
            style: AppTypography.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF7A4621),
            ),
          ),
          const SizedBox(height: 8),
          ...items.map(
            (m) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8EC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x22B07A3A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m.title,
                    style: AppTypography.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF3B1E08),
                    ),
                  ),
                  const SizedBox(height: 4),
                  RichTextDisplay(
                    m.description,
                    style: AppTypography.inter(
                      fontSize: 12.5,
                      height: 1.45,
                      color: const Color(0xFF4A1C00),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.icon, required this.message});
  final IconData icon;
  final String message;
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 42, color: const Color(0xFF8A6B4A)),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTypography.inter(
                  fontSize: 13.5,
                  color: const Color(0xFF7A5A3D),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RitualCard extends StatelessWidget {
  const _RitualCard({required this.ritual});
  final Map<String, dynamic> ritual;

  static String _cleanUrl(String url) {
    return url.replaceAll('`', '').trim();
  }

  static List<dynamic> _ritualDays(Map<String, dynamic> ritual) {
    final raw = ritual['days'];
    if (raw is List) return raw;
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final parsed = jsonDecode(raw);
        if (parsed is List) return parsed;
      } catch (_) {}
    }
    return const [];
  }

  static List<dynamic> _ritualSections(Map<String, dynamic> ritual) {
    final raw = ritual['sections'];
    if (raw is List) return raw;
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final parsed = jsonDecode(raw);
        if (parsed is List) return parsed;
      } catch (_) {}
    }
    return const [];
  }

  static String _sectionDescription(Map<dynamic, dynamic> sec) {
    final direct = (sec['description'] ?? sec['content'] ?? '')
        .toString()
        .trim();
    if (direct.isNotEmpty) return direct;

    final contents = sec['contents'];
    if (contents is! List) return '';

    final parts = <String>[];
    for (final raw in contents) {
      if (raw is! Map) continue;
      final title = (raw['title'] ?? '').toString().trim();
      final desc = (raw['description'] ?? raw['content'] ?? '')
          .toString()
          .trim();
      if (title.isNotEmpty && desc.isNotEmpty) {
        parts.add('$title\n$desc');
      } else if (title.isNotEmpty) {
        parts.add(title);
      } else if (desc.isNotEmpty) {
        parts.add(desc);
      }
    }
    return parts.join('\n\n');
  }

  @override
  Widget build(BuildContext context) {
    final title = (ritual['title'] ?? '').toString();
    final description = (ritual['description'] ?? '').toString();

    // Get image from images array first, then imageUrl/image
    String imageUrl = '';
    final images = ritual['images'];
    if (images is List && images.isNotEmpty) {
      imageUrl = _cleanUrl(images.first.toString());
    } else {
      imageUrl = _cleanUrl(
        (ritual['imageUrl'] ?? ritual['image'] ?? '').toString(),
      );
    }

    final days = _ritualDays(ritual);
    final sections = _ritualSections(ritual);

    final List<String> tags = [];
    if (ritual['difficulty'] != null) tags.add(ritual['difficulty'].toString());
    if (ritual['accessType'] != null) tags.add(ritual['accessType'].toString());
    if (ritual['ritualDays'] != null) {
      tags.add('${ritual['ritualDays']} Days');
    }

    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFFCF7EF),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Image.network(
                imageUrl,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 180,
                  color: const Color(0xFFFAECD2),
                  child: const Icon(
                    Icons.image_outlined,
                    color: Color(0xFFB07A3A),
                  ),
                ),
              ),
            )
          else
            Container(
              height: 180,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFFAECD2),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Image.asset(
                'assets/images/default_img.png',
                fit: BoxFit.cover,
                height: 160,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF3B1E08),
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  RichTextDisplay(
                    description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.inter(
                      fontSize: 13,
                      height: 1.5,
                      color: const Color(0xFF4A1C00),
                    ),
                  ),
                ],
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: tags.map((tag) => _TagChip(label: tag)).toList(),
                  ),
                ],
                if (sections.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Text(
                    'Remedies & Additional Info',
                    style: AppTypography.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF7A4621),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...sections.map((sec) {
                    if (sec is! Map) return const SizedBox.shrink();
                    final secMap = Map<dynamic, dynamic>.from(sec);
                    final label = (secMap['label'] ?? secMap['title'] ?? '')
                        .toString()
                        .trim();
                    final sectionDescription = _sectionDescription(secMap);

                    if (label.isEmpty && sectionDescription.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDF7F0),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF3E5D0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (label.isNotEmpty)
                            Text(
                              label,
                              style: AppTypography.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF3B1E08),
                              ),
                            ),
                          if (label.isNotEmpty && sectionDescription.isNotEmpty)
                            const SizedBox(height: 8),
                          if (sectionDescription.isNotEmpty)
                            RichTextDisplay(
                              sectionDescription,
                              style: AppTypography.inter(
                                fontSize: 12.5,
                                height: 1.45,
                                color: const Color(0xFF4A1C00),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                ],
                if (days.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Text(
                    'Ritual Plan',
                    style: AppTypography.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF7A4621),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...days.map((day) => _DayItem(day: day)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DayItem extends StatefulWidget {
  const _DayItem({required this.day});
  final Map<dynamic, dynamic> day;

  @override
  State<_DayItem> createState() => _DayItemState();
}

class _DayItemState extends State<_DayItem> {
  bool _isExpanded = false;

  static String _cleanUrl(String url) {
    return url.replaceAll('`', '').trim();
  }

  static List<String> _dayImages(Map<dynamic, dynamic> day) {
    final urls = <String>[];

    void addRaw(dynamic raw) {
      if (raw is List) {
        for (final item in raw) {
          final cleaned = _cleanUrl(item.toString());
          if (cleaned.isNotEmpty) urls.add(cleaned);
        }
      } else if (raw != null) {
        final cleaned = _cleanUrl(raw.toString());
        if (cleaned.isNotEmpty) urls.add(cleaned);
      }
    }

    addRaw(day['images']);
    addRaw(day['imageUrls']);
    addRaw(day['imageUrl'] ?? day['image']);

    return urls;
  }

  Widget _buildDayHeroImages(List<String> images) {
    Widget buildImage(String url) {
      return CachedNetworkImage(
        imageUrl: url,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          width: double.infinity,
          color: const Color(0xFFFAECD2),
          alignment: Alignment.center,
          child: const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (_, __, ___) => Container(
          width: double.infinity,
          color: const Color(0xFFFAECD2),
          alignment: Alignment.center,
          child: const Icon(
            Icons.broken_image_outlined,
            color: Color(0xFFB07A3A),
            size: 28,
          ),
        ),
      );
    }

    if (images.length == 1) {
      return AspectRatio(aspectRatio: 16 / 9, child: buildImage(images.first));
    }

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: PageView.builder(
        itemCount: images.length,
        itemBuilder: (_, index) => buildImage(images[index]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final day = widget.day;
    final dayNumber = day['stepNumber'] ?? day['dayNumber'] ?? 0;
    final title = (day['title'] ?? '').toString();
    final description = (day['description'] ?? '').toString();
    final subSteps = <String>[];
    final rawSubSteps = day['subSteps'];
    if (rawSubSteps is List) {
      subSteps.addAll(
        rawSubSteps.map((e) => e.toString().trim()).where((e) => e.isNotEmpty),
      );
    }
    if (subSteps.isEmpty && day['activities'] is List) {
      subSteps.addAll(
        (day['activities'] as List)
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty),
      );
    }
    final images = _dayImages(day);
    final hasBody =
        images.isNotEmpty ||
        description.trim().isNotEmpty ||
        subSteps.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF3E5D0)),
        boxShadow: _isExpanded
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: hasBody
                  ? () => setState(() => _isExpanded = !_isExpanded)
                  : null,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Color(0xFFB07A3A),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$dayNumber',
                        style: const TextStyle(
                          color: Color(0xFFFCF7EF),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title.trim().isNotEmpty
                            ? title.trim()
                            : 'Day $dayNumber',
                        style: AppTypography.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF3B1E08),
                        ),
                      ),
                    ),
                    if (hasBody)
                      Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                        size: 20,
                        color: const Color(0xFF8A6B4A),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (_isExpanded) ...[
            if (images.isNotEmpty) _buildDayHeroImages(images),
            if (description.trim().isNotEmpty || subSteps.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (description.trim().isNotEmpty) ...[
                      RichTextDisplay(
                        description,
                        style: AppTypography.inter(
                          fontSize: 12.5,
                          height: 1.45,
                          color: const Color(0xFF4A1C00),
                        ),
                      ),
                    ],
                    if (subSteps.isNotEmpty) ...[
                      if (description.trim().isNotEmpty)
                        const SizedBox(height: 14),
                      const Divider(height: 1, color: Color(0xFFF3E5D0)),
                      const SizedBox(height: 12),
                      Text(
                        'Steps',
                        style: AppTypography.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF7A4621),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...subSteps.asMap().entries.map((entry) {
                        final idx = entry.key + 1;
                        final step = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6, left: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$idx.',
                                style: AppTypography.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFB07A3A),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: RichTextDisplay(
                                  step,
                                  style: AppTypography.inter(
                                    fontSize: 12.5,
                                    height: 1.4,
                                    color: const Color(0xFF4A1C00),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF3E5D0)),
      ),
      child: Text(
        label,
        style: AppTypography.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF8A6B4A),
        ),
      ),
    );
  }
}
