import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/features/calendar/presentation/controllers/calendar_controller.dart';
import 'package:satya_devotte_app/features/calendar/presentation/widgets/calendar_ui.dart';
import 'package:satya_devotte_app/features/donations/presentation/widgets/donation_ui.dart';
import 'package:satya_devotte_app/shared/widgets/custom_button.dart';
import 'package:satya_devotte_app/shared/widgets/gradient_outline_input_border.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';

/// Figma "Add new event" form.
class CalendarAddEventPage extends StatefulWidget {
  const CalendarAddEventPage({super.key});

  @override
  State<CalendarAddEventPage> createState() => _CalendarAddEventPageState();
}

class _CalendarAddEventPageState extends State<CalendarAddEventPage> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  DateTime? _selectedDate;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter the event name.');
      return;
    }
    if (_selectedDate == null) {
      setState(() => _error = 'Select a date.');
      return;
    }
    await Get.find<CalendarController>().addUserEvent(
      name: name,
      description: _descCtrl.text.trim(),
      date: _selectedDate!,
    );
    if (!mounted) return;
    Get.back();
    Get.snackbar('Event added', name, snackPosition: SnackPosition.BOTTOM);
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = _selectedDate == null
        ? 'Select Date'
        : DateFormat('d MMM yyyy').format(_selectedDate!);

    return Scaffold(
      backgroundColor: CalendarUi.background,
      appBar: DonationSimpleAppBar(title: 'Add new event', onBack: Get.back),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Name of the event',
                    style: AppTypography.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: CalendarUi.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: _inputDecoration('Enter name of the event'),
                    onChanged: (_) {
                      if (_error != null) setState(() => _error = null);
                    },
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Description',
                    style: AppTypography.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: CalendarUi.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descCtrl,
                    maxLines: 4,
                    decoration: _inputDecoration('Enter description'),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Select Date',
                    style: AppTypography.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: CalendarUi.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: CalendarUi.cardBorder),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              dateLabel,
                              style: AppTypography.inter(
                                fontSize: 14,
                                color: _selectedDate == null
                                    ? CalendarUi.textMuted
                                    : CalendarUi.textPrimary,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 20,
                            color: CalendarUi.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: AppTypography.inter(
                        fontSize: 12,
                        color: const Color(0xFFB10F1A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: CustomButton(
                label: 'Add event',
                textColor: Colors.white,
                gradientColors: kCalendarActionGradient,
                borderRadius: 14,
                onTap: _submit,
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.black.withOpacity(0.25), fontSize: 13),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.inputBorderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.inputBorderColor),
      ),
      focusedBorder: GradientOutlineInputBorder(
        gradient: AppColors.inputBorderGradient,
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: CalendarUi.headerOrange,
          width: 1.5,
        ),
      ),
    );
  }
}
