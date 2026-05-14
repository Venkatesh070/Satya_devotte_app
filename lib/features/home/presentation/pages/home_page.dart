import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/core/network/api_client.dart';
import 'package:satya_devotte_app/core/network/api_endpoints.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/core/utils/date_formatters.dart';
import 'package:satya_devotte_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:satya_devotte_app/features/calendar/presentation/pages/calendar_page.dart';
import 'package:satya_devotte_app/features/donations/data/models/donation.dart';
import 'package:satya_devotte_app/features/donations/presentation/pages/donate_amount_sheet.dart';
import 'package:satya_devotte_app/features/home/data/home_constants.dart';
import 'package:satya_devotte_app/features/profile/presentation/controllers/profile_controller.dart';
import 'package:satya_devotte_app/features/profile/presentation/pages/profile_page.dart';
import 'package:satya_devotte_app/features/poojakit/presentation/pages/poojakit_page.dart';
import 'package:satya_devotte_app/features/poojakit/state/cart_controller.dart';
import 'package:satya_devotte_app/features/cms/models/product_model.dart';
import 'package:satya_devotte_app/features/cms/data/datasources/product_remote_datasource.dart';
import 'package:satya_devotte_app/features/poojakit/presentation/pages/poojakit_page.dart';
import 'package:satya_devotte_app/features/cms/models/product_model.dart';
import 'package:satya_devotte_app/features/cms/data/datasources/product_remote_datasource.dart';
import 'package:satya_devotte_app/features/pujas/presentation/pages/puja_list_page.dart';
import 'package:satya_devotte_app/shared/components/section_title.dart';
import 'package:satya_devotte_app/shared/components/section_title.dart';
import 'package:satya_devotte_app/shared/widgets/app_background.dart';
import 'package:satya_devotte_app/shared/widgets/product_card.dart';
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
  String _dailySloka = HomeConstants.quote;
  String _slokaAuthor = '- Bhagavad Gita';
  String _slokaMeaning = '';
  String _slokaContemplation = '';
  String _slokaPrayer = '';
  List<HomeCircleItem> _poojas = HomeConstants.upcomingPooja;
  List<HomeCircleItem> _festivals = HomeConstants.upcomingFestivals;
  List<HomeCircleItem> _donations = HomeConstants.donations;
  List<ProductModel> _featuredProducts = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _fetchHomeDataIfNeeded();
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
    }
    _isAnimatingToTab = false;
  }

  Future<void> _openPoojasTabFromViewMore() async {
    await Get.toNamed(AppRoutes.rituals);
  }

  /// Tap on a single donation circle on the Home screen.
  /// If the backend gave us a real `_id` we navigate straight to the
  /// donation flow; otherwise we fall back to the full donations list.
  void _onDonationItemTap(HomeCircleItem item) {
    final id = item.id?.trim() ?? '';
    if (id.isEmpty) {
      _openDonationsList();
      return;
    }
    final donation = Donation(
      id: id,
      title: item.title.replaceAll('\n', ' ').trim(),
      description: item.description?.trim() ?? '',
      imageUrl: item.imagePath.startsWith('http') ? item.imagePath : null,
    );
    // Two equally valid entry points — open the amount sheet directly so
    // the user can donate in one tap. Power users can still browse all
    // donations via the "More" tile.
    DonateAmountSheet.show(context, donation: donation);
  }

  Future<void> _openDonationsList() async {
    await Get.toNamed(AppRoutes.userDonations);
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
      final donationsData = data['donations'];

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
      final parsedDonations = _mapHomeItems(
        donationsData,
        fallbackImage: 'assets/images/home/moreDonations.png',
      );

      if (!mounted) return;
      setState(() {
        _featuredProducts = products;
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
        if (parsedDonations.isNotEmpty) {
          _donations = parsedDonations;
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

          final title = item['title']?.toString().trim();

          // Clean URL: remove spaces and backticks
          String? _clean(dynamic v) {
            final s = v?.toString().trim() ?? '';
            if (s.isEmpty) return null;
            return s.replaceAll('`', '').trim();
          }

          final image = _clean(item['imageUrl']) ?? _clean(item['image']);

          final resolvedImagePath = (image != null && image.isNotEmpty)
              ? image
              : fallbackImage;

          final placeholderText =
              useDatePlaceholderWhenImageMissing && resolvedImagePath.isEmpty
              ? DateFormatters.formatFestivalDate(item['date']?.toString())
              : null;

          return HomeCircleItem(
            title: (title == null || title.isEmpty) ? 'Untitled' : title,
            imagePath: resolvedImagePath,
            placeholderText: placeholderText,
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
            dailySloka: _dailySloka,
            slokaAuthor: _slokaAuthor,
            slokaMeaning: _slokaMeaning,
            slokaContemplation: _slokaContemplation,
            slokaPrayer: _slokaPrayer,
            poojas: _poojas,
            festivals: _festivals,
            donations: _donations,
            featuredProducts: _featuredProducts,
            onPoojasViewMore: _openPoojasTabFromViewMore,
            onDonationTap: _onDonationItemTap,
            onDonationsViewMore: _openDonationsList,
          ),
          const PoojaKitPage(),
          const RitualListPage(),
          const CalendarPage(),
          const ProfilePage(),
        ],
      ),
      bottomNavigationBar: AnimatedSlide(
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
    );
  }
}

