import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/config/routes/app_routes.dart';
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
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: const Color(0xFFF2EBDC),
        body: Stack(
          children: [
            Positioned(
              top: -30,
              left: 0,
              right: 0,
              child: Image.asset(
                'assets/images/appHeaderImg.png.png',
                fit: BoxFit.fitWidth,
                width: double.infinity,
              ),
            ),
            Positioned(
              top: -140,
              left: 0,
              right: 0,
              child: Center(
                child: Opacity(
                  opacity: 0.92,
                  child: RotationTransition(
                    turns: _rotationController,
                    child: Image.asset(
                      'assets/images/flowerImg.png',
                      width: MediaQuery.sizeOf(context).width * 0.76,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
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
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.sizeOf(context).height * 0.28,
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
                          SvgPicture.asset(
                            'assets/svgs/star.svg',
                            width: 32,
                            height: 32,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            slide.title,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontSize: 24,
                                  height: 32 / 24,
                                  fontWeight: FontWeight.w500,
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
            Align(
              alignment: Alignment.bottomCenter,
              child: Opacity(
                opacity: 0.95,
                child: Image.asset(
                  'assets/images/appFooterImg.png.png',
                  fit: BoxFit.fitWidth,
                  width: double.infinity,
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
                                    ? const Color(0xFF2D4EAD)
                                    : const Color(0xFFEBCFA7),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 18),
                      CustomButton(
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
