import 'dart:async';

import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/core/network/api_client.dart';
import 'package:satya_devotte_app/core/network/api_endpoints.dart';
import 'package:satya_devotte_app/core/network/device_timezone.dart';
import 'package:satya_devotte_app/core/network/interceptors.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/core/utils/date_formatters.dart';
import 'package:satya_devotte_app/features/calendar/presentation/controllers/calendar_controller.dart';
import 'package:satya_devotte_app/features/calendar/presentation/pages/calendar_page.dart';
import 'package:satya_devotte_app/features/cms/data/datasources/product_remote_datasource.dart';
import 'package:satya_devotte_app/features/cms/models/product_model.dart';
import 'package:satya_devotte_app/features/home/data/home_constants.dart';
import 'package:satya_devotte_app/features/home/presentation/pages/search_page.dart';
import 'package:satya_devotte_app/features/notifications/presentation/controllers/user_notifications_badge_controller.dart';
import 'package:satya_devotte_app/features/profile/presentation/controllers/profile_controller.dart';
import 'package:satya_devotte_app/features/profile/presentation/pages/profile_page.dart';
import 'package:satya_devotte_app/features/pujas/presentation/widgets/puja_shared_widgets.dart';
import 'package:satya_devotte_app/features/poojakit/presentation/pages/poojakit_page.dart';
import 'package:satya_devotte_app/features/poojakit/state/cart_controller.dart';
import 'package:satya_devotte_app/features/pujas/presentation/pages/puja_list_page.dart';
import 'package:satya_devotte_app/features/pujas/presentation/pages/user_catalog_tab_page.dart';
import 'package:satya_devotte_app/shared/components/section_title.dart';
import 'package:satya_devotte_app/shared/widgets/product_card.dart';
import 'package:satya_devotte_app/core/services/offline_service.dart';
import 'package:satya_devotte_app/shared/widgets/app_update_popup.dart';

class _HomeTabs {
  static const home = 0;
  static const pujas = 1;
  static const rituals = 2;
  static const deities = 3;
  static const calendar = 4;
  static const profile = 5;
  static const last = profile;
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  late final PageController _pageController;
  int _currentIndex = 0;
  bool _isAnimatingToTab = false;
  bool _showBottomNav = true;
  bool _hideNavContent = false;
  Timer? _hideNavDebounceTimer;
  bool _isFetchingHome = false;
  String _todayDateAndTithi = HomeConstants.dateAndTithi;
  String _dailySloka = HomeConstants.quote;
  String _slokaAuthor = '- Bhagavad Gita';
  String _slokaMeaning = '';
  String _slokaContemplation = '';
  String _slokaPrayer = '';
  List<HomeCircleItem> _poojas = HomeConstants.upcomingPooja;
  List<HomeCircleItem> _festivals = HomeConstants.upcomingFestivals;
  List<ProductModel> _featuredProducts = [];
  int _poojasCompleted = 0;
  int _ritualsCompleted = 0;
  int _dayStreak = 0;
  bool _isUpdateDialogShowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pageController = PageController(initialPage: _currentIndex);

