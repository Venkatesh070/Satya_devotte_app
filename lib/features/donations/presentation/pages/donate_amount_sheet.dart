// Bottom sheet that captures the donation amount + optional note, then
// kicks off the Paystack flow via [DonateController.initiate].
//
// On success it pushes the confirming screen (which launches the Paystack
// URL and polls verify). Inline errors are surfaced from
// [DonateController.lastError] and from local validation.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/features/donations/data/models/donation.dart';
import 'package:satya_devotte_app/features/donations/presentation/pages/make_donation_screen.dart';
import 'package:satya_devotte_app/features/donations/state/donate_controller.dart';

class DonateAmountSheet extends StatefulWidget {
  const DonateAmountSheet({super.key, required this.donation});
  final Donation donation;

  static Future<void> show(BuildContext context,
      {required Donation donation}) {
    return MakeDonationScreen.open(donation: donation);
  }

  @override
  State<DonateAmountSheet> createState() => _DonateAmountSheetState();
}

class _DonateAmountSheetState extends State<DonateAmountSheet> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  static const _quickAmounts = <int>[50, 100, 250, 500, 1000];

  late final DonateController _donateCtrl;
  String? _inlineError;

  @override
  void initState() {
    super.initState();
    _donateCtrl = Get.find<DonateController>();
    _donateCtrl.reset();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  String? _validate() {
    final raw = _amountCtrl.text.trim();
    if (raw.isEmpty) return 'Enter an amount.';
    final parsed = num.tryParse(raw);
    if (parsed == null) return 'Enter a valid amount.';
    if (parsed < 10) return 'Minimum donation is R 10.';
    if (_noteCtrl.text.length > 280) {
      return 'Note must be 280 characters or fewer.';
    }
    return null;
  }

  Future<void> _submit() async {
    final err = _validate();
    if (err != null) {
      setState(() => _inlineError = err);
      return;
    }
    setState(() => _inlineError = null);

    final init = await _donateCtrl.initiate(
      donationId: widget.donation.id,
      amount: num.parse(_amountCtrl.text.trim()),
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    );

    if (!mounted) return;
    if (init == null) {
      setState(() =>
          _inlineError = _donateCtrl.lastError ?? 'Could not start donation.');
      return;
    }
    // Close the sheet, then jump to the confirming screen.
    Navigator.of(context).pop();
    Get.toNamed(AppRoutes.userDonationConfirming, arguments: init);
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3D9C2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Donate to',
                style: AppTypography.inter(
                  fontSize: 12,
                  color: const Color(0xFF7F6C53),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.donation.title,
                style: AppTypography.lora(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textColor,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Amount (ZAR)',
                style: AppTypography.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF4A1C00),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: InputDecoration(
                  hintText: 'Min R 10',
                  prefixText: 'R ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (_) {
                  if (_inlineError != null) {
                    setState(() => _inlineError = null);
                  }
                },
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickAmounts.map((v) {
                  final f = NumberFormat.decimalPattern();
                  return OutlinedButton(
                    onPressed: () {
                      _amountCtrl.text = v.toString();
                      _amountCtrl.selection = TextSelection.collapsed(
                        offset: _amountCtrl.text.length,
                      );
                      setState(() => _inlineError = null);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      side: const BorderSide(color: Color(0xFFE3D9C2)),
                      foregroundColor: AppColors.textColor,
                    ),
                    child: Text('R ${f.format(v)}'),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text(
                'Note (optional)',
                style: AppTypography.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF4A1C00),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _noteCtrl,
                maxLength: 280,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'A short message…',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              if (_inlineError != null) ...[
                const SizedBox(height: 4),
                Text(
                  _inlineError!,
                  style: AppTypography.inter(
                    fontSize: 12,
                    color: const Color(0xFFB10F1A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Obx(() {
                final loading = _donateCtrl.isInitiating;
                return SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB10F33),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Continue to payment',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
