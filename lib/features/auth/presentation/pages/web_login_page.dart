import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/controllers/forgot_password_controller.dart';
import 'package:satya_devotte_app/core/presentation/get_snackbar_insets.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:satya_devotte_app/features/auth/presentation/widgets/inline_forgot_password_form.dart';
import 'package:satya_devotte_app/shared/widgets/onboarding_style_background.dart';
import 'package:satya_devotte_app/shared/widgets/custom_button.dart';
import 'package:satya_devotte_app/shared/widgets/gradient_outline_input_border.dart';

class WebLoginPage extends StatefulWidget {
  const WebLoginPage({super.key});

  @override
  State<WebLoginPage> createState() => _WebLoginPageState();
}

class _WebLoginPageState extends State<WebLoginPage>
    with SingleTickerProviderStateMixin {
  static const Color _fieldColor = Color(0xFFFFFBF3);

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();
  late final AnimationController _rotationController;
  bool _obscurePassword = true;
  bool _showForgotPassword = false;

  AuthController get controller => Get.find<AuthController>();

  void _navigateByRole() => controller.navigateAfterLogin();

  void _openForgotPassword() {
    final forgotCtrl = Get.find<ForgotPasswordController>();
    forgotCtrl.emailController.text = _emailController.text.trim();
    forgotCtrl.isSuccess.value = false;
    setState(() => _showForgotPassword = true);
  }

  void _closeForgotPassword() {
    setState(() => _showForgotPassword = false);
  }

  Future<void> _signIn() async {
    if (controller.isEmailSignInLoading) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      showAppSnackbar(
        title: 'Required',
        message: 'Please enter email and password.',
        isError: true,
      );
      return;
    }

    final ok = await controller.signInAsAdmin(
      email: email,
      password: password,
    );
    if (ok) {
      _navigateByRole();
    } else {
      showAppSnackbar(
        title: 'Login Failed',
        message:
            controller.lastAuthError ??
            'Admin sign in failed. Please try again.',
        isError: true,
      );
    }
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
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isWide = size.width >= 960;

    if (isWide) {
      return Scaffold(
        backgroundColor: const Color(0xFF1F1F1F),
        body: SafeArea(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: _buildLoginCard(isFullHeight: true),
              ),
              Expanded(
                child: OnboardingStyleBackground(
                  rotationController: _rotationController,
                  wrapInPositioned: false,
                  backgroundImage: 'assets/images/home/login_bg.png',
                  chakraVerticalOffset: 0,
                  chakraScale: 0.95,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Narrow/Mobile screen layout
    return Scaffold(
      backgroundColor: const Color(0xFF1F1F1F),
      body: Stack(
        children: [
          OnboardingStyleBackground(
            rotationController: _rotationController,
            wrapInPositioned: true,
            backgroundImage: 'assets/images/home/login_bg.png',
            chakraVerticalOffset: -80,
            chakraScale: 0.7,
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: _buildLoginCard(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginCard({bool isFullHeight = false}) {
    final cardContent = _showForgotPassword
        ? InlineForgotPasswordForm(
            onBack: _closeForgotPassword,
            showYogaImage: true,
          )
        : Obx(() {
              final isEmailLoading = controller.isEmailSignInLoading;
              return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    _buildLabel('Email'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      enabled: !isEmailLoading,
                      onFieldSubmitted: (_) {
                        FocusScope.of(context).requestFocus(_passwordFocusNode);
                      },
                      style: const TextStyle(
                        color: Color(0xFF1F1F1F),
                        fontSize: 13,
                      ),
                      decoration: _inputDecoration('Enter your email'),
                    ),
                    const SizedBox(height: 18),
                    _buildLabel('Password'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _passwordController,
                      focusNode: _passwordFocusNode,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      enabled: !isEmailLoading,
                      onFieldSubmitted: (_) {
                        if (!isEmailLoading) _signIn();
                      },
                      style: const TextStyle(
                        color: Color(0xFF1F1F1F),
                        fontSize: 13,
                      ),
                      decoration: _inputDecoration('Enter password').copyWith(
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword
                              ? 'Show password'
                              : 'Hide password',
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 18,
                            color: const Color(0xFF8F8574),
                          ),
                          onPressed: isEmailLoading
                              ? null
                              : () => setState(
                                    () =>
                                        _obscurePassword = !_obscurePassword,
                                  ),
                        ),
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
                      onTap: _signIn,
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
      shape: RoundedRectangleBorder(
        borderRadius: isFullHeight ? BorderRadius.zero : BorderRadius.circular(16),
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

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: AppTypography.inter(
        color: const Color(0xFF4A1C00),
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.black.withOpacity(0.25), fontSize: 13),
      isDense: true,
      filled: true,
      fillColor: _fieldColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.inputBorderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.inputBorderColor),
      ),
      focusedBorder: GradientOutlineInputBorder(
        gradient: AppColors.inputBorderGradient,
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.gradientStart),
      ),
    );
  }
}

