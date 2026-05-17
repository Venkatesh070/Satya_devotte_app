import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/features/donations/data/models/donation.dart';
import 'package:satya_devotte_app/features/donations/presentation/widgets/donation_ui.dart';
import 'package:satya_devotte_app/features/donations/state/donate_controller.dart';
import 'package:satya_devotte_app/features/donations/state/donations_list_controller.dart';
import 'package:satya_devotte_app/features/profile/presentation/widgets/profile_ui.dart';
import 'package:satya_devotte_app/shared/widgets/custom_button.dart';

/// Figma Make Donation — category, amount, quick chips, gradient Donate Now.
class MakeDonationScreen extends StatefulWidget {
  const MakeDonationScreen({super.key, this.preselected});

  final Donation? preselected;

  static Future<void> open({Donation? donation}) async {
    await Get.to(
      () => MakeDonationScreen(preselected: donation),
      transition: Transition.rightToLeft,
    );
  }

  @override
  State<MakeDonationScreen> createState() => _MakeDonationScreenState();
}

class _MakeDonationScreenState extends State<MakeDonationScreen> {
  final _amountCtrl = TextEditingController();
  static const _quickAmounts = <int>[500, 1000, 2000, 5000];

  late final DonateController _donateCtrl;
  Donation? _selected;
  String? _inlineError;
  bool _loadingCauses = false;

  @override
  void initState() {
    super.initState();
    _donateCtrl = Get.find<DonateController>();
    _donateCtrl.reset();
    _selected = widget.preselected;
    _bootstrapCauses();
  }

  Future<void> _bootstrapCauses() async {
    if (!Get.isRegistered<DonationsListController>()) return;
    final listCtrl = Get.find<DonationsListController>();
    if (listCtrl.items.isEmpty) {
      setState(() => _loadingCauses = true);
      await listCtrl.refreshDonations();
      if (mounted) setState(() => _loadingCauses = false);
    }
    if (_selected == null && listCtrl.items.isNotEmpty) {
      setState(() => _selected = listCtrl.items.first);
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  List<Donation> get _causes {
    if (!Get.isRegistered<DonationsListController>()) return [];
    return Get.find<DonationsListController>().items;
  }

  String? _validate() {
    if (_selected == null) return 'Select a donation type.';
    final raw = _amountCtrl.text.trim();
    if (raw.isEmpty) return 'Enter an amount.';
    final parsed = num.tryParse(raw);
    if (parsed == null) return 'Enter a valid amount.';
    if (parsed < 10) return 'Minimum donation is R 10.';
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
      donationId: _selected!.id,
      amount: num.parse(_amountCtrl.text.trim()),
    );

    if (!mounted) return;
    if (init == null) {
      setState(() =>
          _inlineError = _donateCtrl.lastError ?? 'Could not start donation.');
      return;
    }
    Get.toNamed(AppRoutes.userDonationConfirming, arguments: init);
  }

  @override
  Widget build(BuildContext context) {
    final causes = _causes;

    if (_loadingCauses && causes.isEmpty) {
      return Scaffold(
        backgroundColor: DonationUi.background,
        appBar: DonationSimpleAppBar(title: 'Make Donation', onBack: Get.back),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: DonationUi.background,
      appBar: DonationSimpleAppBar(title: 'Make Donation', onBack: Get.back),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (causes.isNotEmpty) ...[
                    Text(
                      'Donation Type',
                      style: AppTypography.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: DonationUi.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...causes.map((d) {
                      final selected = _selected?.id == d.id;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: () => setState(() {
                              _selected = d;
                              _inlineError = null;
                            }),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selected
                                      ? DonationUi.headerOrange
                                      : DonationUi.cardBorder,
                                  width: selected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    selected
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_off,
                                    color: selected
                                        ? DonationUi.headerOrange
                                        : DonationUi.textMuted,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      d.title,
                                      style: AppTypography.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: DonationUi.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 20),
                  ],
                  Text(
                    'Enter Amount',
                    style: AppTypography.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: DonationUi.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _amountCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: _fieldDecoration(
                      hintText: '0',
                      prefixText: 'R ',
                    ),
                    onChanged: (_) {
                      if (_inlineError != null) {
                        setState(() => _inlineError = null);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _quickAmounts
                        .map(
                          (v) => _AmountChip(
                            label: 'R $v',
                            onTap: () {
                              _amountCtrl.text = v.toString();
                              setState(() => _inlineError = null);
                            },
                          ),
                        )
                        .toList(),
                  ),
                  if (_inlineError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _inlineError!,
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
              child: Obx(
                () => CustomButton(
                  label: 'Donate Now',
                  textColor: Colors.white,
                  gradientColors: kFigmaActionGradient,
                  borderRadius: 14,
                  isLoading: _donateCtrl.isInitiating,
                  onTap: _submit,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration({String? hintText, String? prefixText}) {
    return InputDecoration(
      hintText: hintText,
      prefixText: prefixText,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: DonationUi.cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: DonationUi.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: DonationUi.headerOrange, width: 1.5),
      ),
    );
  }
}

class _AmountChip extends StatelessWidget {
  const _AmountChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: DonationUi.cardBorder),
          ),
          child: Text(
            label,
            style: AppTypography.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: DonationUi.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
