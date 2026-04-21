import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/features/auth/presentation/controllers/auth_controller.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _navigate();
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
      // No saved session — go to onboarding
      Get.offAllNamed(AppRoutes.onboarding);
      return;
    }

    // Route based on role
    if (auth.isAdmin) {
      Get.offAllNamed(AppRoutes.cms);
    } else {
      Get.offAllNamed(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: const Color(0xFFF4F4F4),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final h = constraints.maxHeight;
            return Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Image.asset(
                    'assets/images/headerImg.png.png',
                    fit: BoxFit.fitWidth,
                    width: constraints.maxWidth,
                  ),
                ),
                Positioned(
                  top: -h * 0.02,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Opacity(
                      opacity: 0.28,
                      child: Image.asset(
                        'assets/images/headerFlower.png.png',
                        width: constraints.maxWidth * 0.78,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: h * 0.38,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Image.asset(
                      'assets/images/appLogo.png',
                      width: 120,
                      height: 120,
                    ),
                  ),
                ),
                Positioned(
                  top: h * 0.62,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      Text(
                        'पूजा: कर्मणि कौशलम्',
                        style: GoogleFonts.lora(
                          color: const Color(0xFF8D8D8D),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      Text(
                        'Pooja is peace in action',
                        style: GoogleFonts.lora(
                          color: const Color(0xFF7A7A7A),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: h * 0.05,
                  child: Image.asset(
                    'assets/images/footerImg.png.png',
                    fit: BoxFit.fitWidth,
                    width: constraints.maxWidth,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
