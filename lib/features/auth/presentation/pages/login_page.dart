import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';
import 'package:satya_devotte_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:satya_devotte_app/features/auth/presentation/pages/email_login_page.dart';
import 'package:satya_devotte_app/shared/widgets/custom_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;

  AuthController get controller => Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  void _navigateAfterLogin() => controller.navigateAfterLogin();

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: AppColors.appBgColor,
      body: Stack(
        children: [
          Positioned(
            top: -30,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/images/appHeaderImg.png',
              fit: BoxFit.fitWidth,
              width: double.infinity,
            ),
          ),
          Positioned(
            top: -180,
            left: 0,
            right: 0,
            child: Opacity(
              opacity: 0.92,
              child: RotationTransition(
                turns: _rotationController,
                child: Image.asset(
                  'assets/images/flowerImg.png',
                  width: MediaQuery.sizeOf(context).width * 0.2,
                ),
              ),
            ),
          ),
          Positioned(
            top: topInset + 24,
            right: 22,
            child: const Text(
              'Skip >>',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.sizeOf(context).height * 0.28,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  SvgPicture.asset(
                    'assets/svgs/star.svg',
                    width: 32,
                    height: 32,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Sign In to Continue',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Get reminded about auspicious days and\nupcoming celebrations',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// Bottom Actions (Figma style)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 30),

              child: Obx(() {
                final isLoading = controller.isGoogleSignInLoading;
                final isEmailLoading = controller.isEmailSignInLoading;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SocialButton(
                      label: 'Continue with Google',
                      backgroundColor: Colors.white,
                      textColor: const Color(0xFF1F1F1F),
                      leading: SvgPicture.asset(
                        'assets/svgs/google.svg',
                        width: 18,
                        height: 18,
                      ),
                      isLoading: isLoading,
                      isEnabled: !isLoading && !isEmailLoading,
                      onTap: () async {
                        final isSuccess = await controller.signInWithGoogle();
                        if (isSuccess) _navigateAfterLogin();
                      },
                    ),
                    const SizedBox(height: 12),
                    _SocialButton(
                      label: 'Continue with Apple',
                      backgroundColor: Colors.black,
                      textColor: Colors.white,
                      leading: SvgPicture.asset(
                        'assets/svgs/apple.svg',
                        width: 18,
                        height: 18,
                      ),
                      isEnabled: !isLoading && !isEmailLoading,
                      onTap: () async {
                        await controller.signInWithApple();
                        _navigateAfterLogin();
                      },
                    ),
                    const SizedBox(height: 12),
                    CustomButton(
                      label: 'Continue with Email',
                      gradientColors: const [
                        AppColors.gradientStart,
                        AppColors.gradientEnd,
                      ],
                      textColor: Colors.white,
                      isLoading: isEmailLoading,
                      enabled: !isEmailLoading && !isLoading,
                      borderRadius: 14,
                      onTap: () => Get.to(() => const EmailLoginPage()),
                    ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: () => Get.offAllNamed(AppRoutes.home),
                      child: Text(
                        'Skip for now',
                        style: TextStyle(
                          color: const Color(0xFF6B5730).withOpacity(0.7),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.leading,
    required this.onTap,
    this.isLoading = false,
    this.isEnabled = true,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Widget leading;
  final VoidCallback onTap;
  final bool isLoading;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final canTap = isEnabled && !isLoading;
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: canTap ? onTap : null,
        child: SizedBox(
          height: 48,
          width: double.infinity,
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(textColor),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      leading,
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
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
