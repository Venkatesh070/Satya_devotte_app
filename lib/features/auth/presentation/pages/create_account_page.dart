import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/core/services/auth_session_service.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/core/services/offline_service.dart';
import 'package:satya_devotte_app/core/services/app_music_service.dart';
import 'package:satya_devotte_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:satya_devotte_app/shared/widgets/custom_button.dart';
import 'package:satya_devotte_app/shared/widgets/gradient_outline_input_border.dart';

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key, this.completeProfileOnly = false});

  final bool completeProfileOnly;

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  static const Color _fieldColor = Color(0xFFFFFBF3);
  static const Color _fieldBorder = Color(0xFFE0D6C2);

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birthPlaceController = TextEditingController();

  final _formStepOneKey = GlobalKey<FormState>();
  final _formStepTwoKey = GlobalKey<FormState>();

  DateTime? _dateOfBirth;
  String? _dobError;
  TimeOfDay? _timeOfBirth;
  String _selectedGender = 'MALE';
  int _step = 0;
  bool _hidePassword = true;
  bool _hideConfirmPassword = true;

  AuthController get _authController => Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<AppMusicService>()) {
      Get.find<AppMusicService>().suppressFloatingControl();
    }
    if (widget.completeProfileOnly) {
      _step = 1;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _prefillFromSession(),
      );
    }
  }

  Future<void> _prefillFromSession() async {
    final user = await Get.find<AuthSessionService>().getUserData();
    if (user == null) return;
    final email = (user['email'] as String? ?? '').trim();
    if (email.isNotEmpty) _emailController.text = email;
    final name = (user['fullName'] as String? ?? user['name'] as String? ?? '')
        .trim();
    if (name.isNotEmpty) _fullNameController.text = name;
  }

  @override
  void dispose() {
    if (Get.isRegistered<AppMusicService>()) {
      Get.find<AppMusicService>().syncControlsVisibility();
    }
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
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(1930),
      lastDate: DateTime(2100),
      initialDate: _dateOfBirth ?? today,
    );
    if (picked != null) {
      final pickedDate = DateTime(picked.year, picked.month, picked.day);
      if (pickedDate.isAfter(today)) {
        setState(() {
          _dateOfBirth = picked;
          _dobError = 'Date of birth cannot be in the future';
        });
      } else {
        setState(() {
          _dateOfBirth = picked;
          _dobError = null;
        });
      }
    }
  }

  Future<void> _pickTob() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _timeOfBirth ?? const TimeOfDay(hour: 6, minute: 0),
    );
    if (picked != null) setState(() => _timeOfBirth = picked);
  }

  void _goNext() {
    if (_formStepOneKey.currentState?.validate() != true) return;
    setState(() => _step = 1);
  }

  Future<void> _handleBack() async {
    if (_authController.isEmailSignInLoading) return;

    if (_step == 1 && !widget.completeProfileOnly) {
      setState(() => _step = 0);
      return;
    }

    if (widget.completeProfileOnly) {
      await _authController.signOut();
      if (!mounted) return;
      Get.offAllNamed(AppRoutes.login);
      return;
    }

    Get.back();
  }

  Future<void> _goToLogin() async {
    if (_authController.isEmailSignInLoading) return;

    if (widget.completeProfileOnly) {
      await _authController.signOut();
      if (!mounted) return;
    }

    Get.offAllNamed(AppRoutes.login);
  }

  Future<void> _submit({bool skipProfile = false}) async {
    if (!skipProfile && _formStepTwoKey.currentState?.validate() != true) {
      return;
    }

    Map<String, dynamic>? profilePayload;

    if (!skipProfile) {
      profilePayload = {
        'fullName': _fullNameController.text.trim(),
        'gender': _selectedGender,
        'countryCode': '+91',
        'timeZone': DateTime.now().timeZoneName,
        'preferredLanguage': 'en',
      };

      final dob = _dateOfBirth;
      if (dob != null) {
        profilePayload['dateOfBirth'] = DateFormat('yyyy-MM-dd').format(dob);
      }

      final tob = _timeOfBirth;
      if (tob != null) {
        final hh = tob.hour.toString().padLeft(2, '0');
        final mm = tob.minute.toString().padLeft(2, '0');
        profilePayload['timeOfBirth'] = '$hh:$mm';
      }

      final phone = _phoneController.text.trim();
      if (phone.isNotEmpty) {
        profilePayload['phone'] = phone;
      }

      final place = _birthPlaceController.text.trim();
      if (place.isNotEmpty) {
        profilePayload['placeOfBirth'] = place;
      }
    }

    try {
      if (widget.completeProfileOnly) {
        final isSuccess = await _authController.completeRegistration(
          profileData: profilePayload,
          skipProfile: skipProfile,
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

        _authController.navigateAfterLogin();
      } else {
        await _authController.signUpAndCreateProfile(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          profileData: profilePayload,
        );
        // No snackbar here, we're navigating to verification screen!
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _authController.lastAuthError ?? 'Create account failed.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _handleBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.appBgColor,
        body: SafeArea(
          child: Obx(() {
            final isLoading = _authController.isEmailSignInLoading;
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Bar
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
                          onTap: () => _handleBack(),
                          child: const Padding(
                            padding: EdgeInsets.all(9),
                            child: Icon(
                              Icons.arrow_back,
                              size: 18,
                              color: Color(0xFF1F1F1F),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      GestureDetector(
                        onTap: _goToLogin,
                        child: Row(
                          children: [
                            Text(
                              'Already have an account?',
                              style: TextStyle(
                                color: Colors.black.withValues(alpha: 0.58),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '  Login now!',
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.completeProfileOnly
                            ? 'Complete your profile'
                            : (_step == 0
                                  ? 'Signup with email'
                                  : 'Your details'),
                        style: AppTypography.lora(
                          color: const Color(0xFF4A1C00),
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.completeProfileOnly
                        ? 'Add your details to finish setting up your account'
                        : (_step == 0
                              ? 'Sign up with your email and set a secure password'
                              : 'Enter the below details to continue'),
                    style: AppTypography.inter(
                      color: const Color(0xFF4A1C00),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: SingleChildScrollView(
                      child: _step == 0 && !widget.completeProfileOnly
                          ? Form(
                              key: _formStepOneKey,
                              autovalidateMode: AutovalidateMode.onUnfocus,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 20),
                                  _buildLabel('Email ID'),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    style: const TextStyle(
                                      color: Color(0xFF1F1F1F),
                                      fontSize: 13,
                                    ),
                                    decoration: _inputDecoration(
                                      'Enter your email address',
                                    ),
                                    validator: (v) {
                                      final value = v?.trim() ?? '';
                                      if (value.isEmpty) {
                                        return 'Email is required';
                                      }
                                      final emailRegex = RegExp(
                                        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                                      );
                                      if (!emailRegex.hasMatch(value)) {
                                        return 'Invalid email address';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  _buildLabel('Password'),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _hidePassword,
                                    style: const TextStyle(
                                      color: Color(0xFF1F1F1F),
                                      fontSize: 13,
                                    ),
                                    decoration: _inputDecoration('*******')
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
                                                _hidePassword
                                                    ? Icons
                                                          .visibility_off_outlined
                                                    : Icons.visibility_outlined,
                                                size: 18,
                                                color: const Color(0xFF8F8574),
                                              ),
                                            ),
                                            onPressed: () => setState(
                                              () => _hidePassword =
                                                  !_hidePassword,
                                            ),
                                          ),
                                        ),
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
                                  _buildLabel('Confirm Password'),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _confirmPasswordController,
                                    obscureText: _hideConfirmPassword,
                                    style: const TextStyle(
                                      color: Color(0xFF1F1F1F),
                                      fontSize: 13,
                                    ),
                                    decoration: _inputDecoration('*******')
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
                                                _hideConfirmPassword
                                                    ? Icons
                                                          .visibility_off_outlined
                                                    : Icons.visibility_outlined,
                                                size: 18,
                                                color: const Color(0xFF8F8574),
                                              ),
                                            ),
                                            onPressed: () => setState(
                                              () => _hideConfirmPassword =
                                                  !_hideConfirmPassword,
                                            ),
                                          ),
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
                                  ),
                                ],
                              ),
                            )
                          : Form(
                              key: _formStepTwoKey,
                              autovalidateMode: AutovalidateMode.onUnfocus,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Full name'),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _fullNameController,
                                    enabled: !isLoading,
                                    style: const TextStyle(
                                      color: Color(0xFF1F1F1F),
                                      fontSize: 13,
                                    ),
                                    decoration: _inputDecoration(
                                      'Enter your name',
                                    ),
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty)
                                        ? 'Full name is required'
                                        : null,
                                  ),
                                  const SizedBox(height: 18),
                                  _buildLabel('Gender'),
                                  const SizedBox(height: 6),
                                  DropdownButtonFormField<String>(
                                    initialValue: _selectedGender,
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
                                    decoration: _inputDecoration(
                                      'Select gender',
                                    ),
                                    onChanged: isLoading
                                        ? null
                                        : (value) {
                                            if (value == null) {
                                              return;
                                            }
                                            setState(
                                              () => _selectedGender = value,
                                            );
                                          },
                                  ),
                                  const SizedBox(height: 18),
                                  _buildLabel('Date of Birth (optional)'),
                                  const SizedBox(height: 6),
                                  _PickerField(
                                    value: _dateOfBirth == null
                                        ? null
                                        : DateFormat(
                                            'dd MMM yyyy',
                                          ).format(_dateOfBirth!),
                                    icon: Icons.calendar_today_outlined,
                                    onTap: isLoading ? null : _pickDob,
                                    errorText: _dobError,
                                  ),
                                  const SizedBox(height: 18),
                                  _buildLabel('Time of Birth (optional)'),
                                  const SizedBox(height: 6),
                                  _PickerField(
                                    value: _timeOfBirth?.format(context),
                                    icon: Icons.access_time,
                                    onTap: isLoading ? null : _pickTob,
                                  ),
                                  const SizedBox(height: 18),
                                  _buildLabel('Place of Birth (optional)'),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _birthPlaceController,
                                    enabled: !isLoading,
                                    style: const TextStyle(
                                      color: Color(0xFF1F1F1F),
                                      fontSize: 13,
                                    ),
                                    decoration: _inputDecoration(
                                      'Enter place of birth',
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  _buildLabel('Mobile Number (optional)'),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    enabled: !isLoading,
                                    style: const TextStyle(
                                      color: Color(0xFF1F1F1F),
                                      fontSize: 13,
                                    ),
                                    decoration: _inputDecoration(
                                      'Enter mobile number',
                                    ),
                                    validator: (v) {
                                      final value = v?.trim() ?? '';
                                      if (value.isEmpty) return null;
                                      if (value.length < 10) {
                                        return 'Phone must be at least 10 digits';
                                      }
                                      return null;
                                    },
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
                    borderRadius: 22,
                    gradientColors: const [
                      AppColors.gradientStart,
                      AppColors.gradientEnd,
                    ],
                    textColor: Colors.white,
                    onTap: _step == 0
                        ? _goNext
                        : () async {
                            final offlineService = Get.find<OfflineService>();
                            if (!offlineService.checkAndShowDialog()) return;
                            await _submit();
                          },
                  ),
                ],
              ),
            );
          }),
        ),
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
      hintStyle: AppTypography.inter(
        color: Colors.black.withValues(alpha: 0.25),
        fontSize: 12,
      ),
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

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.value,
    required this.icon,
    required this.onTap,
    this.errorText,
  });

  final String? value;
  final IconData icon;
  final VoidCallback? onTap;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBF3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: errorText != null ? Colors.red : const Color(0xFFE0D6C2),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value ?? 'Select',
                    style: AppTypography.inter(
                      color: value == null
                          ? Colors.black.withValues(alpha: 0.25)
                          : const Color(0xFF1F1F1F),
                      fontSize: 13,
                    ),
                  ),
                ),
                Icon(icon, size: 18, color: const Color(0xFF8F8574)),
              ],
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 4),
            child: Text(
              errorText!,
              style: AppTypography.inter(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
      ],
    );
  }
}