    _recordUserStreak();
    _fetchHomeDataIfNeeded();
    if (Get.isRegistered<UserNotificationsBadgeController>()) {
      unawaited(
        Get.find<UserNotificationsBadgeController>().refreshUnreadBadge(),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // _triggerUpdatePopupIfNeeded();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // _triggerUpdatePopupIfNeeded();
      });
    }
  }

  void _triggerUpdatePopupIfNeeded() {
    if (!mounted) return;
    _logAppVersions();
    _promptAppUpdateIfAvailable(
      appName: 'Sathya',
      appSize: '182 MB',
      isMandatory: true,
    );
  }

  Future<void> _logAppVersions() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final currentVersion = '${info.version}+${info.buildNumber}';
      debugPrint(
        '[AppVersionCheck] Current Installed App Version: $currentVersion (Version: ${info.version}, Build: ${info.buildNumber})',
      );

      try {
        final response = await Get.find<ApiClient>().dio.get<String>(
          'https://play.google.com/store/apps/details?id=com.satya_devotte_app',
          options: dio.Options(
            responseType: dio.ResponseType.plain,
            extra: {kSkipApiLoaderKey: true},
          ),
        );
        final html = response.data ?? '';
        final patterns = [
          RegExp(r'\[\[\["([0-9]+\.[0-9]+\.[0-9]+[^"]*)"\]\]'),
          RegExp(r'HTl26[^>]*>([0-9]+\.[0-9]+\.[0-9]+)<'),
          RegExp(r'"([0-9]+\.[0-9]+\.[0-9]+)"'),
        ];
        String? foundVersion;
        for (final p in patterns) {
          final m = p.firstMatch(html);
          if (m != null && m.group(1) != null) {
            foundVersion = m.group(1);
            break;
          }
        }
        debugPrint(
          '[AppVersionCheck] Play Store Public Version: ${foundVersion ?? "Not published on Public Store yet (Closed Testing Track Active)"}',
        );
      } catch (_) {
        debugPrint(
          '[AppVersionCheck] Play Store Status: App is currently in Closed Testing / Beta track (Not public web listing)',
        );
      }
    } catch (e) {
      debugPrint('[AppVersionCheck] Error fetching package info: $e');
    }
  }

  /// Triggers the Google Play style centered update pop-up dialog over the app screen.
  void _promptAppUpdateIfAvailable({
    String? appName,
    String? releaseNotes,
    String? appSize,
    String? storeUrl,
    bool isMandatory = false,
  }) {
    if (!mounted || _isUpdateDialogShowing) return;
    _isUpdateDialogShowing = true;
    showAppUpdateDialog(
      context,
      appName: appName,
      appSize: appSize,
      releaseNotes: releaseNotes,
      storeUrl: storeUrl,
      isMandatory: isMandatory,
    ).then((_) {
      _isUpdateDialogShowing = false;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _hideNavDebounceTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _onTabSelected(int index) async {
    if (_currentIndex == index) return;
    if (_isAnimatingToTab) return;
    if (!_showBottomNav) {
      setState(() {
        _showBottomNav = true;
        _hideNavContent = false;
      });
    }
    _isAnimatingToTab = true;
    await _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
    if (!mounted) return;
    setState(() => _currentIndex = index);
    if (index == 0) {
      _recordUserStreak();
      _fetchHomeDataIfNeeded();
    } else if (index == _HomeTabs.calendar) {
      if (Get.isRegistered<CalendarController>()) {
        Get.find<CalendarController>().fetchData();
      }
    }
    _isAnimatingToTab = false;
  }

  Future<String> _deviceTimeZone() => deviceIanaTimeZone();

  /// `POST /user/streak` with device IANA timezone for daily streak tracking.
  Future<void> _recordUserStreak() async {
    final offlineService = Get.find<OfflineService>();
    try {
      final apiClient = Get.find<ApiClient>();
      final deviceTimeZone = await _deviceTimeZone();

      if (offlineService.isOnline.value) {
        final response = await apiClient.dio.post<dynamic>(
          ApiEndpoints.userStreak,
          options: dio.Options(
            headers: {'X-Timezone': deviceTimeZone},
            extra: {kSkipApiLoaderKey: true},
          ),
        );
        if (response.data is Map) {
          final data = response.data['data'] ?? response.data;
          if (data is Map) {
            final streak = data['streak'] is Map ? data['streak'] : data;
            final count = _readInt(streak, const ['streakCount', 'count']);
            if (count != null && mounted) {
              setState(() => _dayStreak = count);
            }
          }
        }
      } else {
        await offlineService.queueAction('record_streak', {
          'timezone': deviceTimeZone,
        });
      }
    } catch (error) {
      debugPrint('User streak recording failed: $error');
    }
  }

  int? _readInt(dynamic source, List<String> keys) {
    if (source is! Map) return null;
    for (final key in keys) {
      final value = source[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  Future<void> _openPoojasTabFromViewMore() async {
    await _onTabSelected(_HomeTabs.pujas);
  }

  Future<void> _openFestivalsCalendarTab() async {
    final controller = Get.isRegistered<CalendarController>()
        ? Get.find<CalendarController>()
        : Get.put(CalendarController());
    controller.setActiveTab(CalendarFilterTab.festivals);
    await _onTabSelected(_HomeTabs.calendar);
  }

  Future<void> _onPujaItemTap(HomeCircleItem item) async {
    final id = item.id?.trim() ?? '';
    final args = <String, dynamic>{
      if (item.raw != null) ...item.raw!,
      if (id.isNotEmpty) ...{'_id': id, 'id': id},
      'title': item.title.replaceAll('\n', ' ').trim(),
      if ((item.description ?? '').trim().isNotEmpty)
        'description': item.description!.trim(),
      if (item.imagePath.startsWith('http')) 'imageUrl': item.imagePath,
    };

    if (id.isEmpty && (item.raw == null || item.raw!.isEmpty)) {
      await _openPoojasTabFromViewMore();
      return;
    }
    await openPujaPreview(context, id: id, initialData: args);
  }

  Future<void> _onFestivalItemTap(HomeCircleItem item) async {
    final controller = Get.isRegistered<CalendarController>()
        ? Get.find<CalendarController>()
        : Get.put(CalendarController());
    controller.setActiveTab(CalendarFilterTab.festivals);

    final date = _parseHomeItemDate(item);
    if (date != null) {
      final normalized = DateTime(date.year, date.month, date.day);
      controller.selectedDate.value = normalized;
      controller.focusedDate.value = DateTime(date.year, date.month);
    }

    await _onTabSelected(_HomeTabs.calendar);
  }

  DateTime? _parseHomeItemDate(HomeCircleItem item) {
    final candidates = <String?>[
      item.date,
      item.raw?['date']?.toString(),
      item.raw?['startDate']?.toString(),
      item.raw?['festivalDate']?.toString(),
    ];
    for (final value in candidates) {
      final text = value?.trim();
      if (text == null || text.isEmpty) continue;
      final parsed = DateTime.tryParse(text);
      if (parsed != null) return parsed;
      final parts = text.split('-');
      if (parts.length == 3) {
        final day = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final year = int.tryParse(parts[2]);
        if (day != null && month != null && year != null) {
          return DateTime(year, month, day);
        }
      }
    }
    return null;
  }

  Future<void> _refreshHomeData() async {
    await Future.wait([
      _recordUserStreak(),
      _fetchHomeDataIfNeeded(forceRefresh: true),
    ]);
    if (Get.isRegistered<UserNotificationsBadgeController>()) {
      await Get.find<UserNotificationsBadgeController>().refreshUnreadBadge();
    }
  }

  Future<void> _fetchHomeDataIfNeeded({bool forceRefresh = false}) async {
    if (_isFetchingHome && !forceRefresh) return;
    _isFetchingHome = true;
    final offlineService = Get.find<OfflineService>();
    final cacheKey = 'home_data';
    final productsCacheKey = 'featured_products';

    // First, try to load cached data immediately
    try {
      final cachedPayload = offlineService.getCachedData(cacheKey);
      final cachedProductsData = offlineService.getCachedData(productsCacheKey);

      List<ProductModel> cachedProducts = [];
      if (cachedProductsData is List) {
        cachedProducts = cachedProductsData
            .map((p) => ProductModel.fromJson(Map<String, dynamic>.from(p)))
            .toList();
      }

      if (cachedPayload is Map && mounted) {
        _updateUIWithData(cachedPayload, cachedProducts);
      }
    } catch (error) {
      debugPrint('Error loading cached home data: $error');
    }

    // If offline, we're done after showing cache
    if (!offlineService.isOnline.value) {
      _isFetchingHome = false;
      return;
    }

    try {
      final apiClient = Get.find<ApiClient>();
      final deviceTimeZone = await _deviceTimeZone();
      // Fetch home and products in parallel
      final responses = await Future.wait([
        apiClient.dio.get<dynamic>(
          ApiEndpoints.home,
          queryParameters: {'timezone': deviceTimeZone},
          options: dio.Options(headers: {'X-Timezone': deviceTimeZone}),
        ),
        ProductRemoteDataSource(apiClient).getFeaturedProducts(limit: 10),
      ]);

      final homeResponse = responses[0] as dio.Response<dynamic>;
      final allProducts = responses[1] as List<ProductModel>;
      final filteredProducts = allProducts
          .where((p) => !p.isOrderClosed)
          .toList();

      // Update cache
      await Future.wait([
        offlineService.cacheData(cacheKey, homeResponse.data),
        offlineService.cacheData(
          productsCacheKey,
          filteredProducts.map((p) => p.toJson()).toList(),
        ),
      ]);

      if (!mounted) return;
      _updateUIWithData(homeResponse.data, filteredProducts);
    } catch (error) {
      debugPrint('Home API failed: $error');
    } finally {
      _isFetchingHome = false;
    }
  }

  void _updateUIWithData(dynamic payload, List<ProductModel> products) {
    if (payload is! Map) return;
    final data = payload['data'];
    if (data is! Map) return;

    final slokaData = data['dailySloka'];
    final poojasData = data['poojas'];
    final festivalsData = data['festivals'];
    final todayDateAndTithi = data['todayDateAndTithi']?.toString().trim();
    final todayDate = data['todayDate']?.toString().trim();
    final todayTithi = data['todayTithi']?.toString().trim();

    final completedPujas = _readInt(data, const [
      'completedPujasCount',
      'completedPoojasCount',
      'completedPoojaCount',
      'completedPujaCount',
    ]);
    final completedRituals = _readInt(data, const [
      'completedRitualsCount',
      'completedRitualCount',
    ]);
    final streakData = data['streak'];
    final streakCount = streakData is Map
        ? _readInt(streakData, const ['streakCount', 'count'])
        : _readInt(data, const ['streakCount', 'dayStreak']);

    final parsedSloka = slokaData is Map
        ? slokaData['sloka']?.toString().trim()
        : null;
    final parsedAuthor = slokaData is Map
        ? slokaData['author']?.toString().trim()
        : null;
    final parsedMeaning = slokaData is Map
        ? slokaData['meaning']?.toString().trim()
        : null;
    final parsedContemplation = slokaData is Map
        ? slokaData['contemplation']?.toString().trim()
        : null;
    final parsedPrayer = slokaData is Map
        ? slokaData['prayer']?.toString().trim()
        : null;

    final parsedPoojas = _mapHomeItems(
      poojasData,
      fallbackImage: 'assets/images/home/morePoojas.png',
    );
    final parsedFestivals = _mapHomeItems(
      festivalsData,
      fallbackImage: '',
      useDatePlaceholderWhenImageMissing: true,
    );

    String? resolvedDateAndTithi;
    if (todayDateAndTithi != null && todayDateAndTithi.isNotEmpty) {
      resolvedDateAndTithi = todayDateAndTithi;
    } else if (todayDate != null &&
        todayDate.isNotEmpty &&
        todayTithi != null &&
        todayTithi.isNotEmpty) {
      resolvedDateAndTithi = '$todayDate | $todayTithi';
    } else if (todayDate != null && todayDate.isNotEmpty) {
      resolvedDateAndTithi = todayDate;
    }

    if (!mounted) return;
    setState(() {
      _featuredProducts = products;
      if (completedPujas != null) {
        _poojasCompleted = completedPujas;
      }
      if (completedRituals != null) {
        _ritualsCompleted = completedRituals;
      }
      if (streakCount != null) {
        _dayStreak = streakCount;
      }
      if (resolvedDateAndTithi != null && resolvedDateAndTithi.isNotEmpty) {
        _todayDateAndTithi = resolvedDateAndTithi;
      }
      if (parsedSloka != null && parsedSloka.isNotEmpty) {
        _dailySloka = parsedSloka;
      }
      if (parsedAuthor != null && parsedAuthor.isNotEmpty) {
        _slokaAuthor = '- $parsedAuthor';
      }
      _slokaMeaning = parsedMeaning ?? '';
      _slokaContemplation = parsedContemplation ?? '';
      _slokaPrayer = parsedPrayer ?? '';
      if (parsedPoojas.isNotEmpty) {
        _poojas = parsedPoojas;
      }
      if (parsedFestivals.isNotEmpty) {
        _festivals = parsedFestivals;
      }
    });
  }

  List<HomeCircleItem> _mapHomeItems(
    dynamic source, {
    required String fallbackImage,
    bool useDatePlaceholderWhenImageMissing = false,
  }) {
    List<dynamic> list = [];
    if (source is List) {
      list = source;
    } else if (source is Map) {
      // Handle nested structures like { "festivals": [...] }
      for (final k in ['festivals', 'poojas', 'items', 'results', 'data']) {
        if (source[k] is List) {
          list = source[k];
          break;
        }
      }
    }

    if (list.isEmpty) return const [];

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

    final Set<String> seenIds = {};
    final List<HomeCircleItem> result = [];

    for (final raw in list) {
      if (raw is! Map) continue;
      final item = raw.map((k, v) => MapEntry(k.toString(), v));

      final title = _extractString(item['title'] ?? item['name']);

      // Clean URL: remove spaces and backticks
      String? clean(dynamic v) {
        final s = v?.toString().trim() ?? '';
        if (s.isEmpty) return null;
        return s.replaceAll('`', '').trim();
      }

      final media = item['media'];
      String? mediaImage;
      if (media is Map) {
        final images = media['images'];
        if (images is List && images.isNotEmpty) {
          mediaImage = images.first?.toString();
        }
      }
      final image =
          clean(item['imageUrl']) ?? clean(item['image']) ?? clean(mediaImage);

      final id = _extractString(item['_id'] ?? item['id']);
      final description = _extractString(
        item['description'] ?? item['purpose'] ?? item['about'],
      );
      final date = _extractString(
        item['date'] ?? item['startDate'] ?? item['festivalDate'],
      );
      final resolvedImagePath = (image != null && image.isNotEmpty)
          ? image
          : fallbackImage;

      final placeholderText =
          useDatePlaceholderWhenImageMissing &&
              resolvedImagePath.isEmpty &&
              date.isNotEmpty
          ? DateFormatters.formatFestivalDate(date)
          : null;

      // Skip if we already added an item with this id
      if (id.isNotEmpty) {
        if (seenIds.contains(id)) {
          continue;
        }
        seenIds.add(id);
      }

      result.add(
        HomeCircleItem(
          title: title.isEmpty ? 'Untitled' : title,
          imagePath: resolvedImagePath,
          placeholderText: placeholderText,
          id: id.isEmpty ? null : id,
          description: description.isEmpty ? null : description,
          date: date.isEmpty ? null : date,
          raw: Map<String, dynamic>.from(item),
        ),
      );
    }
    // Sort by date, with earliest upcoming dates first
    result.sort((a, b) {
      final dateA = _parseHomeItemDate(a);
      final dateB = _parseHomeItemDate(b);
      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;
      return dateA.compareTo(dateB);
    });

    return result;
  }

  void _onHomeScrollDirectionChanged(ScrollDirection direction) {
    if (_currentIndex != 0) return;

    if (direction == ScrollDirection.reverse && _showBottomNav) {
      _hideNavDebounceTimer?.cancel();
      _hideNavDebounceTimer = Timer(const Duration(milliseconds: 320), () {
        if (!mounted || !_showBottomNav) return;
        setState(() => _showBottomNav = false);
      });
      return;
    }

    if (direction == ScrollDirection.forward && !_showBottomNav) {
      _hideNavDebounceTimer?.cancel();
      setState(() {
        _showBottomNav = true;
        _hideNavContent = false;
      });
    }
  }

  void _onBottomNavSlideEnd() {
    if (!mounted) return;
    if (!_showBottomNav && !_hideNavContent) {
      setState(() => _hideNavContent = true);
      return;
    }
    if (_showBottomNav && _hideNavContent) {
      setState(() => _hideNavContent = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.viewPaddingOf(context).bottom;
    const navHeight = 78.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF2EBDC),
      extendBody: true,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _HomeTabContent(
            onScrollDirectionChanged: _onHomeScrollDirectionChanged,
            onRefresh: _refreshHomeData,
            onOpenTab: _onTabSelected,
            todayDateAndTithi: _todayDateAndTithi,
            dailySloka: _dailySloka,
            slokaAuthor: _slokaAuthor,
            slokaMeaning: _slokaMeaning,
            slokaContemplation: _slokaContemplation,
            slokaPrayer: _slokaPrayer,
            poojas: _poojas,
            festivals: _festivals,
            featuredProducts: _featuredProducts,
            poojasCompleted: _poojasCompleted,
            ritualsCompleted: _ritualsCompleted,
            dayStreak: _dayStreak,
            onPoojasViewMore: _openPoojasTabFromViewMore,
            onFestivalsViewMore: _openFestivalsCalendarTab,
            onPujaTap: _onPujaItemTap,
            onFestivalTap: _onFestivalItemTap,
          ),
          const UserPujasTabPage(),
          const UserRitualsTabPage(),
          const RitualListPage(),
          const CalendarPage(),
          const ProfilePage(),
        ],
      ),
      bottomNavigationBar: MediaQuery.removePadding(
        context: context,
        removeBottom: true,
        child: SafeArea(
          child: SizedBox(
            height: navHeight + 52 + bottomSafe,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                if (bottomSafe > 0)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: bottomSafe,
                    child: const ColoredBox(color: Color(0xFFF8F1E2)),
                  ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: bottomSafe,
                  height: navHeight,
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 380),
                    curve: Curves.easeInOutCubicEmphasized,
                    offset: _showBottomNav ? Offset.zero : const Offset(0, 1.1),
                    onEnd: _onBottomNavSlideEnd,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeInOutCubic,
                      opacity: _showBottomNav ? 1 : 0,
                      child: _hideNavContent
                          ? const SizedBox.shrink()
                          : _BottomNavBar(
                              currentIndex: _currentIndex,
                              onTap: _onTabSelected,
                            ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  bottom: bottomSafe + navHeight + 6,
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 360),
                    curve: Curves.easeInOutCubicEmphasized,
                    offset: (_showBottomNav && _currentIndex == _HomeTabs.home)
                        ? Offset.zero
                        : const Offset(-1.2, 0),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeInOut,
                      opacity:
                          (_showBottomNav && _currentIndex == _HomeTabs.home)
                          ? 1.0
                          : 0.0,
                      child: _StickyShopButton(
                        onTap: () => Get.to(() => const PoojaKitPage()),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeTabContent extends StatefulWidget {
  const _HomeTabContent({
    required this.onScrollDirectionChanged,
    required this.onRefresh,
    required this.onOpenTab,
    required this.todayDateAndTithi,
    required this.dailySloka,
    required this.slokaAuthor,
    required this.slokaMeaning,
    required this.slokaContemplation,
    required this.slokaPrayer,
    required this.poojas,
    required this.festivals,
    required this.featuredProducts,
    required this.poojasCompleted,
    required this.ritualsCompleted,
    required this.dayStreak,
    required this.onPoojasViewMore,
    required this.onFestivalsViewMore,
    required this.onPujaTap,
    required this.onFestivalTap,
  });

  final ValueChanged<ScrollDirection> onScrollDirectionChanged;
  final Future<void> Function() onRefresh;
  final Future<void> Function(int index) onOpenTab;
  final String todayDateAndTithi;
  final String dailySloka;
  final String slokaAuthor;
  final String slokaMeaning;
  final String slokaContemplation;
  final String slokaPrayer;
  final List<HomeCircleItem> poojas;
  final List<HomeCircleItem> festivals;
  final List<ProductModel> featuredProducts;
  final int poojasCompleted;
  final int ritualsCompleted;
  final int dayStreak;
  final Future<void> Function() onPoojasViewMore;
  final Future<void> Function() onFestivalsViewMore;
  final Future<void> Function(HomeCircleItem item) onPujaTap;
  final Future<void> Function(HomeCircleItem item) onFestivalTap;

  @override
  State<_HomeTabContent> createState() => _HomeTabContentState();
}

class _HomeTabContentState extends State<_HomeTabContent> {
  void _openSearch() {
    Get.to<dynamic>(() => const SearchPage(), routeName: AppRoutes.search);
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<UserScrollNotification>(
      onNotification: (notification) {
        widget.onScrollDirectionChanged(notification.direction);
        return false;
      },
      child: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: widget.onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            children: [
              _HomeHeader(
                onOpenSearch: _openSearch,
                todayDateAndTithi: widget.todayDateAndTithi,
                dailySloka: widget.dailySloka,
                slokaAuthor: widget.slokaAuthor,
                slokaMeaning: widget.slokaMeaning,
                slokaContemplation: widget.slokaContemplation,
                slokaPrayer: widget.slokaPrayer,
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(0, 14, 0, 0),
                child: _HomeBodySections(
                  poojas: widget.poojas,
                  festivals: widget.festivals,
                  featuredProducts: widget.featuredProducts,
                  poojasCompleted: widget.poojasCompleted,
                  ritualsCompleted: widget.ritualsCompleted,
                  dayStreak: widget.dayStreak,
                  onPoojasViewMore: widget.onPoojasViewMore,
                  onFestivalsViewMore: widget.onFestivalsViewMore,
                  onPujaTap: widget.onPujaTap,
                  onFestivalTap: widget.onFestivalTap,
                ),
              ),
              const SizedBox(height: 16),
              _Footer(),
              const SizedBox(height: 35),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeBodySections extends StatelessWidget {
  const _HomeBodySections({
    required this.poojas,
    required this.festivals,
    required this.featuredProducts,
    required this.poojasCompleted,
    required this.ritualsCompleted,
    required this.dayStreak,
    required this.onPoojasViewMore,
    required this.onFestivalsViewMore,
    required this.onPujaTap,
    required this.onFestivalTap,
  });

  final List<HomeCircleItem> poojas;
  final List<HomeCircleItem> festivals;
  final List<ProductModel> featuredProducts;
  final int poojasCompleted;
  final int ritualsCompleted;
  final int dayStreak;
  final Future<void> Function() onPoojasViewMore;
  final Future<void> Function() onFestivalsViewMore;
  final Future<void> Function(HomeCircleItem item) onPujaTap;
  final Future<void> Function(HomeCircleItem item) onFestivalTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
          child: _HomeCircleSection(
            title: 'Upcoming Puja',
            items: poojas,
            useWrap: false,
            moreImagePath: 'assets/images/home/morePoojas.png',
            onItemTap: (item) => onPujaTap(item),
            onViewMoreTap: onPoojasViewMore,
          ),
        ),
        // if (featuredProducts.isNotEmpty) ...[
        //   const SizedBox(height: 16),
        //   _FeaturedProductsSection(products: featuredProducts),
        // ],
        SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
          child: _HomeCircleSection(
            title: 'Upcoming Festivals',
            items: festivals,
            useWrap: false,
            useFestivalStyle: true,
            moreImagePath: 'assets/images/home/more_festivals.png',
            onItemTap: (item) => onFestivalTap(item),
            onViewMoreTap: onFestivalsViewMore,
          ),
        ),
        const SizedBox(height: 28),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
          child: _AchievementsSection(
            poojasCompleted: poojasCompleted,
            ritualsCompleted: ritualsCompleted,
            dayStreak: dayStreak,
          ),
        ),
        // Donation section removed from Home screen as per updated design.
      ],
    );
  }
}

class _AchievementsSection extends StatelessWidget {
  const _AchievementsSection({
    required this.poojasCompleted,
    required this.ritualsCompleted,
    required this.dayStreak,
  });

  final int poojasCompleted;
  final int ritualsCompleted;
  final int dayStreak;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'My Achievements'),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _AchievementCard(
                value: poojasCompleted,
                label: 'Pujas Completed',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _AchievementCard(
                value: ritualsCompleted,
                label: 'Rituals Completed',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _AchievementCard(value: dayStreak, label: 'Day Streak 🔥'),
            ),
          ],
        ),
      ],
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xF8FCF7EF),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16000000),
            blurRadius: 18,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$value',
            style: AppTypography.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF252525),
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.inter(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF7A746D),
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeCircleSection extends StatelessWidget {
  const _HomeCircleSection({
    required this.title,
    required this.items,
    this.useWrap = false,
    this.useFestivalStyle = false,
    this.moreImagePath = 'assets/images/home/more_festivals.png',
    this.onViewMoreTap,
    this.onItemTap,
  });

  final String title;
  final List<HomeCircleItem> items;
  final bool useWrap;
  final bool useFestivalStyle;
  final String moreImagePath;
  final Future<void> Function()? onViewMoreTap;

  /// Optional per-item tap handler.
  final void Function(HomeCircleItem item)? onItemTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: title),
          useWrap
              ? _CircleWrap(
                  items: items,
                  onItemTap: onItemTap,
                  onMoreTap: onViewMoreTap == null
                      ? null
                      : () => onViewMoreTap!(),
                )
              : _CircleRow(
                  items: items,
                  useFestivalStyle: useFestivalStyle,
                  moreImagePath: moreImagePath,
                  onItemTap: onItemTap,
                  onViewMoreTap: onViewMoreTap,
                ),
        ],
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final Future<void> Function(int) onTap;
  static const int lastTabIndex = _HomeTabs.last;

  static const Color navBarColor = Color(0xFFF8F1E2);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 78,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final slotWidth = totalWidth / 6;

          return TweenAnimationBuilder<double>(
            tween: Tween<double>(
              begin: currentIndex.toDouble(),
              end: currentIndex.toDouble(),
            ),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            builder: (context, animProgress, _) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Fluid elevated hump background with flat side edges
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _FluidHumpPainter(
                        animProgress: animProgress,
                        totalTabs: 6,
                        color: navBarColor,
                      ),
                    ),
                  ),

                  // 6 Navigation Tab Items
                  for (int i = 0; i < 6; i++)
                    Positioned(
                      left: i * slotWidth,
                      width: slotWidth,
                      top: 0,
                      bottom: 0,
                      child: _buildNavItem(i, animProgress),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNavItem(int index, double animProgress) {
    final dist = (animProgress - index).abs().clamp(0.0, 1.0);
    final isSelected = index == currentIndex;
    final itemTop = 14.0 + (dist * 10.0);

    final IconData icon;
    final String label;
    switch (index) {
      case _HomeTabs.home:
        icon = Icons.home_outlined;
        label = 'Home';
        break;
      case _HomeTabs.pujas:
        icon = Icons.local_fire_department_outlined;
        label = 'Pujas';
        break;
      case _HomeTabs.rituals:
        icon = Icons.self_improvement_outlined;
        label = 'Rituals';
        break;
      case _HomeTabs.deities:
        icon = Icons.temple_hindu_outlined;
        label = 'Deities';
        break;
      case _HomeTabs.calendar:
        icon = Icons.calendar_today_outlined;
        label = 'Calendar';
        break;
      case _HomeTabs.profile:
        icon = Icons.person_outlined;
        label = 'Profile';
        break;
      default:
        icon = Icons.circle_outlined;
        label = '';
    }

    const unselectedColor = Color(0xFF7F776D);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(index),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: itemTop,
            child: AnimatedScale(
              scale: isSelected ? 1.05 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  isSelected
                      ? ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFF183EA4), Color(0xFFE35600)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds),
                          blendMode: BlendMode.srcIn,
                          child: Icon(
                            icon,
                            size: 24,
                            color: const Color(0xFFFCF7EF),
                          ),
                        )
                      : Icon(
                          icon,
                          size: 22,
                          color: unselectedColor,
                        ),
                  const SizedBox(height: 3),
                  isSelected
                      ? ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFF183EA4), Color(0xFFE35600)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ).createShader(bounds),
                          blendMode: BlendMode.srcIn,
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.visible,
                            style: AppTypography.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFFCF7EF),
                            ),
                          ),
                        )
                      : Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.visible,
                          style: AppTypography.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: unselectedColor,
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

