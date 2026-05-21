import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:satya_devotte_app/core/services/auth_session_service.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:satya_devotte_app/shared/widgets/custom_button.dart';

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key, this.completeProfileOnly = false});

  final bool completeProfileOnly;

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
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

  DateTime? _dateOfBirth;
  TimeOfDay? _timeOfBirth;
  String _selectedGender = 'MALE';
  int _step = 0;
  bool _hidePassword = true;
  bool _hideConfirmPassword = true;

  AuthController get _authController => Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
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
    if (picked != null) setState(() => _dateOfBirth = picked);
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

  Future<void> _submit({bool skipProfile = false}) async {
    if (!skipProfile && _formStepTwoKey.currentState?.validate() != true)
      return;

    Map<String, dynamic>? profilePayload;

    if (!skipProfile) {
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

      final hh = tob.hour.toString().padLeft(2, '0');
      final mm = tob.minute.toString().padLeft(2, '0');

      // Fix: assign to outer variable, don't redeclare with `final`
      profilePayload = {
        'fullName': _fullNameController.text.trim(),
        'gender': _selectedGender,
        'dateOfBirth': DateFormat('yyyy-MM-dd').format(dob),
        'phone': _phoneController.text.trim(),
        'placeOfBirth': _birthPlaceController.text.trim(),
        'countryCode': '+91',
        'timeZone': DateTime.now().timeZoneName,
        'preferredLanguage': 'en',
        'timeOfBirth': '$hh:$mm',
      };
    }

    final bool isSuccess;
    if (widget.completeProfileOnly) {
      isSuccess = await _authController.completeRegistration(
        profileData: profilePayload,
        skipProfile: skipProfile,
      );
    } else {
      isSuccess = await _authController.signUpAndCreateProfile(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        profileData: profilePayload,
      );
    }

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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    IconButton(
                      onPressed: () {
                        if (_step == 1 && !widget.completeProfileOnly) {
                          setState(() => _step = 0);
                          return;
                        }
                        Get.back();
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

                    GestureDetector(
                      onTap: () => Get.to(() => const CreateAccountPage()),
                      child: Row(
                        children: [
                          Text(
                            'Already have an account?',
                            style: TextStyle(
                              color: Colors.black.withOpacity(0.58),
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
                          : (_step == 0 ? 'Signup with email' : 'Your details'),
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [
                                const SizedBox(height: 20),

                                _buildLabel('Email ID'),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: _inputDecoration(
                                    'Enter your email address',
                                  ),
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
                                _buildLabel('Password'),
                                const SizedBox(height: 6),

                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _hidePassword,
                                  decoration: _inputDecoration('*******')
                                      .copyWith(
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _hidePassword
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            size: 18,
                                            color: const Color(0xFF8F8574),
                                          ),
                                          onPressed: () => setState(
                                            () =>
                                                _hidePassword = !_hidePassword,
                                          ),
                                        ),
                                      ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty)
                                      return 'Password is required';
                                    if (v.length < 6)
                                      return 'Password must be at least 6 characters';
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
                                  decoration: _inputDecoration('*******')
                                      .copyWith(
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _hideConfirmPassword
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            size: 18,
                                            color: const Color(0xFF8F8574),
                                          ),
                                          onPressed: () => setState(
                                            () => _hideConfirmPassword =
                                                !_hideConfirmPassword,
                                          ),
                                        ),
                                      ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty)
                                      return 'Please confirm password';
                                    if (v != _passwordController.text)
                                      return 'Passwords do not match';
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          )
                        : Form(
                            key: _formStepTwoKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Full name'),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _fullNameController,
                                  enabled: !isLoading,
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
                                  decoration: _inputDecoration('Select gender'),
                                  onChanged: isLoading
                                      ? null
                                      : (value) {
                                          if (value == null) return;
                                          setState(
                                            () => _selectedGender = value,
                                          );
                                        },
                                ),
                                const SizedBox(height: 18),
                                _buildLabel('Select Date of Birth'),
                                const SizedBox(height: 6),
                                _PickerField(
                                  value: _dateOfBirth == null
                                      ? null
                                      : DateFormat(
                                          'dd MMM yyyy',
                                        ).format(_dateOfBirth!),
                                  icon: Icons.calendar_today_outlined,
                                  onTap: isLoading ? null : _pickDob,
                                ),
                                const SizedBox(height: 18),
                                _buildLabel('Select Time of Birth'),
                                const SizedBox(height: 6),
                                _PickerField(
                                  value: _timeOfBirth == null
                                      ? null
                                      : _timeOfBirth!.format(context),
                                  icon: Icons.access_time,
                                  onTap: isLoading ? null : _pickTob,
                                ),
                                const SizedBox(height: 18),
                                _buildLabel('Place of Birth'),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _birthPlaceController,
                                  enabled: !isLoading,
                                  decoration: _inputDecoration(
                                    'Enter place of birth',
                                  ),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? 'Place of birth is required'
                                      : null,
                                ),
                                const SizedBox(height: 18),
                                _buildLabel('Mobile Number'),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  enabled: !isLoading,
                                  decoration: _inputDecoration(
                                    'Enter mobile number',
                                  ),
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
                  onTap: _step == 0 ? _goNext : _submit,
                ),
              ],
            ),
          );
        }),
      ),
    );
  } // ← build() closes here

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFF4A1C00),
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTypography.inter(
        color: Colors.black.withOpacity(0.25),
        fontSize: 12,
      ),
      isDense: true,
      filled: true,
      fillColor: _fieldColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
    );
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String? value;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBF3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE0D6C2)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value ?? 'Select',
                style: TextStyle(
                  color: value == null
                      ? Colors.black.withOpacity(0.25)
                      : const Color(0xFF1F1F1F),
                  fontSize: 13,
                ),
              ),
            ),
            Icon(icon, size: 18, color: const Color(0xFF8F8574)),
          ],
        ),
      ),
    );
  }
}