class _HomeTabContent extends StatelessWidget {
  const _HomeTabContent({
    required this.onScrollDirectionChanged,
    required this.dailySloka,
    required this.slokaAuthor,
    required this.slokaMeaning,
    required this.slokaContemplation,
    required this.slokaPrayer,
    required this.poojas,
    required this.festivals,
    required this.donations,
    required this.featuredProducts,
    required this.onPoojasViewMore,
    required this.onDonationTap,
    required this.onDonationsViewMore,
  });

  final ValueChanged<ScrollDirection> onScrollDirectionChanged;
  final String dailySloka;
  final String slokaAuthor;
  final String slokaMeaning;
  final String slokaContemplation;
  final String slokaPrayer;
  final List<HomeCircleItem> poojas;
  final List<HomeCircleItem> festivals;
  final List<HomeCircleItem> donations;
  final List<ProductModel> featuredProducts;
  final Future<void> Function() onPoojasViewMore;
  final void Function(HomeCircleItem item) onDonationTap;
  final Future<void> Function() onDonationsViewMore;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<UserScrollNotification>(
      onNotification: (notification) {
        onScrollDirectionChanged(notification.direction);
        return false;
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 0),
        child: Column(
          children: [
            _HomeHeader(
              dailySloka: dailySloka,
              slokaAuthor: slokaAuthor,
              slokaMeaning: slokaMeaning,
              slokaContemplation: slokaContemplation,
              slokaPrayer: slokaPrayer,
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(0, 14, 0, 0),
              child: _HomeBodySections(
                poojas: poojas,
                festivals: festivals,
                donations: donations,
                featuredProducts: featuredProducts,
                onPoojasViewMore: onPoojasViewMore,
                onDonationTap: onDonationTap,
                onDonationsViewMore: onDonationsViewMore,
              ),
            ),
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
    required this.donations,
    required this.featuredProducts,
    required this.onPoojasViewMore,
    required this.onDonationTap,
    required this.onDonationsViewMore,
  });

  final List<HomeCircleItem> poojas;
  final List<HomeCircleItem> festivals;
  final List<HomeCircleItem> donations;
  final List<ProductModel> featuredProducts;
  final Future<void> Function() onPoojasViewMore;

  /// Triggered when a real donation tile is tapped on the Home screen.
  final void Function(HomeCircleItem item) onDonationTap;

  /// Triggered by the trailing "More" tile inside the donations wrap
  /// and by the "Make a Donation" CTA banner.
  final Future<void> Function() onDonationsViewMore;

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
            onViewMoreTap: onPoojasViewMore,
          ),
        ),
        if (featuredProducts.isNotEmpty) ...[
          const SizedBox(height: 16),
          _FeaturedProductsSection(products: featuredProducts),
        ],
        SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
          child: _HomeCircleSection(
            title: 'Upcoming Festivals',
            items: festivals,
          ),
        ),
        SizedBox(height: 10),
        _DonationsContainer(
          items: donations,
          onItemTap: onDonationTap,
          onMoreTap: onDonationsViewMore,
        ),
      ],
    );
  }
}

class _DonationsContainer extends StatelessWidget {
  const _DonationsContainer({
    required this.items,
    required this.onItemTap,
    required this.onMoreTap,
  });

  final List<HomeCircleItem> items;
  final void Function(HomeCircleItem item) onItemTap;
  final Future<void> Function() onMoreTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        color: AppColors.donationBgColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HomeCircleSection(
                    title: 'Donations',
                    items: items,
                    useWrap: true,
                    onItemTap: onItemTap,
                    onViewMoreTap: onMoreTap,
                  ),
                ],
              ),
            ),
            Stack(
              alignment: Alignment.topCenter,
              children: [
                // Decorative texture behind the donation CTA area.
                const Image(
                  image: AssetImage('assets/images/flowerImg.png'),
                  width: 180,
                  height: 180,
                  fit: BoxFit.cover,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 35, 10, 12),
                  child: _DonationBannerCard(onTap: onMoreTap),
                ),
              ],
            ),
          ],
        ),
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

  /// Optional per-item tap handler. Currently used by the Donations wrap
  /// to deep-link into the donation flow.
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
              : _CircleRow(items: items, onViewMoreTap: onViewMoreTap),
        ],
      ),
    );
  }
}

class _DonationBannerCard extends StatelessWidget {
  const _DonationBannerCard({this.onTap});