class _FluidHumpPainter extends CustomPainter {
  const _FluidHumpPainter({
    required this.animProgress,
    required this.totalTabs,
    required this.color,
  });

  final double animProgress;
  final int totalTabs;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final slotWidth = size.width / totalTabs;
    final cx = (animProgress + 0.5) * slotWidth;
    const topY = 16.0;
    const humpSpan = 38.0;

    final path = Path();
    path.moveTo(0, topY);

    final xLeft = cx - humpSpan;
    final xRight = cx + humpSpan;

    if (xLeft > 0) {
      path.lineTo(xLeft, topY);
    }

    path.cubicTo(
      cx - (humpSpan * 0.55), topY,
      cx - (humpSpan * 0.45), 0,
      cx, 0,
    );
    path.cubicTo(
      cx + (humpSpan * 0.45), 0,
      cx + (humpSpan * 0.55), topY,
      xRight.clamp(0.0, size.width), topY,
    );

    path.lineTo(size.width, topY);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    // Subtle top border/shadow for definition
    final shadowPaint = Paint()
      ..color = const Color(0x18000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawPath(path.shift(const Offset(0, -2)), shadowPaint);

    // Main background fill
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);

    // Subtle top contour stroke
    final strokePath = Path();
    strokePath.moveTo(0, topY);
    if (xLeft > 0) strokePath.lineTo(xLeft, topY);
    strokePath.cubicTo(
      cx - (humpSpan * 0.55), topY,
      cx - (humpSpan * 0.45), 0,
      cx, 0,
    );
    strokePath.cubicTo(
      cx + (humpSpan * 0.45), 0,
      cx + (humpSpan * 0.55), topY,
      xRight.clamp(0.0, size.width), topY,
    );
    strokePath.lineTo(size.width, topY);

