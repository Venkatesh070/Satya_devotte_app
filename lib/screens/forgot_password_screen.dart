import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/controllers/forgot_password_controller.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';
import 'package:satya_devotte_app/shared/widgets/gradient_outline_input_border.dart';

class ForgotPasswordScreen extends GetView<ForgotPasswordController> {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F1E8),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Obx(
                      () => Form(
                        key: controller.formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            IconButton(
                              onPressed: controller.isLoading.value
                                  ? null
                                  : Get.back,
                              icon: const Icon(Icons.arrow_back),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Forgot Password',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Enter your email address to receive a password reset link.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF666666),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Email ID',
                              style: TextStyle(
                                color: Color(0xFF8A816F),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: controller.emailController,
                              enabled: !controller.isLoading.value,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) =>
                                  controller.sendResetLink(),
                              decoration: InputDecoration(
                                hintText: 'Enter your email',
                                isDense: true,
                                filled: true,
                                fillColor: const Color(0xFFFFFBF3),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.inputBorderColor,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.inputBorderColor,
                                  ),
                                ),
                                focusedBorder: GradientOutlineInputBorder(
                                  gradient: AppColors.inputBorderGradient,
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.gradientStart,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 15,
                                ),
                              ),
                              validator: controller.validateEmail,
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed:
                                    (controller.isLoading.value ||
                                        controller.cooldownSeconds.value > 0)
                                    ? null
                                    : controller.sendResetLink,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFED844D),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: controller.isLoading.value
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : Text(
                                        controller.cooldownSeconds.value > 0
                                            ? 'Send again in ${controller.cooldownSeconds.value}s'
                                            : 'Send Reset Link',
                                      ),
                              ),
                            ),
                            if (controller.cooldownSeconds.value > 0) ...[
                              const SizedBox(height: 8),
                              // Text(
                              //   'You can request another reset link in ${controller.cooldownSeconds.value} seconds.',
                              //   style: const TextStyle(
                              //     fontSize: 12,
                              //     color: Color(0xFF7A7A7A),
                              //   ),
                              // ),
                            ],
                            if (controller.isSuccess.value) ...[
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE9F7EF),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFFB7E5C3),
                                  ),
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
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
