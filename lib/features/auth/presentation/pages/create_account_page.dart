import 'dart:typed_data';

import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/core/services/media_upload_service.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';
import 'package:satya_devotte_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:satya_devotte_app/shared/widgets/custom_button.dart';

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  static const Color _bgColor = Color(0xFFF2EBDC);
  static const Color _fieldColor = Color(0xFFFFFBF3);
  static const Color _fieldBorder = Color(0xFFE0D6C2);
  static const Color _titleColor = Color(0xFF1F1F1F);

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birthPlaceController = TextEditingController();

  final _formStepOneKey = GlobalKey<FormState>();
  final _formStepTwoKey = GlobalKey<FormState>();

  PickedFile? _pickedImage;
  DateTime? _dateOfBirth;
  TimeOfDay? _timeOfBirth;
  String _selectedGender = 'MALE';
  int _step = 0;
  bool _hidePassword = true;
  bool _hideConfirmPassword = true;

  AuthController get _authController => Get.find<AuthController>();
  MediaUploadService get _mediaService => Get.find<MediaUploadService>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _birthPlaceController.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(1930),
      lastDate: now,
      initialDate: DateTime(now.year - 21, now.month, now.day),
    );
    if (picked != null) {
      setState(() => _dateOfBirth = picked);
    }
  }

  Future<void> _pickTob() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _timeOfBirth ?? const TimeOfDay(hour: 6, minute: 0),
    );
    if (picked != null) {
      setState(() => _timeOfBirth = picked);
    }
  }

  void _goNext() {
    if (_formStepOneKey.currentState?.validate() != true) return;
    setState(() => _step = 1);
  }

  Future<void> _pickImage() async {
    final picked = await _mediaService.pickFile(type: PickMediaType.image);
    if (picked != null) {
      setState(() => _pickedImage = picked);
    }
  }

  Future<void> _submit({bool skipProfile = false}) async {
    if (!skipProfile && _formStepTwoKey.currentState?.validate() != true)
      return;

    Map<String, dynamic>? profilePayload;

    if (!skipProfile) {
      if (_pickedImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please upload a profile image.')),
        );
        return;
      }

      final dob = _dateOfBirth;
      if (dob == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select date of birth.')),
        );
        return;
      }
      final tob = _timeOfBirth;
      if (tob == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select time of birth.')),
        );
        return;
      }

      profilePayload = {
        'fullName': _fullNameController.text.trim(),
        'gender': _selectedGender,
        'dateOfBirth': DateFormat('yyyy-MM-dd').format(dob),
        'phone': _phoneController.text.trim(),
        'placeOfBirth': _birthPlaceController.text.trim(),
        'countryCode': '+91',
        'timeZone': DateTime.now().timeZoneName,
        'preferredLanguage': 'en',
        'image': dio.MultipartFile.fromBytes(
          _pickedImage!.bytes,
          filename: _pickedImage!.filename,
        ),
      };

      final hh = tob.hour.toString().padLeft(2, '0');
      final mm = tob.minute.toString().padLeft(2, '0');
      profilePayload['timeOfBirth'] = '$hh:$mm';
    }

    final isSuccess = await _authController.signUpAndCreateProfile(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      profileData: profilePayload,
    );
    if (!mounted) return;

    if (!isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _authController.lastAuthError ?? 'Create account failed.',
          ),
        ),
      );
      return;
    }

    if (_authController.isAdmin) {
      Get.offAllNamed(AppRoutes.cms);
    } else {
      Get.offAllNamed(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Obx(() {
          final isLoading = _authController.isEmailSignInLoading;
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (_step == 1) {
                          setState(() => _step = 0);
                          return;
                        }
                        Get.back<void>();
                      },
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        size: 16,
                        color: Color(0xFF2A2A2A),
                      ),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Sign up with your mobile no to continue',
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.65),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'Login now',
                      style: TextStyle(
                        color: Color(0xFF6B5730),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _step == 0 ? 'Signup with email' : 'Your details',
                      style: const TextStyle(
                        color: _titleColor,
                        fontSize: 27,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'serif',
                      ),
                    ),
                    if (_step == 1)
                      TextButton(
                        onPressed: isLoading
                            ? null
                            : () => _submit(skipProfile: true),
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                            color: Color(0xFF6B5730),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _step == 0
                      ? 'Sign up with your email and set a secure password'
                      : 'Enter your details with us',
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.58),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: SingleChildScrollView(
                    child: _step == 0
                        ? Form(
                            key: _formStepOneKey,
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: _inputDecoration('Email'),
                                  validator: (v) {
                                    final value = v?.trim() ?? '';
                                    if (value.isEmpty)
                                      return 'Email is required';
                                    if (!value.contains('@'))
                                      return 'Invalid email';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _hidePassword,
                                  decoration: _inputDecoration('Password'),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Password is required';
                                    }
                                    if (v.length < 6) {
                                      return 'Password must be at least 6 characters';
                                    }
                                    return null;
                                  },
                                  onChanged: (_) => setState(() {}),
                                ),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: _confirmPasswordController,
                                  obscureText: _hideConfirmPassword,
                                  decoration: _inputDecoration(
                                    'Confirm Password',
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Please confirm password';
                                    }
                                    if (v != _passwordController.text) {
                                      return 'Passwords do not match';
                                    }
                                    return null;
                                  },
                                  onChanged: (_) => setState(() {}),
                                ),
                              ],
                            ),
                          )
                        : Form(
                            key: _formStepTwoKey,
                            child: Column(
                              children: [
                                Center(
                                  child: Stack(
                                    children: [
                                      CircleAvatar(
                                        radius: 45,
                                        backgroundColor: _fieldBorder,
                                        backgroundImage: _pickedImage != null
                                            ? MemoryImage(
                                                Uint8List.fromList(
                                                  _pickedImage!.bytes,
                                                ),
                                              )
                                            : null,
                                        child: _pickedImage == null
                                            ? const Icon(
                                                Icons.person,
                                                size: 45,
                                                color: Colors.white,
                                              )
                                            : null,
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: InkWell(
                                          onTap: isLoading ? null : _pickImage,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: AppColors.gradientStart,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.camera_alt,
                                              size: 18,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                TextFormField(
                                  controller: _fullNameController,
                                  decoration: _inputDecoration('Full Name'),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? 'Full name is required'
                                      : null,
                                ),
                                const SizedBox(height: 10),
                                DropdownButtonFormField<String>(
                                  value: _selectedGender,
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'MALE',
                                      child: Text('Male'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'FEMALE',
                                      child: Text('Female'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'OTHER',
                                      child: Text('Other'),
                                    ),
                                  ],
                                  decoration: _inputDecoration('Gender'),
                                  onChanged: isLoading
                                      ? null
                                      : (value) {
                                          if (value == null) return;
                                          setState(
                                            () => _selectedGender = value,
                                          );
                                        },
                                ),
                                const SizedBox(height: 10),
                                _PickerField(
                                  label: 'Date of Birth',
                                  value: _dateOfBirth == null
                                      ? null
                                      : DateFormat(
                                          'dd MMM yyyy',
                                        ).format(_dateOfBirth!),
                                  icon: Icons.calendar_today,
                                  onTap: isLoading ? null : _pickDob,
                                ),
                                const SizedBox(height: 10),
                                _PickerField(
                                  label: 'Time of Birth',
                                  value: _timeOfBirth == null
                                      ? null
                                      : _timeOfBirth!.format(context),
                                  icon: Icons.access_time,
                                  onTap: isLoading ? null : _pickTob,
                                ),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: _birthPlaceController,
                                  decoration: _inputDecoration(
                                    'Place of Birth',
                                  ),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? 'Place of birth is required'
                                      : null,
                                ),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  decoration: _inputDecoration('Phone Number'),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? 'Phone number is required'
                                      : null,
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                CustomButton(
                  label: _step == 0 ? 'Next' : 'Get Started',
                  isLoading: isLoading,
                  enabled: !isLoading,
                  borderRadius: 8,
                  gradientColors: const [
                    AppColors.gradientStart,
                    AppColors.gradientEnd,
                  ],
                  textColor: Colors.white,
                  onTap: _step == 0 ? _goNext : () => _submit(),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    final isPassword = label == 'Password';
    final isConfirmPassword = label == 'Confirm Password';
    return InputDecoration(
      labelText: label,
      isDense: true,
      filled: true,
      fillColor: _fieldColor,
      labelStyle: const TextStyle(color: Color(0xFF8A816F), fontSize: 11),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _fieldBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _fieldBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.gradientStart),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      suffixIcon: isPassword || isConfirmPassword
          ? IconButton(
              onPressed: () {
                if (isPassword) {
                  setState(() => _hidePassword = !_hidePassword);
                } else {
                  setState(() => _hideConfirmPassword = !_hideConfirmPassword);
                }
              },
              icon: Icon(
                (isPassword ? _hidePassword : _hideConfirmPassword)
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 18,
                color: const Color(0xFF8F8574),
              ),
            )
          : null,
    );
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String? value;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          filled: true,
          fillColor: const Color(0xFFF8F4EA),
          labelStyle: const TextStyle(color: Color(0xFF7D7466), fontSize: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE0D6C2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE0D6C2)),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          suffixIcon: Icon(icon, size: 18),
        ),
        child: Text(
          value ?? 'Select',
          style: TextStyle(
            color: value == null ? Colors.black54 : const Color(0xFF1F1F1F),
          ),
        ),
      ),
    );
  }
}
