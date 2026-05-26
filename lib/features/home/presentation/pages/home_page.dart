import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/core/network/api_client.dart';
import 'package:satya_devotte_app/core/network/api_endpoints.dart';
import 'package:satya_devotte_app/core/network/interceptors.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/core/utils/date_formatters.dart';
import 'package:satya_devotte_app/features/calendar/presentation/controllers/calendar_controller.dart';
import 'package:satya_devotte_app/features/calendar/presentation/pages/calendar_page.dart';
import 'package:satya_devotte_app/features/cms/data/datasources/product_remote_datasource.dart';
import 'package:satya_devotte_app/features/cms/models/product_model.dart';
import 'package:satya_devotte_app/features/donations/data/models/donation.dart';
import 'package:satya_devotte_app/features/home/data/home_constants.dart';
import 'package:satya_devotte_app/features/profile/presentation/controllers/profile_controller.dart';
import 'package:satya_devotte_app/features/profile/presentation/pages/profile_page.dart';
import 'package:satya_devotte_app/features/poojakit/presentation/pages/poojakit_page.dart';
import 'package:satya_devotte_app/features/poojakit/state/cart_controller.dart';
import 'package:satya_devotte_app/features/pujas/presentation/pages/puja_list_page.dart';
import 'package:satya_devotte_app/shared/components/section_title.dart';
import 'package:satya_devotte_app/shared/widgets/product_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
  int _dayStreak = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _fetchHomeDataIfNeeded();
    _fetchAchievementsData(recordStreak: true);
  }

  @override
  void dispose() {
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
      _fetchHomeDataIfNeeded();
      _fetchAchievementsData(recordStreak: true);
    }
    _isAnimatingToTab = false;
  }

  Future<String> _deviceTimeZone() async {
    try {
      return await FlutterTimezone.getLocalTimezone();
    } catch (_) {
      return DateTime.now().timeZoneName;
    }
  }

  Future<void> _fetchAchievementsData({required bool recordStreak}) async {
    await Future.wait([
      recordStreak ? _recordUserStreak() : _fetchUserStreakStatus(),
      _fetchPoojasCompleted(),
    ]);
  }

  /// `POST /user/streak` with device IANA timezone for daily streak tracking.
  Future<void> _recordUserStreak() async {
    try {
      final apiClient = Get.find<ApiClient>();
      final deviceTimeZone = await _deviceTimeZone();
      final response = await apiClient.dio.post<dynamic>(
        ApiEndpoints.userStreak,
        options: Options(
          headers: {'X-Timezone': deviceTimeZone},
          extra: {kSkipApiLoaderKey: true},
        ),
      );
      _updateDayStreakFromPayload(response.data);
    } on DioException catch (error) {
      debugPrint('User streak API failed: ${error.message}');
      await _fetchUserStreakStatus();
    } catch (error) {
      debugPrint('User streak API failed: $error');
      await _fetchUserStreakStatus();
    }
  }

  Future<void> _fetchUserStreakStatus() async {
    try {
      final apiClient = Get.find<ApiClient>();
      final deviceTimeZone = await _deviceTimeZone();
      final response = await apiClient.dio.get<dynamic>(
        ApiEndpoints.userStreak,
        options: Options(
          headers: {'X-Timezone': deviceTimeZone},
          extra: {kSkipApiLoaderKey: true},
        ),
      );
      _updateDayStreakFromPayload(response.data);
    } on DioException catch (error) {
      debugPrint('User streak status API failed: ${error.message}');
    } catch (error) {
      debugPrint('User streak status API failed: $error');
    }
  }

  Future<void> _fetchPoojasCompleted() async {
    try {
      final apiClient = Get.find<ApiClient>();
      final response = await apiClient.dio.get<dynamic>(
        ApiEndpoints.userPoojaHistoryFinished,
        queryParameters: const {'page': 1, 'limit': 1},
        options: Options(extra: {kSkipApiLoaderKey: true}),
      );
      final completed = _extractCompletedPoojaCount(response.data);
      if (!mounted) return;
      setState(() => _poojasCompleted = completed);
    } on DioException catch (error) {
      debugPrint('Pooja completed API failed: ${error.message}');
    } catch (error) {
      debugPrint('Pooja completed API failed: $error');
    }
  }

  void _updateDayStreakFromPayload(dynamic payload) {
    final streak =
        _extractMap(payload, const ['data', 'streak']) ??
        _extractMap(payload, const ['streak']);
    final count = _readInt(streak, const ['streakCount']);
    if (count == null || !mounted) return;
    setState(() => _dayStreak = count);
  }

  int _extractCompletedPoojaCount(dynamic payload) {
    final root = payload is Map ? payload : const <String, dynamic>{};
    final direct = _readInt(root, const [
      'total',
      'totalCount',
      'count',
      'completed',
      'completedCount',
      'finishedCount',
    ]);
    if (direct != null) return direct;

    final data = root['data'];
    if (data is List) return data.length;
    if (data is Map) {
      final dataCount = _readInt(data, const [
        'total',
        'totalCount',
        'count',
        'completed',
        'completedCount',
        'finishedCount',
      ]);
      if (dataCount != null) return dataCount;

      final pagination = data['pagination'];
      final pagedCount = _readInt(pagination, const ['total', 'totalCount']);
      if (pagedCount != null) return pagedCount;

      for (final key in const ['finished', 'items', 'results', 'docs']) {
        final value = data[key];
        if (value is List) return value.length;
      }
    }
    return 0;
  }

  Map? _extractMap(dynamic payload, List<String> path) {
    dynamic current = payload;
    for (final key in path) {
      if (current is! Map) return null;
      current = current[key];
    }
    return current is Map ? current : null;
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
    await Get.toNamed(AppRoutes.rituals);
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
    await Get.toNamed<dynamic>(AppRoutes.ritualDetail, arguments: args);
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

    await _onTabSelected(3);
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

  Future<void> _fetchHomeDataIfNeeded() async {
    if (_isFetchingHome) return;
    _isFetchingHome = true;
    try {
      final apiClient = Get.find<ApiClient>();

      // Fetch home layout data
      final response = await apiClient.dio.get<dynamic>(ApiEndpoints.home);

      // Fetch featured products separately as per requirement
      final productDs = ProductRemoteDataSource(apiClient);
      final products = await productDs.getFeaturedProducts(limit: 10);

      final payload = response.data;
      if (payload is! Map) return;
      final data = payload['data'];
      if (data is! Map) return;

      final slokaData = data['dailySloka'];
      final poojasData = data['poojas'];
      final festivalsData = data['festivals'];
      final todayDateAndTithi = data['todayDateAndTithi']?.toString().trim();

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

      if (!mounted) return;
      setState(() {
        _featuredProducts = products;
        if (todayDateAndTithi != null && todayDateAndTithi.isNotEmpty) {
          _todayDateAndTithi = todayDateAndTithi;
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
    } on DioException catch (error) {
      debugPrint('Home API failed: ${error.message}');
    } catch (error) {
      debugPrint('Home API failed: $error');
    } finally {
      _isFetchingHome = false;
    }
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

    return list
        .map((raw) {
          if (raw is! Map) return null;
          final item = raw.map((k, v) => MapEntry(k.toString(), v));

          final title = (item['title'] ?? item['name'])?.toString().trim();

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
              clean(item['imageUrl']) ??
              clean(item['image']) ??
              clean(mediaImage);

          final resolvedImagePath = (image != null && image.isNotEmpty)
              ? image
              : fallbackImage;

          final placeholderText =
              useDatePlaceholderWhenImageMissing && resolvedImagePath.isEmpty
              ? DateFormatters.formatFestivalDate(item['date']?.toString())
              : null;
          final id = (item['_id'] ?? item['id'])?.toString().trim();
          final description = (item['description'] ?? item['purpose'])
              ?.toString()
              .trim();
          final date =
              (item['date'] ?? item['startDate'] ?? item['festivalDate'])
                  ?.toString()
                  .trim();

          return HomeCircleItem(
            title: (title == null || title.isEmpty) ? 'Untitled' : title,
            imagePath: resolvedImagePath,
            placeholderText: placeholderText,
            id: id == null || id.isEmpty ? null : id,
            description: description == null || description.isEmpty
                ? null
                : description,
            date: date == null || date.isEmpty ? null : date,
            raw: Map<String, dynamic>.from(item),
          );
        })
        .whereType<HomeCircleItem>()
        .toList();
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
    return Scaffold(
      backgroundColor: const Color(0xFFF2EBDC),
      extendBody: true,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _HomeTabContent(
            onScrollDirectionChanged: _onHomeScrollDirectionChanged,
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
            dayStreak: _dayStreak,
            onPoojasViewMore: _openPoojasTabFromViewMore,
            onPujaTap: _onPujaItemTap,
            onFestivalTap: _onFestivalItemTap,
          ),
          const PoojaKitPage(),
          const RitualListPage(),
          const CalendarPage(),
          const ProfilePage(),
        ],
      ),
      bottomNavigationBar: SizedBox(
        height: 94 + MediaQuery.paddingOf(context).bottom,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedSlide(
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
                    : SafeArea(
                        top: false,
                        bottom: true,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 0),
                          child: _BottomNavBar(
                            currentIndex: _currentIndex,
                            pageController: _pageController,
                            onTap: _onTabSelected,
                          ),
                        ),
                      ),
              ),
            ),
            Positioned(
              left: 0,
              bottom: MediaQuery.paddingOf(context).bottom + 26,
              child: _StickyShopButton(onTap: () => _onTabSelected(1)),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeTabContent extends StatefulWidget {
  const _HomeTabContent({
    required this.onScrollDirectionChanged,
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
    required this.dayStreak,
    required this.onPoojasViewMore,
    required this.onPujaTap,
    required this.onFestivalTap,
  });

  final ValueChanged<ScrollDirection> onScrollDirectionChanged;
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
  final int dayStreak;
  final Future<void> Function() onPoojasViewMore;
  final Future<void> Function(HomeCircleItem item) onPujaTap;
  final Future<void> Function(HomeCircleItem item) onFestivalTap;

  @override
  State<_HomeTabContent> createState() => _HomeTabContentState();
}

class _HomeTabContentState extends State<_HomeTabContent> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  bool _isSearching = false;
  bool _hasSearched = false;
  String? _searchError;
  List<_GlobalSearchResult> _searchResults = const [];

  bool get _isSearchMode =>
      _searchController.text.trim().length >= 2 ||
      _isSearching ||
      _hasSearched ||
      _searchError != null;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    final q = value.trim();
    if (q.length < 2) {
      setState(() {
        _isSearching = false;
        _hasSearched = false;
        _searchError = null;
        _searchResults = const [];
      });
      return;
    }
    setState(() {
      _isSearching = true;
      _hasSearched = false;
      _searchError = null;
      _searchResults = const [];
    });
    _searchDebounce = Timer(
      const Duration(milliseconds: 320),
      () => _search(q),
    );
  }

  Future<void> _search(String q) async {
    setState(() {
      _isSearching = true;
      _searchError = null;
    });
    try {
      final response = await Get.find<ApiClient>().dio.get<dynamic>(
        ApiEndpoints.search,
        queryParameters: {'q': q, 'limit': 8, 'maxTotal': 20},
      );
      if (!mounted || _searchController.text.trim() != q) return;
      setState(() {
        _hasSearched = true;
        _searchResults = _extractResults(response.data);
      });
    } on DioException catch (error) {
      if (!mounted || _searchController.text.trim() != q) return;
      setState(() {
        _hasSearched = true;
        _searchResults = const [];
        _searchError = _messageForSearchError(error);
      });
    } catch (_) {
      if (!mounted || _searchController.text.trim() != q) return;
      setState(() {
        _hasSearched = true;
        _searchResults = const [];
        _searchError = 'Search failed.';
      });
    } finally {
      if (mounted && _searchController.text.trim() == q) {
        setState(() => _isSearching = false);
      }
    }
  }

  List<_GlobalSearchResult> _extractResults(dynamic payload) {
    dynamic data = payload;
    if (payload is Map) {
      data = payload['data'] ?? payload;
      if (data is Map) {
        data =
            data['results'] ??
            data['items'] ??
            data['docs'] ??
            data['data'] ??
            data;
      }
    }
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((raw) => _GlobalSearchResult.fromJson(raw))
        .where((result) => result.title.isNotEmpty)
        .toList(growable: false);
  }

  String _messageForSearchError(DioException error) {
    final code = error.response?.statusCode;
    if (code == 404) {
      return 'Search is not available. Check that the app uses the latest API.';
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError) {
      return 'No connection. Check your network and try again.';
    }
    final data = error.response?.data;
    if (data is Map) {
      final msg = data['message'] ?? data['error'];
      if (msg != null && msg.toString().trim().isNotEmpty) {
        return msg.toString();
      }
    }
    return 'Search failed. Please try again.';
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();
    setState(() {
      _isSearching = false;
      _hasSearched = false;
      _searchError = null;
      _searchResults = const [];
    });
  }

  Future<void> _openSearchResult(_GlobalSearchResult result) async {
    FocusScope.of(context).unfocus();
    switch (result.type) {
      case 'pooja':
        if (result.id.isEmpty) return;
        await Get.toNamed<dynamic>(
          AppRoutes.ritualDetail,
          arguments: result.toDetailArgs(),
        );
        return;
      case 'deity':
        if (result.id.isEmpty) return;
        await Get.toNamed<dynamic>(
          AppRoutes.ritualDetail,
          arguments: result.toDeityArgs(),
        );
        return;
      case 'donation':
        if (result.id.isEmpty) return;
        await Get.toNamed<dynamic>(
          AppRoutes.userDonationDetails,
          arguments: Donation(
            id: result.id,
            title: result.title,
            description: result.description,
            imageUrl: result.imageUrl,
          ),
        );
        return;
      case 'festival':
        await widget.onOpenTab(3);
        return;
      case 'ritual':
      default:
        await widget.onOpenTab(2);
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<UserScrollNotification>(
      onNotification: (notification) {
        widget.onScrollDirectionChanged(notification.direction);
        return false;
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 120),
        child: Column(
          children: [
            _HomeHeader(
              isSearchMode: _isSearchMode,
              searchController: _searchController,
              onSearchChanged: _onSearchChanged,
              onSearchSubmitted: (value) {
                final q = value.trim();
                if (q.length >= 2) _search(q);
              },
              onClearSearch: _clearSearch,
              todayDateAndTithi: widget.todayDateAndTithi,
              dailySloka: widget.dailySloka,
              slokaAuthor: widget.slokaAuthor,
              slokaMeaning: widget.slokaMeaning,
              slokaContemplation: widget.slokaContemplation,
              slokaPrayer: widget.slokaPrayer,
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(0, 14, 0, 0),
              child: _isSearchMode
                  ? _GlobalSearchResultsSection(
                      isSearching: _isSearching,
                      error: _searchError,
                      results: _searchResults,
                      onResultTap: _openSearchResult,
                    )
                  : _HomeBodySections(
                      poojas: widget.poojas,
                      festivals: widget.festivals,
                      featuredProducts: widget.featuredProducts,
                      poojasCompleted: widget.poojasCompleted,
                      dayStreak: widget.dayStreak,
                      onPoojasViewMore: widget.onPoojasViewMore,
                      onPujaTap: widget.onPujaTap,
                      onFestivalTap: widget.onFestivalTap,
                    ),
            ),
            const SizedBox(height: 40),
            _Footer(),
            const SizedBox(height: 40),
          ],
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
    required this.dayStreak,
    required this.onPoojasViewMore,
    required this.onPujaTap,
    required this.onFestivalTap,
  });

  final List<HomeCircleItem> poojas;
  final List<HomeCircleItem> festivals;
  final List<ProductModel> featuredProducts;
  final int poojasCompleted;
  final int dayStreak;
  final Future<void> Function() onPoojasViewMore;
  final Future<void> Function(HomeCircleItem item) onPujaTap;
  final Future<void> Function(HomeCircleItem item) onFestivalTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
          child: _HomeCircleSection(
            title: 'Upcoming Puja',
            items: poojas,
            useWrap: false,
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
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
          child: _HomeCircleSection(
            title: 'Upcoming Festivals',
            items: festivals,
            useWrap: false,
            onItemTap: (item) => onFestivalTap(item),
          ),
        ),
        const SizedBox(height: 28),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
          child: _AchievementsSection(
            poojasCompleted: poojasCompleted,
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
    required this.dayStreak,
  });

  final int poojasCompleted;
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
                label: 'Poojas Completed',
              ),
            ),
            const SizedBox(width: 12),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xF8FFFFFF),
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
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF252525),
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.inter(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF7A746D),
              height: 1,
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
    this.onViewMoreTap,
    this.onItemTap,
  });

  final String title;
  final List<HomeCircleItem> items;
  final bool useWrap;
  final Future<void> Function()? onViewMoreTap;

  /// Optional per-item tap handler.
  final void Function(HomeCircleItem item)? onItemTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
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
                  onItemTap: onItemTap,
                  onViewMoreTap: onViewMoreTap,
                ),
        ],
      ),
    );
  }
}

