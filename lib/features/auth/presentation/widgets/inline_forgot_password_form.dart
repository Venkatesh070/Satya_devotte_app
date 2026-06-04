import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/controllers/forgot_password_controller.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';
import 'package:satya_devotte_app/shared/widgets/custom_button.dart';

/// Forgot-password UI for use inside login screens (no route push).
class InlineForgotPasswordForm extends StatelessWidget {
  const InlineForgotPasswordForm({
    super.key,
    required this.onBack,
    this.showYogaImage = false,
  });

  final VoidCallback onBack;
  final bool showYogaImage;

  @override
  Widget build(BuildContext context) {
    final forgotCtrl = Get.find<ForgotPasswordController>();
    return Obx(
      () => Form(
        key: forgotCtrl.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showYogaImage) ...[
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
            ],
            const Text(
              'Forgot Password',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter your email address to receive a password reset link',
              style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: forgotCtrl.emailController,
              enabled: !forgotCtrl.isLoading.value,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => forgotCtrl.sendResetLink(),
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'Enter your email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.inputBorderColor,
                  ),
                ),
              ),
              validator: forgotCtrl.validateEmail,
            ),
            const SizedBox(height: 18),
            CustomButton(
              label: forgotCtrl.cooldownSeconds.value > 0
                  ? 'Send again in ${forgotCtrl.cooldownSeconds.value}s'
                  : 'Send Reset Link',
              isLoading: forgotCtrl.isLoading.value,
              enabled:
                  !forgotCtrl.isLoading.value &&
                  forgotCtrl.cooldownSeconds.value == 0,
              gradientColors: const [
                AppColors.gradientStart,
                AppColors.gradientEnd,
              ],
              textColor: AppColors.white,
              onTap: forgotCtrl.sendResetLink,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: forgotCtrl.isLoading.value ? null : onBack,
                child: const Text('Back to Login'),
              ),
            ),
            if (forgotCtrl.cooldownSeconds.value > 0) ...[
              const SizedBox(height: 8),
              Text(
                'You can request another reset link in ${forgotCtrl.cooldownSeconds.value} seconds.',
                style: const TextStyle(fontSize: 12, color: Color(0xFF7A7A7A)),
              ),
            ],
            if (forgotCtrl.isSuccess.value) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9F7EF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFB7E5C3)),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: Color(0xFF2E7D32),
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Reset link sent. Please check your email inbox.',
                        style: TextStyle(
                          color: Color(0xFF2E7D32),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
