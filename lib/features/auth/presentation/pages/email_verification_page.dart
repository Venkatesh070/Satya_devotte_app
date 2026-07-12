import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/core/services/firebase_service.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';
import 'package:satya_devotte_app/core/utils/toast_util.dart';
import 'package:satya_devotte_app/shared/widgets/custom_button.dart';
import 'package:satya_devotte_app/features/auth/presentation/controllers/auth_controller.dart';

class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({super.key});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  final FirebaseService _firebaseService = Get.find<FirebaseService>();
  final AuthController _authController = Get.find<AuthController>();
  Timer? _timer;
  Timer? _resendCooldownTimer;
  bool _isResending = false;
  bool _isSendingFirstEmail = false;
  bool _canResend = true;
  int _resendCooldownSeconds = 0;

  @override
  void initState() {
    super.initState();
    _startCheckTimer();
    _sendFirstVerificationEmail();
  }

  String _getUserFriendlyErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'too-many-requests':
          return 'Too many attempts! Please wait a few minutes and try again.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'user-not-found':
          return 'User not found. Please sign up first.';
        case 'user-disabled':
          return 'This account has been disabled.';
        default:
          return 'Error sending verification email: ${error.message}';
      }
    }
    return 'Failed to send verification email. Please try again.';
  }

  Future<void> _sendFirstVerificationEmail() async {
    setState(() => _isSendingFirstEmail = true);
    try {
      await _firebaseService.sendEmailVerification();
      if (mounted) {
        ToastUtil.showSuccess('Check your inbox for the verification link');
      }
    } catch (e) {
      if (mounted) {
        ToastUtil.showError(_getUserFriendlyErrorMessage(e));
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingFirstEmail = false);
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _resendCooldownTimer?.cancel();
    super.dispose();
  }

  void _startCheckTimer() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      await _firebaseService.reloadCurrentUser();
      if (_firebaseService.isEmailVerified) {
        _timer?.cancel();
        await _checkEmailVerifiedAndProceed();
      }
    });
  }

  void _startResendCooldown() {
    _resendCooldownSeconds = 60; // 1 minute cooldown
    _canResend = false;
    setState(() {});

    _resendCooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldownSeconds > 0) {
        setState(() => _resendCooldownSeconds--);
      } else {
        _resendCooldownTimer?.cancel();
        _canResend = true;
        setState(() {});
      }
    });
  }

  Future<void> _checkEmailVerifiedAndProceed() async {
    if (_firebaseService.isEmailVerified) {
      if (mounted) {
        await _authController.completeSignupAfterVerification();
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (_isResending || !_canResend) return;
    setState(() => _isResending = true);
    try {
      await _firebaseService.sendEmailVerification();
      _startResendCooldown();
      if (mounted) {
        ToastUtil.showSuccess('Verification email has been resent!');
      }
    } catch (e) {
      if (mounted) {
        ToastUtil.showError(_getUserFriendlyErrorMessage(e));
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  Future<void> _logout() async {
    await _authController.signOut();
    Get.offAllNamed(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final user = _firebaseService.getCurrentUserProfileDetails();
    final email = user?['email'] ?? '';

    return Scaffold(
      backgroundColor: AppColors.appBgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.email_outlined,
                size: 80,
                color: AppColors.gradientStart,
              ),
              const SizedBox(height: 24),
              Text(
                'Verify your email',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF4A1C00),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'We have sent a verification email to\n$email',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 40),
              CustomButton(
                label: _isSendingFirstEmail
                    ? 'Sending Verification Email...'
                    : !_canResend
                    ? 'Resend in $_resendCooldownSeconds s'
                    : 'Resend Verification Email',
                isLoading: _isResending || _isSendingFirstEmail,
                enabled: !_isResending && !_isSendingFirstEmail && _canResend,
                gradientColors: const [
                  AppColors.gradientStart,
                  AppColors.gradientEnd,
                ],
                textColor: Color(0xFFFCF7EF),
                borderRadius: 14,
                onTap: _resendVerificationEmail,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _logout,
                child: Text(
                  'Cancel & Go Back',
                  style: TextStyle(
                    color: const Color(0xFF4A1C00),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
