import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/controllers/forgot_password_controller.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';
import 'package:satya_devotte_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:satya_devotte_app/screens/forgot_password_screen.dart';
import 'package:satya_devotte_app/shared/widgets/custom_button.dart';

class WebLoginPage extends StatefulWidget {
  const WebLoginPage({super.key});

  @override
  State<WebLoginPage> createState() => _WebLoginPageState();
}

class _WebLoginPageState extends State<WebLoginPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late final AnimationController _rotationController;
  bool _showEmailForm = false;

  AuthController get controller => Get.find<AuthController>();

  void _navigateByRole() {
    if (controller.isAdmin) {
      Get.offAllNamed(AppRoutes.cms);
    } else {
      Get.offAllNamed(AppRoutes.home);
    }
  }

  void _openForgotPassword() {
    final forgotCtrl = Get.find<ForgotPasswordController>();
    forgotCtrl.emailController.clear();
    forgotCtrl.isSuccess.value = false;
    Get.to(() => const ForgotPasswordScreen());
  }

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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isWide = size.width >= 960;

    return Scaffold(
      backgroundColor: const Color(0xFFF2EBDC),
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
          SafeArea(
            child: isWide
                ? Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: _buildLoginCard(isFullHeight: true),
                        ),
                      ),
                  
                      Expanded(child: _buildChakraAnimation()),
                    ],
                  )
                : Center(child: _buildLoginCard()),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginCard({bool isFullHeight = false}) {
    final cardContent = Obx(() {
              final isGoogleLoading = controller.isGoogleSignInLoading;
              final isEmailLoading = controller.isEmailSignInLoading;
              if (_showEmailForm) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Material(
                          color: const Color(0xFFF3F3F3),
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: isEmailLoading
                                ? null
                                : () => setState(() => _showEmailForm = false),
                            child: const Padding(
                              padding: EdgeInsets.all(8),
                              child: Icon(Icons.arrow_back, size: 18),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Continue with Email',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 300,
                      width: double.infinity,
                      child: Image.asset(
                        'assets/images/yoga.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      enabled: !isEmailLoading,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      enabled: !isEmailLoading,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: isEmailLoading ? null : _openForgotPassword,
                        child: const Text('Forgot Password?'),
                      ),
                    ),
                    const SizedBox(height: 14),
                    CustomButton(
                      label: 'Sign In',
                      isLoading: isEmailLoading,
                      enabled: !isEmailLoading,
                      gradientColors: const [
                        AppColors.gradientStart,
                        AppColors.gradientEnd,
                      ],
                      textColor: AppColors.white,
                      onTap: () async {
                        final email = _emailController.text.trim();
                        final password = _passwordController.text;
                        if (email.isEmpty || password.isEmpty) {
                          Get.snackbar(
                            'Required',
                            'Please enter email and password.',
                            snackPosition: SnackPosition.TOP,
                          );
                          return;
                        }
                        final ok = await controller.signInWithEmailPassword(
                          email: email,
                          password: password,
                        );
                        if (ok) {
                          _navigateByRole();
                        } else {
                          Get.snackbar(
                            'Login Failed',
                            controller.lastAuthError ??
                                'Email sign in failed. Please try again.',
                            snackPosition: SnackPosition.TOP,
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: isEmailLoading
                          ? null
                          : () async {
                              final email = _emailController.text.trim();
                              final password = _passwordController.text;
                              if (email.isEmpty || password.isEmpty) {
                                Get.snackbar(
                                  'Required',
                                  'Please enter email and password.',
                                  snackPosition: SnackPosition.TOP,
                                );
                                return;
                              }
                              final ok = await controller.signUpWithEmailPassword(
                                email: email,
                                password: password,
                              );
                              if (ok) {
                                _navigateByRole();
                              } else {
                                Get.snackbar(
                                  'Signup Failed',
                                  controller.lastAuthError ??
                                      'Email sign up failed. Please try again.',
                                  snackPosition: SnackPosition.TOP,
                                );
                              }
                            },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: const Text('Create New Account'),
                    ),
                  ],
                );
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Sign In to Continue',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Choose a login method',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF7A7A7A),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 300,
                    width: double.infinity,
                    child: Image.asset(
                      'assets/images/yoga.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _WebSocialButton(
                    label: 'Continue with Google',
                    backgroundColor: const Color(0xFFF2F2F2),
                    textColor: const Color(0xFF1F1F1F),
                    leading: SvgPicture.asset(
                      'assets/svgs/google.svg',
                      width: 16,
                      height: 16,
                    ),
                    isLoading: isGoogleLoading,
                    isEnabled: !isGoogleLoading,
                    onTap: () async {
                      final ok = await controller.signInWithGoogle();
                      if (ok) {
                        _navigateByRole();
                      } else {
                        Get.snackbar(
                          'Login Failed',
                          controller.lastAuthError ??
                              'Google sign in failed. Please try again.',
                          snackPosition: SnackPosition.TOP,
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  _WebSocialButton(
                    label: 'Continue with Apple',
                    backgroundColor: AppColors.black,
                    textColor: AppColors.white,
                    leading: SvgPicture.asset(
                      'assets/svgs/apple.svg',
                      width: 16,
                      height: 16,
                    ),
                    isEnabled: !isGoogleLoading,
                    onTap: () async {
                      await controller.signInWithApple();
                      _navigateByRole();
                    },
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text('Or'),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CustomButton(
                    label: 'Continue with Email/Password',
                    gradientColors: const [
                      AppColors.gradientStart,
                      AppColors.gradientEnd,
                    ],
                    textColor: AppColors.white,
                    isLoading: isEmailLoading,
                    enabled: !isGoogleLoading && !isEmailLoading,
                    onTap: () {
                      setState(() {
                        _showEmailForm = true;
                        _emailController.clear();
                        _passwordController.clear();
                      });
                    },
                  ),
                ],
              );
            });

    final cardBody = isFullHeight
        ? SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: cardContent,
            ),
          )
        : Padding(
            padding: const EdgeInsets.all(24),
            child: cardContent,
          );

    final card = Card(
      margin: EdgeInsets.zero,
      elevation: 8,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      clipBehavior: Clip.hardEdge,
      child: cardBody,
    );

    if (isFullHeight) {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SizedBox(
          height: double.infinity,
          child: card,
        ),
      );
    }

    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: card,
      ),
    );
  }

  Widget _buildChakraAnimation() {
    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        final spin = _rotationController.value * 2 * math.pi;
        return Center(
          child: Stack(
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
                  child: Image.asset(
                    'assets/images/chakra3.png',
                    filterQuality: FilterQuality.high,
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
                      Opacity(
                        opacity: 0.8,
                        child: Image.asset(
                          'assets/images/onBoardBgOverlay.png',
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SvgPicture.asset(
                'assets/svgs/whiteLogo.svg',
                width: 84,
                height: 102,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WebSocialButton extends StatelessWidget {
  const _WebSocialButton({
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
