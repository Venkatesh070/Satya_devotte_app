import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
    _navigate();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _navigate() async {
    // Wait for splash to show
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final auth = Get.find<AuthController>();

    // Restore saved session from SharedPreferences
    await auth.loadSavedSession();

    if (!mounted) return;

    if (!auth.isAuthenticated) {
      // Web/CMS skips onboarding and goes straight to login.
      Get.offAllNamed(kIsWeb ? AppRoutes.login : AppRoutes.onboarding);
      return;
    }

    auth.navigateAfterLogin();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarDividerColor: Colors.black,
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
                          return Transform.rotate(angle: spin, child: child);
                        },
                        child: Image.asset('assets/images/flowerImg.png'),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Opacity(
                      opacity: 1,
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
                                child: Image.asset('assets/images/chakra1.png'),
                              ),
                              Transform.rotate(
                                angle: -spin,
                                child: Transform.scale(
                                  scale: 0.90,
                                  child: Image.asset('assets/images/chakra2.png'),
                                ),
                              ),
                              Transform.rotate(
                                angle: spin,
                                child: Transform.scale(
                                  scale: 0.80,
                                  child: Image.asset('assets/images/chakra3.png'),
                                ),
                              ),
                              Transform.rotate(
                                angle: -spin,
                                child: Transform.scale(
                                  scale: 0.53,
                                  child: Image.asset('assets/images/chakra4.png'),
                                ),
                              ),
                              Opacity(
                                opacity: 0.8,
                                child: Image.asset('assets/images/onBoardBgOverlay.png'),
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
              left: 0,
              right: 0,
              bottom: 88,
              child: Column(
                children: const [
                  Text(
                    'पूजा: कर्मणि कौशलम्',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Pooja is peace in action',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
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
          ],
        ),
      ),
    );
  }
}
