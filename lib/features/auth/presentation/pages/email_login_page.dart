import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/controllers/forgot_password_controller.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';
import 'package:satya_devotte_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:satya_devotte_app/features/auth/presentation/widgets/inline_forgot_password_form.dart';
import 'package:satya_devotte_app/shared/widgets/custom_button.dart';

class EmailLoginPage extends StatefulWidget {
  const EmailLoginPage({super.key});

  @override
  State<EmailLoginPage> createState() => _EmailLoginPageState();
}

class _EmailLoginPageState extends State<EmailLoginPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _showForgotPassword = false;

  late final AnimationController _rotationController;

  AuthController get controller => Get.find<AuthController>();

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      vsync: this,
      duration: kIsWeb
          ? const Duration(seconds: 40) // slower on web
          : const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _navigateByRole() {
    if (controller.isAdmin) {
      Get.offAllNamed(AppRoutes.cms);
    } else {
      Get.offAllNamed(AppRoutes.home);
    }
  }

  void _openForgotPassword() {
    final forgotCtrl = Get.find<ForgotPasswordController>();
    forgotCtrl.emailController.text = _emailController.text.trim();
    forgotCtrl.isSuccess.value = false;
    setState(() => _showForgotPassword = true);
  }

  void _closeForgotPassword() {
    setState(() => _showForgotPassword = false);
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: const Color(0xFFF2EBDC),
      body: Stack(
        children: [
          /// Top background image
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

          /// Rotating flower
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

          /// Skip
          Positioned(
            top: topInset + 24,
            right: 22,
            child: GestureDetector(
              onTap: () => Get.offAllNamed(AppRoutes.home),
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

          /// Title section
          Positioned(
            top: MediaQuery.sizeOf(context).height * 0.25,
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

          /// Center Card (MAIN FIX)
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Card(
                  elevation: 12,
                  shadowColor: Colors.black26,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: _showForgotPassword
                        ? InlineForgotPasswordForm(
                            onBack: _closeForgotPassword,
                          )
                        : Obx(() {
                      final isLoading = controller.isEmailSignInLoading;

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Continue with Email",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 20),

                          /// Email
                          TextField(
                            controller: _emailController,
                            enabled: !isLoading,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: "Email",
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 14),

                          /// Password
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            enabled: !isLoading,
                            decoration: InputDecoration(
                              labelText: "Password",
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                tooltip: _obscurePassword
                                    ? 'Show password'
                                    : 'Hide password',
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                                onPressed: isLoading
                                    ? null
                                    : () => setState(
                                          () => _obscurePassword =
                                              !_obscurePassword,
                                        ),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: isLoading ? null : _openForgotPassword,
                              child: const Text('Forgot Password?'),
                            ),
                          ),
                          const SizedBox(height: 20),

                          /// Sign In
                          CustomButton(
                            label: "Sign In",
                            isLoading: isLoading,
                            gradientColors: const [
                              AppColors.gradientStart,
                              AppColors.gradientEnd,
                            ],
                            textColor: Colors.white,
                            onTap: () async {
                              final email = _emailController.text.trim();
                              final password = _passwordController.text;

                              if (email.isEmpty || password.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please enter email and password',
                                    ),
                                  ),
                                );
                                return;
                              }

                              final success = await controller
                                  .signInWithEmailPassword(
                                    email: email,
                                    password: password,
                                  );

                              if (success) {
                                _navigateByRole();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      controller.lastAuthError ??
                                          'Login failed',
                                    ),
                                  ),
                                );
                              }
                            },
                          ),

                          const SizedBox(height: 10),

                          /// Sign Up
                          OutlinedButton(
                            onPressed: isLoading
                                ? null
                                : () async {
                                    final email = _emailController.text.trim();
                                    final password = _passwordController.text;

                                    if (email.isEmpty || password.isEmpty) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Please enter email and password',
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    final success = await controller
                                        .signUpWithEmailPassword(
                                          email: email,
                                          password: password,
                                        );

                                    if (success) {
                                      _navigateByRole();
                                    }
                                  },
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                            ),
                            child: const Text("Create New Account"),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
