import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/shared/widgets/onboarding_style_background.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/config/routes/app_routes.dart';
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
    (title: '', subtitle: 'Your spiritual companion'),
    (
      title: 'Guided Rituals',
      subtitle:
          'Step-by-step instructions for every puja,\nfrom preparation to completion',
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
    if (!kIsWeb) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
    // Don't start music here — wait until user logs in!
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
            OnboardingStyleBackground(rotationController: _rotationController),
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
                        child: Icon(
                          Icons.arrow_back,
                          size: 18,
                          color: Color(0XFF4A1C00),
                        ),
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
                    color: Color(0xFFFCF7EF),
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
              top: _currentIndex == 0
                  ? MediaQuery.sizeOf(context).height * 0.6 + 40
                  : MediaQuery.sizeOf(context).height * 0.6 + 50,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 180, // Increased height to fit logo and divider
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _slides.length,
                      onPageChanged: (index) =>
                          setState(() => _currentIndex = index),
                      itemBuilder: (context, index) {
                        final slide = _slides[index];
                        final isFirst = index == 0;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isFirst) ...[
                                Image.asset(
                                  'assets/images/SathyaLogo.png',
                                  height: 100,
                                  width: 344,
                                  fit: BoxFit.cover,
                                ),
                                // const SizedBox(height: 10),
                                Image.asset(
                                  'assets/images/divider.png',
                                  height: 23,
                                  width: 152,
                                  fit: BoxFit.cover,
                                ),
                              ] else ...[
                                Text(
                                  slide.title,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        color: Color(0xFFFCF7EF),
                                        fontSize: 24,
                                        height: 32 / 24,
                                        shadows: [
                                          Shadow(
                                            color: const Color.fromARGB(
                                              255,
                                              242,
                                              237,
                                              237,
                                            ).withValues(alpha: 0.25),
                                            offset: const Offset(0, 1),
                                            blurRadius: 8,
                                          ),
                                        ],
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                              const SizedBox(height: 1),
                              Text(
                                slide.subtitle,
                                textAlign: TextAlign.center,
                                style: AppTypography.lora(
                                  fontSize: 16,
                                  color: Color(0XFFFFFFFF),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (i) {
                      final isActive = i == _currentIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 6,
                        width: isActive ? 18 : 6,
                        decoration: BoxDecoration(
                          color: isActive
                              ? Color(0xFFFCF7EF)
                              : Color(0xFFFCF7EF).withOpacity(0.3),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            OnboardingStyleFooter(rotationController: _rotationController),
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
