import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/features/home/data/home_constants.dart';
import 'package:satya_devotte_app/features/profile/presentation/pages/profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (_currentIndex == index) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2EBDC),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) => setState(() => _currentIndex = index),
          children: [
          _HomeTabContent(),
          _SimpleTabPage(
            icon: Icons.local_fire_department_outlined,
            title: 'Poojas',
          ),
          _SimpleTabPage(
            icon: Icons.calendar_today_outlined,
            title: 'Calendar',
          ),
          const ProfilePage(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: _BottomNavBar(
            currentIndex: _currentIndex,
            pageController: _pageController,
            onTap: _onTabSelected,
          ),
        ),
      ),
    );
  }
}

class _HomeTabContent extends StatelessWidget {
  const _HomeTabContent();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 0),
      child: Column(
        children: [
          _HomeHeader(),
          const Padding(
            padding: EdgeInsets.fromLTRB(0, 14, 0, 0),
            child: _HomeBodySections(),
          ),
        ],
      ),
    );
  }
}

class _HomeBodySections extends StatelessWidget {
  const _HomeBodySections();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
          child: _HomeCircleSection(
            title: 'Upcoming Pooja',
            items: HomeConstants.upcomingPooja,
          ),
        ),
        SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
          child: _HomeCircleSection(
            title: 'Upcoming Festivals',
            items: HomeConstants.upcomingFestivals,
          ),
        ),
        SizedBox(height: 10),
        _DonationsContainer(),
      ],
    );
  }
}

class _DonationsContainer extends StatelessWidget {
  const _DonationsContainer();

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
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HomeCircleSection(
                    title: 'Donations',
                    items: HomeConstants.donations,
                    useWrap: true,
                  ),
                ],
              ),
            ),
            Stack(
              alignment: Alignment.topCenter,
              children: const [
                // Decorative texture behind the donation CTA area.
                Image(
                  image: AssetImage('assets/images/flowerImg.png'),
                  width: 180,
                  height: 180,
                  fit: BoxFit.cover,
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(10, 35, 10, 12),
                  child: _DonationBannerCard(),
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
  });

  final String title;
  final List<HomeCircleItem> items;
  final bool useWrap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: title),
          useWrap ? _CircleWrap(items: items) : _CircleRow(items: items),
        ],
      ),
    );
  }
}

class _DonationBannerCard extends StatelessWidget {
  const _DonationBannerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
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
              padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
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
  }
}
class _SimpleTabPage extends StatelessWidget {
  const _SimpleTabPage({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28, color: const Color(0xFF8C8575)),
          const SizedBox(height: 10),
          Text(
            '$title screen',
            style: const TextStyle(
              color: Color(0xFF8C8575),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({
    required this.currentIndex,
    required this.pageController,
    required this.onTap,
  });

  final int currentIndex;
  final PageController pageController;
  final ValueChanged<int> onTap;
  static const int _lastTabIndex = 3;

  void _handleSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity < -120 && currentIndex < _lastTabIndex) {
      onTap(currentIndex + 1);
      return;
    }
    if (velocity > 120 && currentIndex > 0) {
      onTap(currentIndex - 1);
    }
  }

  double _tabTopOffset({
    required double centerX,
    required double totalWidth,
  }) {
    final t = (centerX / totalWidth).clamp(0.0, 1.0);
    final curveY = ((1 - t) * (1 - t) * 24) + (2 * (1 - t) * t * -10) + (t * t * 24);
    // Map each tab center to the same convex arc as the nav shell.
    return 14 + ((curveY + 10) * 0.45);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 94,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const slotWidth = 90.0;
          const railWidth = slotWidth * 6;
          final railLeft = (constraints.maxWidth - railWidth) / 2;
          return AnimatedBuilder(
            animation: pageController,
            builder: (context, _) {
              final pageValue = pageController.hasClients
                  ? (pageController.page ?? currentIndex.toDouble())
                  : currentIndex.toDouble();
              // Shift tab slots with page progress for smooth tab swapping.
              final horizontalShift =
                  pageValue.clamp(0.0, _lastTabIndex.toDouble()) * slotWidth;
              final homeLeft = (railLeft + (slotWidth * 2)) - horizontalShift;
              final poojasLeft = (railLeft + (slotWidth * 3)) - horizontalShift;
              final calendarLeft = (railLeft + (slotWidth * 4)) - horizontalShift;
              final profileLeft = (railLeft + (slotWidth * 5)) - horizontalShift;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragEnd: _handleSwipe,
                child: Stack(
                  children: [
                Positioned(
                  top: 12,
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
                    selected: currentIndex == 0,
                    onTap: () => onTap(0),
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
                    label: 'Poojas',
                    selected: currentIndex == 1,
                    onTap: () => onTap(1),
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
                    selected: currentIndex == 2,
                    onTap: () => onTap(2),
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
                    selected: currentIndex == 3,
                    onTap: () => onTap(3),
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
  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return SizedBox(
      width: double.infinity,
      height: 500,
      child: Stack(
        children: [
          const Positioned.fill(
            child: Image(
              image: AssetImage('assets/images/home/homeHeaderImg.png'),
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          Positioned(
            top: 0,
            right: -2,
            child: Opacity(
              opacity: 0.95,
              child: const Image(
              image: AssetImage('assets/images/home/homeHeaderFlower.png'),
                width: 178,
                height: 120,
              fit: BoxFit.contain,
              ),
            ),
          ),
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
                      colorFilter:
                          const ColorFilter.mode(Colors.white, BlendMode.srcIn),
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
                  HomeConstants.userName,
                  style: AppTypography.lora(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w400,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 55),
                const _HeaderDivider(),
                const SizedBox(height: 12),
                const _QuoteCard(),
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

class _QuoteCard extends StatelessWidget {
  const _QuoteCard();

  static const double _cardRadius = 16;
  static const double _flowerSize = 100;
  static const double _horizontalAttach = 22;
  static const double _cardHeight = 150;

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
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      HomeConstants.quote,
                      style: AppTypography.lora(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 0),
                    Text(
                      HomeConstants.quoteSubtext,
                      style: AppTypography.inter(
                        color: Color(0xFFEDE0D9),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                    Text(
                      '- Bhagavad Gita',
                      style: AppTypography.lora(
                        color: Color(0xFFF0E5DE),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                      ),
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
  const _CircleRow({required this.items});
  final List<HomeCircleItem> items;

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
                child: _CircleItem(item: item),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _CircleWrap extends StatelessWidget {
  const _CircleWrap({required this.items});
  final List<HomeCircleItem> items;

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
            .map((item) => _CircleItem(item: item))
            .toList(),
      ),
    );
  }
}

class _CircleItem extends StatelessWidget {
  const _CircleItem({required this.item});
  final HomeCircleItem item;

  @override
  Widget build(BuildContext context) {
    final normalizedTitle = item.title.trim().toLowerCase().replaceAll('\n', ' ');
    final isMoreItem = normalizedTitle == 'view more' || normalizedTitle == 'more';
    return SizedBox(
      width: 80,
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
              child: Image(
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

