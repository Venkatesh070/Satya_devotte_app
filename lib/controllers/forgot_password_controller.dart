import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/services/auth_service.dart';
import 'package:satya_devotte_app/core/utils/toast_util.dart';

class ForgotPasswordController extends GetxController {
  ForgotPasswordController(this._authService);

  final AuthService _authService;
  final emailController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final isLoading = false.obs;
  final isSuccess = false.obs;
  final cooldownSeconds = 0.obs;
  Timer? _cooldownTimer;

  @override
  void onInit() {
    super.onInit();
    emailController.addListener(_onEmailChanged);
  }

  void _onEmailChanged() {
    if (isSuccess.value) {
      isSuccess.value = false;
    }
    if (emailController.text.trim().isEmpty) {
      resetState(clearText: false);
    }
  }

  void resetState({bool clearText = true}) {
    _cooldownTimer?.cancel();
    _cooldownTimer = null;
    cooldownSeconds.value = 0;
    isSuccess.value = false;
    isLoading.value = false;
    if (clearText) {
      emailController.clear();
    }
  }

  String? validateEmail(String? value) {
    final email = (value ?? '').trim().toLowerCase();
    if (email.isEmpty) return 'Email is required';
    final pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!pattern.hasMatch(email)) return 'Please enter a valid email address';
    return null;
  }

  Future<void> sendResetLink() async {
    if (isLoading.value || cooldownSeconds.value > 0) return;

    final formState = formKey.currentState;
    if (formState == null || !formState.validate()) return;

    FocusManager.instance.primaryFocus?.unfocus();

    isLoading.value = true;
    isSuccess.value = false;
    try {
      await _authService.sendPasswordResetEmail(emailController.text);
      isSuccess.value = true;
      ToastUtil.showSuccess('Password reset email sent successfully');
      _startCooldown();
    } on FirebaseAuthException catch (e) {
      final message = _mapFirebaseError(e);
      ToastUtil.showError(message);
    } catch (_) {
      ToastUtil.showError('Failed to send reset link. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Please enter a valid email address';
      case 'user-not-found':
        return 'This email is not registered. Please sign up first.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection';
      case 'too-many-requests':
        return 'Too many requests. Please try again later';
      default:
        return e.message ?? 'Unable to send reset link';
    }
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    cooldownSeconds.value = 60;
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final current = cooldownSeconds.value;
      if (current <= 1) {
        cooldownSeconds.value = 0;
        timer.cancel();
        return;
      }
      cooldownSeconds.value = current - 1;
    });
  }

  @override
  void onClose() {
    emailController.removeListener(_onEmailChanged);
    _cooldownTimer?.cancel();
    emailController.dispose();
    super.onClose();
  }
}
