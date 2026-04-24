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
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Navigate based on the user's role after successful login.
  void _navigateByRole() {
    if (controller.isAdmin) {
      Get.offAllNamed(AppRoutes.cms);
    } else {
      Get.offAllNamed(AppRoutes.home);
    }
  }

  Future<void> _showEmailPasswordSheet() async {
    _emailController.clear();
    _passwordController.clear();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.of(context).viewInsets.bottom +
                  MediaQuery.of(context).padding.bottom +
                  20,
            ),
            child: Obx(() {
              final isLoading = controller.isEmailSignInLoading;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Continue with Email',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !isLoading,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    enabled: !isLoading,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  CustomButton(
                    label: 'Sign In',
                    isLoading: isLoading,
                    enabled: !isLoading,
                    gradientColors: const [
                      AppColors.gradientStart,
                      AppColors.gradientEnd,
                    ],
                    textColor: AppColors.white,
                    onTap: () async {
                      final email = _emailController.text.trim();
                      final password = _passwordController.text;
                      if (email.isEmpty || password.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter email and password.'),
                          ),
                        );
                        return;
                      }
                      final isSuccess = await controller
                          .signInWithEmailPassword(
                            email: email,
                            password: password,
                          );
                      if (!mounted) return;
                      if (isSuccess) {
                        Navigator.of(context).pop();
                        _navigateByRole();
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            controller.lastAuthError ??
                                'Email sign in failed. Please try again.',
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: isLoading
                        ? null
                        : () async {
                            final email = _emailController.text.trim();
                            final password = _passwordController.text;
                            if (email.isEmpty || password.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please enter email and password.',
                                  ),
                                ),
                              );
                              return;
                            }
                            final isSuccess = await controller
                                .signUpWithEmailPassword(
                                  email: email,
                                  password: password,
                                );
                            if (!mounted) return;
                            if (isSuccess) {
                              Navigator.of(context).pop();
                              _navigateByRole();
                              return;
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  controller.lastAuthError ??
                                      'Email sign up failed. Please try again.',
                                ),
                              ),
                            );
                          },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: const Text('Create New Account'),
                  ),
                ],
              );
            }),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
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
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Obx(() {
                  final isLoading = controller.isGoogleSignInLoading;
                  final isEmailLoading = controller.isEmailSignInLoading;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _SocialButton(
                        label: 'Continue with Google',
                        backgroundColor: const Color(0xFFF2F2F2),
                        textColor: const Color(0xFF1F1F1F),
                        leading: SvgPicture.asset(
                          'assets/svgs/google.svg',
                          width: 16,
                          height: 16,
                        ),
                        isLoading: isLoading,
                        isEnabled: !isLoading,
                        onTap: () async {
                          final isSuccess = await controller.signInWithGoogle();
                          if (isSuccess) {
                            _navigateByRole();
                            return;
                          }
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                controller.lastAuthError ??
                                    'Google sign in failed. Please try again.',
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      _SocialButton(
                        label: 'Continue with Apple',
                        backgroundColor: AppColors.black,
                        textColor: AppColors.white,
                        leading: SvgPicture.asset(
                          'assets/svgs/apple.svg',
                          width: 16,
                          height: 16,
                        ),
                        isEnabled: !isLoading,
                        onTap: () async {
                          await controller.signInWithApple();
                          _navigateByRole();
                        },
                      ),
                      const SizedBox(height: 12),
                      const Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: Color(0xFFE3D9C4),
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              'Or',
                              style: TextStyle(
                                color: Color(0xFF8B8B8B),
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: Color(0xFFE3D9C4),
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      CustomButton(
                        label: 'Continue with Email/Password',
                        gradientColors: [
                          AppColors.gradientStart,
                          AppColors.gradientEnd,
                        ],
                        textColor: AppColors.white,
                        isLoading: isEmailLoading,
                        enabled: !isEmailLoading && !isLoading,
                        onTap: () {
                          final isMobile =
                              MediaQuery.of(context).size.width < 600;

                          if (isMobile) {
                            _showEmailPasswordSheet();
                          } else {
                            Get.to(() => const EmailLoginPage());
                          }
                        },
                      ),
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