  final Future<void> Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFB10F33), Color(0xFF8E0B2A)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0x22FFFFFF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.volunteer_activism_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Make a Donation',
                    style: AppTypography.lora(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Support noble causes\n& earn blessings',
                    style: AppTypography.inter(
                      color: const Color(0xFFFDE7EC),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0x26FFFFFF),
            ),
            child: const Icon(
              Icons.chevron_right,
              color: Colors.white,
              size: 22,
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTap!(),
        borderRadius: BorderRadius.circular(20),
        child: card,
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
          const railWidth = slotWidth * 7;
          final railLeft = (constraints.maxWidth - railWidth) / 2;
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
              // Offset by half-slot so active tab center aligns with screen center.
              final homeLeft = (railLeft + (slotWidth * 2.5)) - horizontalShift;
              final poojaKitLeft =
                  (railLeft + (slotWidth * 3.5)) - horizontalShift;
              final poojasLeft =
                  (railLeft + (slotWidth * 4.5)) - horizontalShift;
              final calendarLeft =
                  (railLeft + (slotWidth * 5.5)) - horizontalShift;
              final profileLeft =
                  (railLeft + (slotWidth * 6.5)) - horizontalShift;
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
    required this.dailySloka,
    required this.slokaAuthor,
    required this.slokaMeaning,
    required this.slokaContemplation,
    required this.slokaPrayer,
  });

  final String dailySloka;
  final String slokaAuthor;
  final String slokaMeaning;
  final String slokaContemplation;
  final String slokaPrayer;

  @override
  Widget build(BuildContext context) {
    final profileController = Get.find<ProfileController>();

    final sessionUser = profileController.sessionUser;
    final profile = profileController.profile;

    final userData =
        sessionUser ?? profile?['user'] as Map<String, dynamic>? ?? profile;
    debugPrint('HomeHeader userData: $userData');
    final userName = userData?['name'] ?? userData?['email'] ?? 'User';
    final topInset = MediaQuery.paddingOf(context).top;

    return SizedBox(
      width: double.infinity,
      height: 500,
      child: Stack(
        children: [
          const Positioned.fill(
            child: Image(
              image: AssetImage('assets/images/appHeaderImg.png'),
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
                      HomeConstants.dateAndTithi,
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
                  ],
                ),
                const SizedBox(height: 30),
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
                  userName.split('@')[0],
                  style: AppTypography.lora(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w400,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 20),
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
            ),
          ),
        ],
      ),
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
  static const double _cardHeight = 172;

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
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0x2EFFFFFF),
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: const Color(0x2EFFFFFF)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_cardRadius),
        child: SizedBox(
          height: _cardHeight,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // Corner motifs are clipped to the same radius as the quote card.
              Positioned(
                top: 0,
                left: -_horizontalAttach,
                child: Opacity(
                  opacity: 0.22,
                  child: Image(
                    image: AssetImage('assets/images/home/cardFlower.png'),
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
                      image: AssetImage('assets/images/home/cardFlower.png'),
                      width: _flowerSize,
                      height: _flowerSize,
                    ),
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Expanded(
                        child: Center(
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
                      const SizedBox(height: 8),
                      // Text(
                      //   _selectedTab == 0 ? 'Meaning' : _selectedTab == 1 ? 'Contemplation' : 'Prayer / Resolve',
                      //   maxLines: 1,
                      //   overflow: TextOverflow.ellipsis,
                      //   style: AppTypography.lora(
                      //     color: const Color(0xFFF0E5DE),
                      //     fontSize: 12,
                      //     fontStyle: FontStyle.italic,
                      //     fontWeight: FontWeight.w500,
                      //   ),
                      // ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _SlokaTabBtn(
                            label: 'Meaning',
                            selected: _selectedTab == 0,
                            onTap: () => setState(() => _selectedTab = 0),
                          ),
                          _SlokaTabBtn(
                            label: 'Contemplation',
                            selected: _selectedTab == 1,
                            onTap: () => setState(() => _selectedTab = 1),
                          ),
                          _SlokaTabBtn(
                            label: 'Prayer / Resolve',
                            selected: _selectedTab == 2,
                            onTap: () => setState(() => _selectedTab = 2),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: selected ? Colors.white.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected ? Colors.white.withOpacity(0.5) : Colors.transparent,
        ),
      ),
      child: Text(
        label,
        style: AppTypography.inter(
          color: Colors.white,
          fontSize: 10,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    ),
  );
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
          fontWeight: FontWeight.w800,
          color: const Color(0xFF333333),
        ),
      ),
    );
  }
}

class _CircleRow extends StatelessWidget {
  const _CircleRow({required this.items, this.onViewMoreTap});
  final List<HomeCircleItem> items;
  final Future<void> Function()? onViewMoreTap;

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
                      : null,
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
              selected
                  ? ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFF183EA4), Color(0xFFE35600)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      blendMode: BlendMode.srcIn,
                      child: Icon(icon, size: 26, color: Colors.white),
                    )
                  : Icon(icon, size: 20, color: color),
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