class _BottomNavBar extends StatefulWidget {
  const _BottomNavBar({
    required this.currentIndex,
    required this.pageController,
    required this.onTap,
  });

  final int currentIndex;
  final PageController pageController;
  final Future<void> Function(int) onTap;
  static const int lastTabIndex = 4;

  @override
  State<_BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<_BottomNavBar> {
  double _dragPageValue = 0;
  bool _isDragging = false;
  bool _isSettling = false;

  @override
  void initState() {
    super.initState();
    _dragPageValue = widget.currentIndex.toDouble();
  }

  @override
  void didUpdateWidget(covariant _BottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isDragging && !_isSettling) {
      _dragPageValue = widget.currentIndex.toDouble();
    }
  }

  void _handleDragStart(DragStartDetails details) {
    if (_isSettling) return;
    _isDragging = true;
    _dragPageValue = widget.currentIndex.toDouble();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_isSettling) return;
    const tabWidth = 72.0;
    setState(() {
      _dragPageValue = (_dragPageValue - (details.delta.dx / tabWidth)).clamp(
        0.0,
        _BottomNavBar.lastTabIndex.toDouble(),
      );
    });
  }

  Future<void> _handleDragEnd(DragEndDetails details) async {
    final targetIndex = _dragPageValue.round().clamp(
      0,
      _BottomNavBar.lastTabIndex,
    );
    await _settleToIndex(targetIndex);
  }

  Future<void> _settleToIndex(int targetIndex) async {
    if (_isSettling) return;
    setState(() {
      _isSettling = true;
      _isDragging = false;
      _dragPageValue = targetIndex.toDouble();
    });
    await widget.onTap(targetIndex);
    if (!mounted) return;
    setState(() {
      _isSettling = false;
    });
  }

  double _tabTopOffset({required double centerX, required double totalWidth}) {
    final t = (centerX / totalWidth).clamp(0.0, 1.0);
    final curveY =
        ((1 - t) * (1 - t) * 24) + (2 * (1 - t) * t * -10) + (t * t * 24);
    // Map each tab center to the same convex arc as the nav shell.
    return 14 + ((curveY + 10) * 0.45);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 94,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const slotWidth =
              72.0; // Reduced slotWidth to fit 5 items comfortably
          const firstSlotLeft = 78.0;
          return AnimatedBuilder(
            animation: widget.pageController,
            builder: (context, _) {
              final pageValue = _isDragging
                  ? _dragPageValue
                  : _isSettling
                  ? _dragPageValue
                  : (widget.pageController.hasClients
                        ? (widget.pageController.page ??
                              widget.currentIndex.toDouble())
                        : widget.currentIndex.toDouble());
              // Shift tab slots with page progress for smooth tab swapping.
              final horizontalShift =
                  pageValue.clamp(0.0, _BottomNavBar.lastTabIndex.toDouble()) *
                  slotWidth;
              // The fixed Shop chip overlays this rail, so tabs intentionally
              // start underneath it and slide behind it while the rail moves.
              final homeLeft = firstSlotLeft - horizontalShift;
              final poojaKitLeft = homeLeft + slotWidth;
              final poojasLeft = poojaKitLeft + slotWidth;
              final calendarLeft = poojasLeft + slotWidth;
              final profileLeft = calendarLeft + slotWidth;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragStart: _handleDragStart,
                onHorizontalDragUpdate: _handleDragUpdate,
                onHorizontalDragEnd: _handleDragEnd,
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: PhysicalShape(
                        color: const Color(0xFFF8F1E2),
                        clipper: _ConvexNavClipper(),
                        elevation: 10,
                        shadowColor: const Color(0x24000000),
                        child: CustomPaint(
                          painter: _TopCurveHighlightPainter(),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                    Positioned(
                      top: _tabTopOffset(
                        centerX: homeLeft + (slotWidth / 2),
                        totalWidth: constraints.maxWidth,
                      ),
                      left: homeLeft,
                      width: slotWidth,
                      child: _BottomItem(
                        icon: Icons.home_outlined,
                        label: 'Home',
                        selected: widget.currentIndex == 0,
                        onTap: () => _settleToIndex(0),
                      ),
                    ),
                    Positioned(
                      top: _tabTopOffset(
                        centerX: poojaKitLeft + (slotWidth / 2),
                        totalWidth: constraints.maxWidth,
                      ),
                      left: poojaKitLeft,
                      width: slotWidth,
                      child: _BottomItem(
                        icon: Icons.shopping_bag_outlined,
                        label: 'Pooja Kit',
                        selected: widget.currentIndex == 1,
                        onTap: () => _settleToIndex(1),
                      ),
                    ),
                    Positioned(
                      top: _tabTopOffset(
                        centerX: poojasLeft + (slotWidth / 2),
                        totalWidth: constraints.maxWidth,
                      ),
                      left: poojasLeft,
                      width: slotWidth,
                      child: _BottomItem(
                        icon: Icons.local_fire_department_outlined,
                        label: 'Deities',
                        selected: widget.currentIndex == 2,
                        onTap: () => _settleToIndex(2),
                      ),
                    ),
                    Positioned(
                      top: _tabTopOffset(
                        centerX: calendarLeft + (slotWidth / 2),
                        totalWidth: constraints.maxWidth,
                      ),
                      left: calendarLeft,
                      width: slotWidth,
                      child: _BottomItem(
                        icon: Icons.calendar_today_outlined,
                        label: 'Calendar',
                        selected: widget.currentIndex == 3,
                        onTap: () => _settleToIndex(3),
                      ),
                    ),
                    Positioned(
                      top: _tabTopOffset(
                        centerX: profileLeft + (slotWidth / 2),
                        totalWidth: constraints.maxWidth,
                      ),
                      left: profileLeft,
                      width: slotWidth,
                      child: _BottomItem(
                        icon: Icons.person_outline,
                        label: 'Profile',
                        selected: widget.currentIndex == 4,
                        onTap: () => _settleToIndex(4),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.isSearchMode,
    required this.searchController,
    required this.onSearchChanged,
    required this.onSearchSubmitted,
    required this.onClearSearch,
    required this.todayDateAndTithi,
    required this.dailySloka,
    required this.slokaAuthor,
    required this.slokaMeaning,
    required this.slokaContemplation,
    required this.slokaPrayer,
  });

  final bool isSearchMode;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSearchSubmitted;
  final VoidCallback onClearSearch;
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
        // Search mode: content height + safe area; a fixed 240 caused Column overflow.
        final headerHeight = isSearchMode ? topInset + 250 : 500.0;

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
                          color: Colors.white,
                        ),
                        Spacer(),
                        Text(
                          todayDateAndTithi,
                          style: AppTypography.inter(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SvgPicture.asset(
                          'assets/svgs/bell.svg',
                          width: 18,
                          height: 18,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
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
                                  width: 48,
                                  height: 48,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
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
                                          color: Colors.white,
                                          width: 1.2,
                                        ),
                                      ),
                                      child: Text(
                                        count > 99 ? '99+' : '$count',
                                        style: AppTypography.inter(
                                          color: Colors.white,
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
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      displayName,
                      style: AppTypography.lora(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w400,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _GlobalSearchField(
                      controller: searchController,
                      onChanged: onSearchChanged,
                      onSubmitted: onSearchSubmitted,
                      onClear: onClearSearch,
                    ),
                    if (!isSearchMode) ...[
                      const SizedBox(height: 18),
                      const _HeaderDivider(),
                      const SizedBox(height: 12),
                      _QuoteCard(
                        quote: dailySloka,
                        author: slokaAuthor,
                        meaning: slokaMeaning,
                        contemplation: slokaContemplation,
                        prayer: slokaPrayer,
                      ),
                      const SizedBox(height: 12),
                      const _HeaderDivider(),
                    ],
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
          Text(
            'Sathya v1.2.0',
            style: AppTypography.inter(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            'Made with devotion for spiritual seekers by',
            style: AppTypography.lora(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Color(0XFF78716C),
            ),
          ),
          const SizedBox(height: 12),
          Image.asset(
            'assets/images/redin_consulting.png',
            width: 116,
            height: 32,
          ),
        ],
      ),
    );
  }
}

class _GlobalSearchField extends StatelessWidget {
  const _GlobalSearchField({
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final hasQuery = controller.text.trim().isNotEmpty;
    return Material(
      color: Colors.white,
      elevation: 3,
      shadowColor: const Color(0x22000000),
      borderRadius: BorderRadius.circular(16),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.search,
        style: AppTypography.inter(
          fontSize: 14,
          color: const Color(0xFF3D2B1F),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Search pujas, deities, festivals...',
          hintStyle: AppTypography.inter(
            fontSize: 13,
            color: const Color(0xFF9B8B7B),
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF183EA4), Color(0xFFE35600)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ).createShader(bounds),
            blendMode: BlendMode.srcIn,
            child: Icon(
              Icons.search_rounded,
              // color: Color(0xFF8E5C25),
              size: 22,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 44,
            minHeight: 48,
          ),
          suffixIcon: hasQuery
              ? ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF183EA4), Color(0xFFE35600)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ).createShader(bounds),
                  blendMode: BlendMode.srcIn,
                  child: IconButton(
                    onPressed: onClear,
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}

class _GlobalSearchResultsSection extends StatelessWidget {
  const _GlobalSearchResultsSection({
    required this.isSearching,
    required this.error,
    required this.results,
    required this.onResultTap,
  });

  final bool isSearching;
  final String? error;
  final List<_GlobalSearchResult> results;
  final Future<void> Function(_GlobalSearchResult result) onResultTap;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + 118),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Search Results',
            style: AppTypography.lora(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 12),
          if (isSearching && results.isEmpty)
            const SizedBox(
              height: 220,
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
              ),
            )
          else if (error != null)
            _SearchMessage(text: error!, height: 180)
          else if (results.isEmpty)
            const _SearchMessage(text: 'No results found.', height: 180)
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: results.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final result = results[index];
                return _GlobalSearchResultTile(
                  result: result,
                  onTap: () => onResultTap(result),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _SearchMessage extends StatelessWidget {
  const _SearchMessage({required this.text, this.height = 64});
  final String text;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Center(
        child: Text(
          text,
          style: AppTypography.inter(
            color: const Color(0xFF7A5A3D),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _GlobalSearchResultTile extends StatelessWidget {
  const _GlobalSearchResultTile({required this.result, required this.onTap});
  final _GlobalSearchResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              _SearchResultImage(result: result),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.inter(
                        fontSize: 14,
                        color: const Color(0xFF332218),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (result.description.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        result.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.inter(
                          fontSize: 11,
                          height: 1.25,
                          color: const Color(0xFF7B6A5A),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _SearchTypePill(type: result.typeLabel),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchResultImage extends StatelessWidget {
  const _SearchResultImage({required this.result});
  final _GlobalSearchResult result;

  @override
  Widget build(BuildContext context) {
    final imageUrl = result.imageUrl?.trim() ?? '';
    final placeholder = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFF3E2C3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(result.icon, size: 22, color: const Color(0xFF8E5C25)),
    );
    if (imageUrl.isEmpty) return placeholder;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        imageUrl,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => placeholder,
      ),
    );
  }
}

class _SearchTypePill extends StatelessWidget {
  const _SearchTypePill({required this.type});
  final String type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF4E6CC),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        type,
        style: AppTypography.inter(
          fontSize: 10,
          color: const Color(0xFF8E5C25),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _GlobalSearchResult {
  const _GlobalSearchResult({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.raw,
  });

  factory _GlobalSearchResult.fromJson(Map<dynamic, dynamic> json) {
    final normalized = json.map(
      (key, value) => MapEntry(key.toString(), value),
    );
    String valueOf(List<String> keys) {
      for (final key in keys) {
        final value = normalized[key];
        if (value == null || value is Map || value is List) continue;
        final text = value.toString().trim();
        if (text.isNotEmpty) return text;
      }
      return '';
    }

    return _GlobalSearchResult(
      id: valueOf(['id', '_id']),
      type: valueOf(['type']).toLowerCase(),
      title: valueOf(['title', 'name']),
      description: valueOf(['description']),
      imageUrl: valueOf(['imageUrl', 'image']).isEmpty
          ? null
          : valueOf(['imageUrl', 'image']),
      raw: Map<String, dynamic>.from(normalized),
    );
  }

  final String id;
  final String type;
  final String title;
  final String description;
  final String? imageUrl;
  final Map<String, dynamic> raw;

  String get typeLabel {
    if (type.isEmpty) return 'result';
    return type[0].toUpperCase() + type.substring(1);
  }

  IconData get icon {
    switch (type) {
      case 'donation':
        return Icons.volunteer_activism_outlined;
      case 'festival':
        return Icons.event_available_outlined;
      case 'ritual':
        return Icons.local_fire_department_outlined;
      case 'deity':
        return Icons.temple_hindu_outlined;
      case 'pooja':
      default:
        return Icons.spa_outlined;
    }
  }

  Map<String, dynamic> toDetailArgs() => {
    ...raw,
    '_id': id,
    'id': id,
    'title': title,
    'description': description,
    if (imageUrl != null) 'imageUrl': imageUrl,
  };

  Map<String, dynamic> toDeityArgs() => {
    'type': 'deity',
    ...toDetailArgs(),
    'name': title,
    if (imageUrl != null)
      'media': {
        'images': [imageUrl],
      },
  };
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
  int _selectedTab = 0;

  static const double _cardRadius = 16;
  static const double _flowerSize = 100;
  static const double _horizontalAttach = 22;
  static const double _tabHeight = 40;
  static const double _contentHeight = 122;

  String get _tabText {
    switch (_selectedTab) {
      case 1:
        return widget.contemplation.trim().isNotEmpty
            ? widget.contemplation.trim()
            : 'No contemplation available.';
      case 2:
        return widget.prayer.trim().isNotEmpty
            ? widget.prayer.trim()
            : 'No prayer available.';
      case 0:
      default:
        return widget.meaning.trim().isNotEmpty
            ? widget.meaning.trim()
            : widget.quote;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SizedBox(
        width: double.infinity,
        height: _tabHeight + _contentHeight + 6,
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
                        onTap: () => setState(() => _selectedTab = 0),
                      ),
                    ),
                    Expanded(
                      child: _SlokaTabBtn(
                        label: 'Contemplation',
                        selected: _selectedTab == 1,
                        onTap: () => setState(() => _selectedTab = 1),
                      ),
                    ),
                    Expanded(
                      child: _SlokaTabBtn(
                        label: 'Prayer',
                        selected: _selectedTab == 2,
                        onTap: () => setState(() => _selectedTab = 2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
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
                              color: Colors.white,
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
    const selectedBorder = Color(0xFFFFEF11);
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
                color: selected ? Colors.white : const Color(0x99FFFFFF),
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                height: 1,
              ),
            ),
          ),
          if (selected)
            const Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: selectedBorder, width: 1.4),
                      right: BorderSide(color: selectedBorder, width: 1.4),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
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
  const _CircleRow({required this.items, this.onViewMoreTap, this.onItemTap});
  final List<HomeCircleItem> items;
  final Future<void> Function()? onViewMoreTap;
  final void Function(HomeCircleItem item)? onItemTap;

  bool _isMoreTitle(String title) {
    final normalized = title.trim().toLowerCase().replaceAll('\n', ' ');
    return normalized == 'view more' || normalized == 'more';
  }

  @override
  Widget build(BuildContext context) {
    final baseItems = items.where((item) => !_isMoreTitle(item.title)).toList();
    const staticViewMoreItem = HomeCircleItem(
      title: 'View\nMore',
      imagePath: 'assets/images/home/morePoojas.png',
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
  const _CircleItem({required this.item, this.onTap});
  final HomeCircleItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final normalizedTitle = item.title.trim().toLowerCase().replaceAll(
      '\n',
      ' ',
    );
    final isMoreItem =
        normalizedTitle == 'view more' || normalizedTitle == 'more';
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
                color: Colors.white,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: ClipOval(
                child: item.imagePath.isEmpty
                    ? ColoredBox(
                        color: const Color(0xFFEADCC3),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              item.placeholderText ?? '',
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.inter(
                                fontSize: 10,
                                color: const Color(0xFF4A1C00),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      )
                    : item.imagePath.startsWith('http')
                    ? Image.network(
                        item.imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const ColoredBox(color: Color(0xFFE7D7BC));
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
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(10)),
        child: Ink(
          height: 42,
          padding: const EdgeInsets.only(left: 16, right: 18),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF183EA4), Color(0xFFE35600)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.horizontal(right: Radius.circular(10)),
            boxShadow: [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 12,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Center(
            child: Text(
              'Shop',
              style: AppTypography.inter(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  const _BottomItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = const Color(0xFF7F776D);
    final isProfile = label.trim().toLowerCase() == 'profile';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 56,
        child: AnimatedScale(
          scale: selected ? 1.08 : 1,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isProfile)
                Container(
                  width: selected ? 32 : 26,
                  height: selected ? 32 : 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected
                        ? Colors.white.withOpacity(0.14)
                        : Colors.transparent,
                    border: Border.all(
                      color: selected
                          ? const Color(0xFFF2C94C)
                          : Colors.transparent,
                      width: 1.2,
                    ),
                  ),
                  child: Center(
                    child: selected
                        ? ShaderMask(
                            shaderCallback: (bounds) =>
                                const LinearGradient(
                              colors: [Color(0xFF183EA4), Color(0xFFE35600)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(bounds),
                            blendMode: BlendMode.srcIn,
                            child: Icon(icon, size: 22, color: Colors.white),
                          )
                        : Icon(icon, size: 18, color: color),
                  ),
                )
              else
                (selected
                    ? ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFF183EA4), Color(0xFFE35600)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        blendMode: BlendMode.srcIn,
                        child: Icon(icon, size: 26, color: Colors.white),
                      )
                    : Icon(icon, size: 20, color: color)),
              const SizedBox(height: 2),
              selected
                  ? ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFF183EA4), Color(0xFFE35600)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ).createShader(bounds),
                      blendMode: BlendMode.srcIn,
                      child: Text(
                        label,
                        style: AppTypography.inter(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : Text(
                      label,
                      style: AppTypography.inter(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConvexNavClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()..moveTo(0, 24);
    path.quadraticBezierTo(size.width * 0.5, -10, size.width, 24);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _TopCurveHighlightPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, 28);
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0x00F7B25A), Color(0x90F29A37), Color(0x00F7B25A)],
        stops: [0.3, 0.5, 0.7],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..isAntiAlias = true;
    final path = Path()
      ..moveTo(0, 24)
      ..quadraticBezierTo(size.width * 0.5, -10, size.width, 24);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
                  onAddToCartTap: () => cartCtrl.addToCart(product.id),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
