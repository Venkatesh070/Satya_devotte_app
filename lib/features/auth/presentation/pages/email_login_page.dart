import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/controllers/forgot_password_controller.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/core/services/offline_service.dart';
import 'package:satya_devotte_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:satya_devotte_app/features/auth/presentation/widgets/inline_forgot_password_form.dart';
import 'package:satya_devotte_app/features/auth/presentation/pages/create_account_page.dart';
import 'package:satya_devotte_app/screens/forgot_password_screen.dart';
import 'package:satya_devotte_app/shared/widgets/custom_button.dart';
import 'package:satya_devotte_app/shared/widgets/gradient_outline_input_border.dart';

class EmailLoginPage extends StatefulWidget {
  const EmailLoginPage({super.key});

  @override
  State<EmailLoginPage> createState() => _EmailLoginPageState();
}

class _EmailLoginPageState extends State<EmailLoginPage> {
  static const Color _bgColor = Color(0xFFF2EBDC);
  static const Color _fieldColor = Color(0xFFFFFBF3);
  static const Color _fieldBorder = Color(0xFFE0D6C2);
  static const Color _titleColor = Color(0xFF1F1F1F);

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _showForgotPassword = false;

  AuthController get controller => Get.find<AuthController>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _navigateAfterLogin() => controller.navigateAfterLogin();

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
    return Scaffold(
      backgroundColor: AppColors.appBgColor,
      body: SafeArea(
        child: Obx(() {
          final isLoading = controller.isEmailSignInLoading;

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Top Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Material(
                      color: Colors.white,
                      elevation: 4,
                      shadowColor: Colors.black26,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => Get.back(),
                        child: const Padding(
                          padding: EdgeInsets.all(9),
                          child: Icon(Icons.arrow_back, size: 18),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Get.to(() => const CreateAccountPage()),
                      child: Row(
                        children: [
                          Text(
                            'New User?',
                            style: TextStyle(
                              color: Colors.black.withOpacity(0.58),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            ' Sign up now!',
                            style: TextStyle(
                              color: const Color(0xFF4A1C00),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                /// Title
                Text(
                  'Continue with email',
                  style: AppTypography.lora(
                    color: const Color(0xFF4A1C00),
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Enter your email id and password to continue',
                  style: AppTypography.inter(
                    color: const Color(0xFF4A1C00),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 24),

                Expanded(
                  child: SingleChildScrollView(
                    child: _showForgotPassword
                        ? InlineForgotPasswordForm(onBack: _closeForgotPassword)
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Email ID'),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _emailController,
                                enabled: !isLoading,
                                keyboardType: TextInputType.emailAddress,
                                decoration: _inputDecoration(
                                  'Enter your email',
                                ),
                              ),
                              const SizedBox(height: 18),
                              _buildLabel('Password'),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                enabled: !isLoading,
                                decoration: _inputDecoration('Enter password')
                                    .copyWith(
                                      suffixIcon: IconButton(
                                        icon: ShaderMask(
                                          shaderCallback: (bounds) =>
                                              const LinearGradient(
                                                colors: [
                                                  Color(0xFF183EA4),
                                                  Color(0xFFE35600),
                                                ],
                                                begin: Alignment.centerLeft,
                                                end: Alignment.centerRight,
                                              ).createShader(bounds),
                                          blendMode: BlendMode.srcIn,
                                          child: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            size: 18,
                                            color: const Color(0xFF8F8574),
                                          ),
                                        ),
                                        onPressed: () => setState(
                                          () => _obscurePassword =
                                              !_obscurePassword,
                                        ),
                                      ),
                                    ),
                              ),
                              // Align(
                              //   alignment: Alignment.centerRight,
                              //   child: TextButton(
                              //     onPressed: isLoading
                              //         ? null
                              //         : _openForgotPassword,
                              //     style: TextButton.styleFrom(
                              //       padding: EdgeInsets.zero,
                              //       minimumSize: const Size(0, 30),
                              //       tapTargetSize:
                              //           MaterialTapTargetSize.shrinkWrap,
                              //     ),
                              //     child: const Text(
                              //       'Forgot Password?',
                              //       style: TextStyle(
                              //         color: Color(0xFF6B5730),
                              //         fontSize: 11.5,
                              //         fontWeight: FontWeight.w600,
                              //       ),
                              //     ),
                              //   ),
                              // ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 12),
                CustomButton(
                  label: "Login",
                  isLoading: isLoading,
                  enabled: !isLoading,
                  borderRadius: 22,
                  gradientColors: const [
                    AppColors.gradientStart,
                    AppColors.gradientEnd,
                  ],
                  textColor: Colors.white,
                  onTap: () async {
                    final offlineService = Get.find<OfflineService>();
                    if (!offlineService.checkAndShowDialog()) return;

                    final email = _emailController.text.trim();
                    final password = _passwordController.text;

                    if (email.isEmpty || password.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter email and password'),
                        ),
                      );
                      return;
                    }

                    final success = await controller.signInWithEmailPassword(
                      email: email,
                      password: password,
                    );

                    if (success) {
                      _navigateAfterLogin();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            controller.lastAuthError ?? 'Login failed',
                          ),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          );
        }),
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
