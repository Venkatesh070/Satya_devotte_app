import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/core/services/app_music_service.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';
import 'package:satya_devotte_app/shared/widgets/custom_button.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late final AnimationController _rotationController;
  int _currentIndex = 0;

  static const _slides = [
    (
      title: 'Welcome to Sathya',
      subtitle:
          'Your spiritual companion for Hindu rituals\nand divine practices',
    ),
    (
      title: 'Guided Rituals',
      subtitle:
          'Step-by-step instructions for every pooja,\nfrom preparation to completion',
    ),
    (
      title: 'Never Miss a Festival',
      subtitle: 'Get reminded about auspicious days and\nupcoming celebrations',
    ),
    
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
    if (!kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.find<AppMusicService>().start();
      });
    }
  }

  void _goNext() {
    if (_currentIndex == _slides.length - 1) {
      Get.offAllNamed(AppRoutes.login);
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _rotationController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarDividerColor: Colors.black,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: const Color(0xFF17191E),
        body: Stack(
          children: [
            Positioned.fill(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/onBoardBg3.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: -200,
                    left: 0,
                    right: 0,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: AnimatedBuilder(
                        animation: _rotationController,
                        builder: (context, child) {
                          final spin = _rotationController.value * 2 * math.pi;
                          return Transform.rotate(
                            angle: spin,
                            child: child,
                          );
                        },
                        child: Image.asset(
                          'assets/images/flowerImg.png',
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Opacity(
                      opacity:1,
                      child: ImageFiltered(
                        imageFilter: ui.ImageFilter.blur(sigmaX: 64, sigmaY: 64),
                        child: SizedBox(
                          width: 294.69,
                          height: 294.69,
                          child: Image.asset(
                            'assets/images/onBoardRightCorner.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Transform.translate(
                      offset: const Offset(0, -55),
                      child: AnimatedBuilder(
                        animation: _rotationController,
                        builder: (context, child) {
                          final spin = _rotationController.value * 2 * math.pi;
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              Transform.rotate(
                                angle: spin,
                                child: Image.asset(
                                  'assets/images/chakra1.png',
                                  filterQuality: FilterQuality.high,
                                ),
                              ),
                              Transform.rotate(
                                angle: -spin,
                                child: Transform.scale(
                                  scale: 0.90,
                                  child: Image.asset(
                                    'assets/images/chakra2.png',
                                    filterQuality: FilterQuality.high,
                                  ),
                                ),
                              ),
                         Transform.rotate(
                                angle: spin,
                                child: Transform.scale(
                                  scale: 0.80,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Image.asset(
                                        'assets/images/chakra3.png',
                                        filterQuality: FilterQuality.high,
                                      ),

                                    ],
                                  ),
                                ),
                              ),
                             Transform.rotate(
                                angle: -spin,
                                child: Transform.scale(
                                  scale: 0.53,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Image.asset(
                                        'assets/images/chakra4.png',
                                        filterQuality: FilterQuality.high,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                             Opacity(
                                          opacity: 0.8,
                                          child:  Image.asset(
                                            'assets/images/onBoardBgOverlay.png',
                                            filterQuality: FilterQuality.high,
                                          ),
                                        ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: topInset + 14,
              left: 14,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _currentIndex > 0 ? 1 : 0,
                child: IgnorePointer(
                  ignoring: _currentIndex == 0,
                  child: Material(
                    color: const Color(0xFFE9EAEC),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => _pageController.previousPage(
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeOut,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(9),
                        child: Icon(Icons.arrow_back, size: 18),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: topInset + 24,
              right: 22,
              child: GestureDetector(
                onTap: () => Get.offAllNamed(AppRoutes.login),
                child: const Text(
                  'Skip >>',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.sizeOf(context).height * 0.365,
              left: 0,
              right: 0,
              child: Center(
                child: SvgPicture.asset(
                  'assets/svgs/whiteLogo.svg',
                  width: 93,
                  height: 112,
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.sizeOf(context).height * 0.36 + 132,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 230,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (index) =>
                      setState(() => _currentIndex = index),
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            slide.title,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontSize: 24,
                                  height: 32 / 24,
                                  shadows: [
                                    Shadow(
                                      color: const Color.fromARGB(255, 242, 237, 237).withValues(alpha: 0.25),
                                      offset: const Offset(0, 1),
                                      blurRadius: 8,
                                    ),
                                  ],
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 15),
                          Text(
                            slide.subtitle,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  height: 1.35,
                                ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                child: Image.asset(
                  'assets/images/onBoardFooter.png',
                  width: MediaQuery.sizeOf(context).width,
                  fit: BoxFit.fitWidth,
                  alignment: Alignment.bottomCenter,
                ),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.translate(
                        offset: const Offset(0, -120),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_slides.length, (i) {
                            final isActive = i == _currentIndex;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              height: 6,
                              width: isActive ? 18 : 6,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                color: isActive
                                    ? AppColors.white
                                    : AppColors.white.withValues(alpha: 0.4),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 18),
                      CustomButton(
                        gradientColors: [AppColors.white, AppColors.white],
                        textColor: AppColors.black,
                        label: _currentIndex == _slides.length - 1
                            ? 'Get started'
                            : 'Next',
                        onTap: _goNext,
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
