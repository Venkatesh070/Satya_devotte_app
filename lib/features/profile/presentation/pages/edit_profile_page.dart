import 'dart:typed_data';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:satya_devotte_app/core/services/media_upload_service.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/features/profile/presentation/controllers/profile_controller.dart';
import 'package:satya_devotte_app/shared/widgets/custom_button.dart';
import 'package:satya_devotte_app/shared/widgets/gradient_outline_input_border.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  static const Color _bgColor = Color(0xFFF2EBDC);
  static const Color _fieldColor = Color(0xFFFFFBF3);
  static const Color _fieldBorder = Color(0xFFE0D6C2);
  static const Color _titleColor = Color(0xFF1F1F1F);

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late TextEditingController _birthPlaceController;

  PickedFile? _pickedImage;
  DateTime? _dateOfBirth;
  TimeOfDay? _timeOfBirth;
  String _selectedGender = 'MALE';
  String _sunSign = 'Aries';
  String _moonSign = 'Aries';

  final List<String> _zodiacSigns = [
    'Aries',
    'Taurus',
    'Gemini',
    'Cancer',
    'Leo',
    'Virgo',
    'Libra',
    'Scorpio',
    'Sagittarius',
    'Capricorn',
    'Aquarius',
    'Pisces',
  ];

  ProfileController get _profileController => Get.find<ProfileController>();
  MediaUploadService get _mediaService => Get.find<MediaUploadService>();

  @override
  void initState() {
    super.initState();
    final user = _profileController.resolvedUser;
    _fullNameController = TextEditingController(
      text: user?['fullName'] ?? user?['name'] ?? '',
    );
    _phoneController = TextEditingController(text: user?['phone'] ?? '');
    _birthPlaceController = TextEditingController(
      text: user?['placeOfBirth'] ?? '',
    );
    _selectedGender = (user?['gender']?.toString().toUpperCase() ?? 'MALE');
    if (_selectedGender != 'MALE' &&
        _selectedGender != 'FEMALE' &&
        _selectedGender != 'OTHER') {
      _selectedGender = 'MALE';
    }

    if (user?['dateOfBirth'] != null) {
      try {
        _dateOfBirth = DateTime.parse(user!['dateOfBirth'].toString());
      } catch (_) {}
    }

    if (user?['timeOfBirth'] != null) {
      try {
        final parts = user!['timeOfBirth'].toString().split(':');
        if (parts.length == 2) {
          _timeOfBirth = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        }
      } catch (_) {}
    }

    if (user?['sunSign'] != null && _zodiacSigns.contains(user!['sunSign'])) {
      _sunSign = user['sunSign'];
    }
    if (user?['moonSign'] != null && _zodiacSigns.contains(user!['moonSign'])) {
      _moonSign = user['moonSign'];
    }
  }

  @override
  void dispose() {
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
      initialDate: _dateOfBirth ?? DateTime(now.year - 21, now.month, now.day),
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

  Future<void> _pickImage() async {
    final picked = await _mediaService.pickFile(type: PickMediaType.image);
    if (picked != null) {
      setState(() => _pickedImage = picked);
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;

    final payload = <String, dynamic>{
      'fullName': _fullNameController.text.trim(),
      'gender': _selectedGender,
      'phone': _phoneController.text.trim(),
      'placeOfBirth': _birthPlaceController.text.trim(),
      'sunSign': _sunSign,
      'moonSign': _moonSign,
      'countryCode': '+91',
    };

    if (_dateOfBirth != null) {
      payload['dateOfBirth'] = DateFormat('yyyy-MM-dd').format(_dateOfBirth!);
    }
    if (_timeOfBirth != null) {
      final hh = _timeOfBirth!.hour.toString().padLeft(2, '0');
      final mm = _timeOfBirth!.minute.toString().padLeft(2, '0');
      payload['timeOfBirth'] = '$hh:$mm';
    }

    if (_pickedImage != null) {
      payload['image'] = dio.MultipartFile.fromBytes(
        _pickedImage!.bytes,
        filename: _pickedImage!.filename,
      );
    }

    final success = await _profileController.updateProfile(payload);
    if (success) {
      Get.back();
      Get.snackbar(
        'Success',
        'Profile updated successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      Get.snackbar(
        'Error',
        _profileController.error ?? 'Failed to update profile',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBgColor,
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: _titleColor, fontFamily: 'serif'),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: _titleColor,
            size: 20,
          ),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        final isLoading = _profileController.isLoading;
        final user = _profileController.resolvedUser;
        final existingImageUrl = user?['imageUrl'] ?? user?['profileImageUrl'];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: _fieldBorder,
                        backgroundImage: _pickedImage != null
                            ? MemoryImage(
                                Uint8List.fromList(_pickedImage!.bytes),
                              )
                            : (existingImageUrl != null
                                      ? NetworkImage(
                                          existingImageUrl.toString(),
                                        )
                                      : null)
                                  as ImageProvider?,
                        child:
                            (_pickedImage == null && existingImageUrl == null)
                            ? const Icon(
                                Icons.person,
                                size: 50,
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
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppColors.gradientStart,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                _buildLabel('Full Name'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _fullNameController,
                  decoration: _inputDecoration('Enter full name'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Full name is required'
                      : null,
                ),
                const SizedBox(height: 18),
                _buildLabel('Gender'),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  items: const [
                    DropdownMenuItem(value: 'MALE', child: Text('Male')),
                    DropdownMenuItem(value: 'FEMALE', child: Text('Female')),
                    DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                  ],
                  decoration: _inputDecoration('Select gender'),
                  onChanged: isLoading
                      ? null
                      : (v) => setState(() => _selectedGender = v!),
                ),
                const SizedBox(height: 18),
                _PickerField(
                  label: 'Date of Birth',
                  value: _dateOfBirth == null
                      ? null
                      : DateFormat('dd MMM yyyy').format(_dateOfBirth!),
                  icon: Icons.calendar_today,
                  onTap: isLoading ? null : _pickDob,
                ),
                const SizedBox(height: 18),
                _PickerField(
                  label: 'Time of Birth',
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
                  decoration: _inputDecoration('Enter place of birth'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Place of birth is required'
                      : null,
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Sun Sign'),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _sunSign,
                            items: _zodiacSigns
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s),
                                  ),
                                )
                                .toList(),
                            decoration: _inputDecoration('Select'),
                            onChanged: isLoading
                                ? null
                                : (v) => setState(() => _sunSign = v!),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Moon Sign'),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _moonSign,
                            items: _zodiacSigns
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s),
                                  ),
                                )
                                .toList(),
                            decoration: _inputDecoration('Select'),
                            onChanged: isLoading
                                ? null
                                : (v) => setState(() => _moonSign = v!),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _buildLabel('Phone Number'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: _inputDecoration('Enter phone number'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Phone number is required'
                      : null,
                ),
                const SizedBox(height: 40),
                CustomButton(
                  label: 'Update Profile',
                  isLoading: isLoading,
                  enabled: !isLoading,
                  borderRadius: 12,
                  gradientColors: const [
                    AppColors.gradientStart,
                    AppColors.gradientEnd,
                  ],
                  textColor: Colors.white,
                  onTap: _submit,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
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
        color: Colors.black.withOpacity(0.25),
        fontSize: 13,
      ),
      isDense: true,
      filled: true,
      fillColor: _fieldColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.inputBorderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.inputBorderColor),
      ),
      focusedBorder: GradientOutlineInputBorder(
        gradient: AppColors.inputBorderGradient,
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.gradientStart),
        gapPadding: 8.0,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.inter(
            color: const Color(0xFF4A1C00),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBF3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.inputBorderColor),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value ?? 'Select',
                    style: TextStyle(
                      color: value == null
                          ? Colors.black26
                          : const Color(0xFF1F1F1F),
                    ),
                  ),
                ),
                Icon(icon, size: 20, color: const Color(0xFF8F8574)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