    final strokePaint = Paint()
      ..color = const Color(0xFFEADBCE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(strokePath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _FluidHumpPainter oldDelegate) {
    return oldDelegate.animProgress != animProgress ||
        oldDelegate.color != color ||
        oldDelegate.totalTabs != totalTabs;
  }
}

class _HomeSearchBar extends StatelessWidget {
  const _HomeSearchBar({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFFCF7EF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5D5C5), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF183EA4), Color(0xFFE35600)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFFFCF7EF),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Search pujas, deities, festivals...',
                    style: AppTypography.inter(
                      fontSize: 13,
                      color: const Color(0xFF9B8B7B),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),

                const SizedBox(width: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.onOpenSearch,
    required this.todayDateAndTithi,
    required this.dailySloka,
    required this.slokaAuthor,
    required this.slokaMeaning,
    required this.slokaContemplation,
    required this.slokaPrayer,
  });

  final VoidCallback onOpenSearch;
  final String todayDateAndTithi;
  final String dailySloka;
  final String slokaAuthor;
  final String slokaMeaning;
  final String slokaContemplation;
  final String slokaPrayer;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(
      builder: (profileController) {
        final displayName = ProfileController.displayNameFromUserMap(
          profileController.resolvedUser,
        );
        final topInset = MediaQuery.paddingOf(context).top;
        const headerHeight = 500.0;

        return SizedBox(
          width: double.infinity,
          height: headerHeight,
          child: Stack(
            children: [
              const Positioned.fill(
                child: Image(
                  image: AssetImage('assets/images/home/new_home_header.png'),
                  fit: BoxFit.fill,
                  alignment: Alignment.topCenter,
                ),
              ),
              // Positioned(
              //   top: 0,
              //   right: -2,
              //   child: Opacity(
              //     opacity: 0.95,
              //     child: const Image(
              //       image: AssetImage('assets/images/home/homeHeaderFlower.png'),
              //       width: 178,
              //       height: 120,
              //       fit: BoxFit.contain,
              //     ),
              //   ),
              // ),
              Padding(
                padding: EdgeInsets.fromLTRB(16, topInset + 8, 16, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Image(
                          image: const AssetImage('assets/images/appLogo.png'),
                          height: 52,
                          color: Color(0xFFFCF7EF),
                        ),
                        Spacer(),
                        Text(
                          todayDateAndTithi,
                          style: AppTypography.inter(
                            color: Color(0xFFFCF7EF),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Obx(() {
                          final badgeCtrl =
                              Get.find<UserNotificationsBadgeController>();
                          return GestureDetector(
                            onTap: () => Get.toNamed(AppRoutes.notifications),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                SvgPicture.asset(
                                  'assets/svgs/bell.svg',
                                  width: 18,
                                  height: 18,
                                  colorFilter: const ColorFilter.mode(
                                    Color(0xFFFCF7EF),
                                    BlendMode.srcIn,
                                  ),
                                ),
                                if (badgeCtrl.hasUnread.value)
                                  const Positioned(
                                    right: -2,
                                    top: -2,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: Color(0xFFE44D4D),
                                        shape: BoxShape.circle,
                                      ),
                                      child: SizedBox(width: 8, height: 8),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(width: 12),
                        // Cart icon (with count badge) for Pooja Kit.
                        Obx(() {
                          final cartCtrl = Get.find<CartController>();
                          final count = cartCtrl.itemCount;
                          return GestureDetector(
                            onTap: () => Get.toNamed(AppRoutes.poojaKitCart),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFCF7EF),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.shopping_cart_outlined,
                                    size: 22,
                                    color: Colors.black,
                                  ),
                                ),
                                if (count > 0)
                                  Positioned(
                                    right: 2,
                                    top: 2,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE44D4D),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: Color(0xFFFCF7EF),
                                          width: 1.2,
                                        ),
                                      ),
                                      child: Text(
                                        count > 99 ? '99+' : '$count',
                                        style: AppTypography.inter(
                                          color: Color(0xFFFCF7EF),
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          height: 1.0,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Namaste',
                      style: AppTypography.inter(
                        color: Color(0xFFE4B8AB),
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      displayName,
                      style: AppTypography.lora(
                        color: Color(0xFFFCF7EF),
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _HomeSearchBar(onTap: onOpenSearch),
                    const SizedBox(height: 8),
                    const _HeaderDivider(),
                    const SizedBox(height: 8),
                    _QuoteCard(
                      quote: dailySloka,
                      author: slokaAuthor,
                      meaning: slokaMeaning,
                      contemplation: slokaContemplation,
                      prayer: slokaPrayer,
                    ),
                    const SizedBox(height: 5),
                    const _HeaderDivider(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeaderDivider extends StatelessWidget {
  const _HeaderDivider();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Image(
        image: AssetImage('assets/images/home/divider.png'),
        width: 145,
        fit: BoxFit.contain,
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          // FutureBuilder<PackageInfo>(
          //   future: PackageInfo.fromPlatform(),
          //   builder: (context, snapshot) {
          //     final info = snapshot.data;
          //     final version = info?.version ?? '';
          //     final buildNumber = info?.buildNumber ?? '';
          //     final label = version.isEmpty
          //         ? 'Sathya'
          //         : buildNumber.isEmpty
          //         ? 'Sathya v$version'
          //         : 'Sathya v$version ($buildNumber)';
          //     return Text(
          //       label,
          //       style: AppTypography.inter(fontSize: 12, color: Colors.grey),
          //     );
          //   },
          // ),
          // const SizedBox(height: 4),
          Text(
            'Developed by',
            style: AppTypography.lora(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Color(0XFF78716C),
            ),
          ),
          const SizedBox(height: 12),
          Image.asset('assets/images/redin_logo.png', width: 136, height: 42),
        ],
      ),
    );
  }
}

class _QuoteCard extends StatefulWidget {
  const _QuoteCard({
    required this.quote,
    required this.author,
    required this.meaning,
    required this.contemplation,
    required this.prayer,
  });

  final String quote;
  final String author;
  final String meaning;
  final String contemplation;
  final String prayer;

  @override
  State<_QuoteCard> createState() => _QuoteCardState();
}

class _QuoteCardState extends State<_QuoteCard> {
  int _selectedTab = -1;

  static const double _cardRadius = 16;
  static const double _flowerSize = 100;
  static const double _horizontalAttach = 22;
  static const double _tabHeight = 35;
  static const double _contentHeight = 120;

  String get _tabText {
    switch (_selectedTab) {
      case 0:
        return widget.meaning.trim().isNotEmpty
            ? widget.meaning.trim()
            : 'No meaning available.';
      case 1:
        return widget.contemplation.trim().isNotEmpty
            ? widget.contemplation.trim()
            : 'No contemplation available.';
      case 2:
        return widget.prayer.trim().isNotEmpty
            ? widget.prayer.trim()
            : 'No prayer available.';
      default:
        return widget.quote;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SizedBox(
        width: double.infinity,
        height: _tabHeight + _contentHeight,
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                height: _tabHeight,
                child: Row(
                  children: [
                    Expanded(
                      child: _SlokaTabBtn(
                        label: 'Meaning',
                        selected: _selectedTab == 0,
                        onTap: () => setState(
                          () => _selectedTab = _selectedTab == 0 ? -1 : 0,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _SlokaTabBtn(
                        label: 'Contemplation',
                        selected: _selectedTab == 1,
                        onTap: () => setState(
                          () => _selectedTab = _selectedTab == 1 ? -1 : 1,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _SlokaTabBtn(
                        label: 'Prayer',
                        selected: _selectedTab == 2,
                        onTap: () => setState(
                          () => _selectedTab = _selectedTab == 2 ? -1 : 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 1),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0x3D2A2632),
                  borderRadius: BorderRadius.circular(_cardRadius),
                  border: Border.all(color: const Color(0x30FFFFFF)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 130,
                      offset: Offset(0, 4),
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(_cardRadius),
                  child: Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      Positioned(
                        top: 0,
                        left: -_horizontalAttach,
                        child: Opacity(
                          opacity: 0.22,
                          child: Image(
                            image: AssetImage(
                              'assets/images/home/cardFlower.png',
                            ),
                            width: _flowerSize,
                            height: _flowerSize,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: -_horizontalAttach,
                        child: Opacity(
                          opacity: 0.22,
                          child: RotatedBox(
                            quarterTurns: 2,
                            child: Image(
                              image: AssetImage(
                                'assets/images/home/cardFlower.png',
                              ),
                              width: _flowerSize,
                              height: _flowerSize,
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 16,
                          ),
                          child: Text(
                            _tabText,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.lora(
                              color: Color(0xFFFCF7EF),
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                              height: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlokaTabBtn extends StatelessWidget {
  const _SlokaTabBtn({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const selectedGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Color(0xB8506AB2), Color(0x5C643D52)],
    );

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            alignment: Alignment.center,
            height: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              gradient: selected ? selectedGradient : null,
              color: selected ? null : const Color(0x3D643D52),
              border: Border.all(
                color: selected ? Colors.transparent : const Color(0x14643D52),
                width: 1,
              ),
              boxShadow: selected
                  ? const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 18,
                        offset: Offset(0, 4),
                      ),
                    ]
                  : const [],
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.inter(
                color: selected ? Color(0xFFFCF7EF) : const Color(0x99FFFFFF),
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                height: 1,
              ),
            ),
          ),
          if (selected)
            const Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _TopRightChipBorderPainter(
                    radius: 10,
                    strokeWidth: 1.2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TopRightChipBorderPainter extends CustomPainter {
  const _TopRightChipBorderPainter({
    required this.radius,
    required this.strokeWidth,
  });

  final double radius;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final topY = strokeWidth / 2;
    final rightX = size.width - strokeWidth / 2;

    final topPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: const [Color(0x00FFEF11), Color(0x55FFEF11), Color(0xFFFFEF11)],
        stops: const [0.0, 0.72, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, strokeWidth));

    final topPath = Path()
      ..moveTo(radius, topY)
      ..lineTo(size.width - radius, topY)
      ..arcToPoint(
        Offset(rightX, radius),
        radius: Radius.circular(radius),
        clockwise: true,
      );
    canvas.drawPath(topPath, topPaint);

    final rightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader =
          LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: const [
              Color(0xFFFFEF11),
              Color(0x66FFEF11),
              Color(0x00FFEF11),
            ],
            stops: const [0.0, 0.35, 1.0],
          ).createShader(
            Rect.fromLTWH(
              size.width - strokeWidth,
              0,
              strokeWidth,
              size.height,
            ),
          );

    canvas.drawLine(
      Offset(rightX, radius),
      Offset(rightX, size.height - 2),
      rightPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TopRightChipBorderPainter oldDelegate) {
    return oldDelegate.radius != radius ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 0),
      child: Text(
        title,
        style: AppTypography.lora(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF4A1C00),
        ),
      ),
    );
  }
}

class _CircleRow extends StatelessWidget {
  const _CircleRow({
    required this.items,
    this.useFestivalStyle = false,
    this.moreImagePath = 'assets/images/home/more_festivals.png',
    this.onViewMoreTap,
    this.onItemTap,
  });
  final List<HomeCircleItem> items;
  final bool useFestivalStyle;
  final String moreImagePath;
  final Future<void> Function()? onViewMoreTap;
  final void Function(HomeCircleItem item)? onItemTap;

  bool _isMoreTitle(String title) {
    final normalized = title.trim().toLowerCase().replaceAll('\n', ' ');
    return normalized == 'view more' || normalized == 'more';
  }

  @override
  Widget build(BuildContext context) {
    final baseItems = items.where((item) => !_isMoreTitle(item.title)).toList();
    final staticViewMoreItem = HomeCircleItem(
      title: 'View\nMore',
      imagePath: moreImagePath,
    );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [...baseItems, staticViewMoreItem]
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _CircleItem(
                  item: item,
                  useFestivalStyle: useFestivalStyle,
                  onTap: _isMoreTitle(item.title)
                      ? () {
                          onViewMoreTap?.call();
                        }
                      : (onItemTap == null ? null : () => onItemTap!(item)),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _CircleWrap extends StatelessWidget {
  const _CircleWrap({required this.items, this.onItemTap, this.onMoreTap});

  final List<HomeCircleItem> items;

  /// Invoked when a real (non-"More") tile is tapped.
  final void Function(HomeCircleItem item)? onItemTap;

  /// Invoked when the trailing "More" tile is tapped.
  final VoidCallback? onMoreTap;

  bool _isMoreTitle(String title) {
    final normalized = title.trim().toLowerCase().replaceAll('\n', ' ');
    return normalized == 'view more' || normalized == 'more';
  }

  @override
  Widget build(BuildContext context) {
    final baseItems = items.where((item) => !_isMoreTitle(item.title)).toList();
    const staticMoreItem = HomeCircleItem(
      title: 'More',
      imagePath: 'assets/images/home/moreDonations.png',
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [...baseItems, staticMoreItem]
            .map(
              (item) => _CircleItem(
                item: item,
                onTap: _isMoreTitle(item.title)
                    ? onMoreTap
                    : (onItemTap != null ? () => onItemTap!(item) : null),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _CircleItem extends StatelessWidget {
  const _CircleItem({
    required this.item,
    this.useFestivalStyle = false,
    this.onTap,
  });
  final HomeCircleItem item;
  final bool useFestivalStyle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final normalizedTitle = item.title.trim().toLowerCase().replaceAll(
      '\n',
      ' ',
    );
    final isMoreItem =
        normalizedTitle == 'view more' || normalizedTitle == 'more';
    final isDatePlaceholder =
        useFestivalStyle &&
        item.imagePath.isEmpty &&
        (item.placeholderText?.trim().isNotEmpty ?? false);
    return SizedBox(
      width: 80,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 70,
              height: 70,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFCF7EF),
                border: Border.all(color: Color(0xFFFCF7EF), width: 2),
                boxShadow: useFestivalStyle
                    ? const [
                        BoxShadow(
                          color: Color(0x1F4A1C00),
                          blurRadius: 14,
                          offset: Offset(0, 5),
                        ),
                      ]
                    : const [],
              ),
              child: ClipOval(
                child: item.imagePath.isEmpty
                    ? isDatePlaceholder
                          ? ColoredBox(
                              color: Color(0xFFFCF7EF),
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  child: Text(
                                    item.placeholderText ?? '',
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.inter(
                                      fontSize: 10,
                                      color: const Color(0xFF5B2B18),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : Image.asset(
                              'assets/images/default_img.png',
                              fit: BoxFit.cover,
                            )
                    : item.imagePath.startsWith('http')
                    ? CachedNetworkImage(
                        imageUrl: item.imagePath,
                        fit: BoxFit.cover,
                        errorWidget: (context, error, stackTrace) {
                          return Image.asset(
                            'assets/images/default_img.png',
                            fit: BoxFit.cover,
                          );
                        },
                        placeholder: (context, url) {
                          return Image.asset(
                            'assets/images/default_img.png',
                            fit: BoxFit.cover,
                          );
                        },
                      )
                    : Image(
                        image: AssetImage(item.imagePath),
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 36,
              child: Align(
                alignment: Alignment.topCenter,
                child: Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTypography.inter(
                    fontSize: 11,
                    color: AppColors.textColor,
                    fontWeight: isMoreItem ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StickyShopButton extends StatelessWidget {
  const _StickyShopButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        child: Ink(
          height: 42,
          padding: const EdgeInsets.only(left: 16, right: 18),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF183EA4), Color(0xFFE35600)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.storefront_outlined,
                size: 19,
                color: Color(0xFFFCF7EF),
              ),
              const SizedBox(width: 7),
              Text(
                'Shop',
                style: AppTypography.inter(
                  color: const Color(0xFFFCF7EF),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 11,
                color: const Color(0xFFFCF7EF).withValues(alpha: 0.9),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



// ignore: unused_element
class _FeaturedProductsSection extends StatelessWidget {
  const _FeaturedProductsSection({required this.products});
  final List<ProductModel> products;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: SectionTitle('Featured Puja Kits'),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 280,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              final cartCtrl = Get.find<CartController>();
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ProductCard(
                  product: product,
                  width: 160,
                  onTap: () => Get.toNamed(
                    AppRoutes.poojaKitDetails,
                    arguments: product,
                  ),
                  onAddToCartTap: () => cartCtrl.addToCart(
                    product.id,
                    productCategory: product.category,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
