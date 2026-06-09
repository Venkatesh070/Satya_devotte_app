import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';
import 'package:satya_devotte_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:satya_devotte_app/features/auth/presentation/pages/email_login_page.dart';
import 'package:satya_devotte_app/shared/widgets/custom_button.dart';

import 'package:satya_devotte_app/shared/widgets/onboarding_style_background.dart';
import 'package:satya_devotte_app/features/auth/presentation/widgets/login_footer.dart';

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
      duration: const Duration(seconds: 24),
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
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Scaffold(
      backgroundColor: AppColors.appBgColor,
      body: Stack(
        children: [
          // Dark top background with rotating mandala and original curved image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height:
                screenHeight *
                0.62, // Slightly reduced height to match Figma density
            child: OnboardingStyleBackground(
              rotationController: _rotationController,
              wrapInPositioned: false,
              backgroundImage: 'assets/images/home/login_bg.png',
              chakraVerticalOffset: 5, // Move mandala down to align with logo
            ),
          ),

          Positioned(
            top: topInset + 20,
            right: 20,
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
            top:
                screenHeight *
                0.23, // Adjusted logo position to be inside mandala
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

          /// Bottom Actions (Figma style)
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
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
                        hasBorder: true,
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
                      Text(
                        'Or',
                        style: TextStyle(
                          color: Colors.black.withValues(alpha: 0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
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
                      const SizedBox(height: 10),
                      const LoginFooter(),
                    ],
                  );
                }),
              ),
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
    this.hasBorder = false,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Widget leading;
  final VoidCallback onTap;
  final bool isLoading;
  final bool isEnabled;
  final bool hasBorder;

  @override
  Widget build(BuildContext context) {
    final canTap = isEnabled && !isLoading;
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(14),
      elevation: hasBorder ? 1 : 0,
      shadowColor: Colors.black12,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: canTap ? onTap : null,
        child: Container(
          height: 48,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: hasBorder
                ? Border.all(color: Colors.black.withValues(alpha: 0.1))
                : null,
          ),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(textColor),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      leading,
                      const SizedBox(width: 12),
                      Text(
                        label,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
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
