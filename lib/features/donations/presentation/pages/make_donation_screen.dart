import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/features/donations/data/models/donation.dart';
import 'package:satya_devotte_app/features/donations/presentation/widgets/donation_ui.dart';
import 'package:satya_devotte_app/features/donations/state/donate_controller.dart';
import 'package:satya_devotte_app/shared/widgets/gradient_outline_input_border.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';
import 'package:satya_devotte_app/shared/widgets/rich_text_display.dart';

/// Figma "Make a Donation" bottom sheet.
class MakeDonationScreen extends StatefulWidget {
  const MakeDonationScreen({super.key, this.donation});

  final Donation? donation;

  static const _presetAmounts = <int>[100, 250, 500, 1000, 2000, 5000];

  static Future<void> show(BuildContext context, {Donation? donation}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final viewInsets = MediaQuery.viewInsetsOf(sheetContext).bottom;
        final maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.88;
        return Padding(
          padding: EdgeInsets.only(bottom: viewInsets),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: MakeDonationScreen(donation: donation),
          ),
        );
      },
    );
  }

  /// Back-compat for call sites that used navigation.
  static Future<void> open({Donation? donation, BuildContext? context}) {
    final ctx = context ?? Get.context;
    if (ctx == null) return Future.value();
    return show(ctx, donation: donation);
  }

  @override
  State<MakeDonationScreen> createState() => _MakeDonationScreenState();
}

class _MakeDonationScreenState extends State<MakeDonationScreen> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  late final DonateController _donateCtrl;
  int? _selectedPreset;
  String? _inlineError;

  @override
  void initState() {
    super.initState();
    _donateCtrl = Get.find<DonateController>();
    _donateCtrl.reset();
    _selectedPreset = 500;
    _amountCtrl.text = '500';
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
    if (parsed < 10) return 'Minimum contribution is R 10.';
    if (_noteCtrl.text.trim().length > 280) {
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
      donationId: widget.donation?.id,
      amount: num.parse(_amountCtrl.text.trim()),
      note: _noteCtrl.text.trim(),
    );

    if (!mounted) return;
    if (init == null) {
      setState(
        () => _inlineError =
            _donateCtrl.lastError ?? 'Could not start contribution.',
      );
      return;
    }
    Navigator.of(context).pop();
    Get.toNamed(AppRoutes.userDonationConfirming, arguments: init);
  }

  void _selectPreset(int value) {
    setState(() {
      _selectedPreset = value;
      _amountCtrl.text = value.toString();
      _inlineError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DonationUi.background,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: DonationUi.cardBorder,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: DonationUi.textMuted,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Make a Contribution',
                    style: AppTypography.lora(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: DonationUi.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your contribution can make a difference.',
                    style: AppTypography.inter(
                      fontSize: 14,
                      color: DonationUi.textMuted,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (widget.donation != null) ...[
                    _SelectedCauseCard(donation: widget.donation!),
                    const SizedBox(height: 24),
                  ],
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF183EA4), Color(0xFFE35600)],
                    ).createShader(bounds),
                    child: Text(
                      'Select Amount',
                      style: AppTypography.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 30,
                    crossAxisSpacing: 30,
                    childAspectRatio: 1.9,
                    children: MakeDonationScreen._presetAmounts.map((v) {
                      return _AmountPresetTile(
                        label: 'R $v',
                        selected: _selectedPreset == v,
                        onTap: () => _selectPreset(v),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF183EA4), Color(0xFFE35600)],
                    ).createShader(bounds),
                    child: Text(
                      'Or Enter Custom Amount',
                      style: AppTypography.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: _fieldDecoration(prefixText: 'R '),
                    onChanged: (v) {
                      final parsed = int.tryParse(v.trim());
                      setState(() {
                        _selectedPreset =
                            MakeDonationScreen._presetAmounts.contains(parsed)
                            ? parsed
                            : null;
                        _inlineError = null;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF183EA4), Color(0xFFE35600)],
                    ).createShader(bounds),
                    child: Text(
                      'Add Note',
                      style: AppTypography.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _noteCtrl,
                    minLines: 3,
                    maxLines: 5,
                    maxLength: 280,
                    textInputAction: TextInputAction.newline,
                    decoration: _fieldDecoration(
                      hintText: 'Write a note or prayer...',
                      prefixText: null,
                      alignLabelWithHint: true,
                    ),
                    onChanged: (_) {
                      if (_inlineError != null) {
                        setState(() => _inlineError = null);
                      }
                    },
                  ),
                  if (_inlineError != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _inlineError!,
                      style: AppTypography.inter(
                        fontSize: 12,
                        color: const Color(0xFFB10F1A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Obx(
                () => SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: _donateCtrl.isInitiating
                          ? null
                          : const LinearGradient(
                              colors: [Color(0xFF183EA4), Color(0xFFE35600)],
                            ),
                      borderRadius: BorderRadius.circular(14),
                      color: _donateCtrl.isInitiating
                          ? DonationUi.amountBlue.withOpacity(0.55)
                          : null,
                    ),
                    child: ElevatedButton(
                      onPressed: _donateCtrl.isInitiating
                          ? null
                          : () => _submit(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _donateCtrl.isInitiating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Make Contribution',
                              style: AppTypography.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration({
    String? hintText,
    String? prefixText = 'R ',
    bool alignLabelWithHint = false,
  }) {
    const gradient = LinearGradient(
      colors: [Color(0xFF421204), Color(0xFF8B2C0F), Color(0xFFC04E15)],
    );

    return InputDecoration(
      hintText: hintText,
      prefixText: prefixText,
      prefixStyle: AppTypography.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: DonationUi.textPrimary,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      alignLabelWithHint: alignLabelWithHint,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFF3E5D0)),
      ),
      focusedBorder: GradientOutlineInputBorder(
        gradient: gradient,
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(width: 1.5),
      ),
      filled: true,
      fillColor: const Color(0xFFFDF9F2),
    );
  }
}

class _SelectedCauseCard extends StatelessWidget {
  const _SelectedCauseCard({required this.donation});

  final Donation donation;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DonationUi.cardFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DonationUi.cardBorder),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 48,
              height: 48,
              child: _CauseImage(url: donation.imageUrl),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  donation.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: DonationUi.text,
                  ),
                ),
                RichTextDisplay(
                  donation.description,
                  style: AppTypography.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: DonationUi.text,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CauseImage extends StatelessWidget {
  const _CauseImage({this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: const Color(0xFFEADCC3),
      child: const Icon(Icons.volunteer_activism, color: Color(0xFF8C5A2A)),
    );
    if (url == null || url!.isEmpty) return placeholder;
    if (url!.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: url!,
        fit: BoxFit.cover,
        placeholder: (_, _) => placeholder,
        errorWidget: (_, _, _) => placeholder,
      );
    }
    return Image.asset(
      url!,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => placeholder,
    );
  }
}

class _AmountPresetTile extends StatelessWidget {
  const _AmountPresetTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? null : Colors.white,
          gradient: selected
              ? const LinearGradient(
                  colors: [
                    Color(0xFF421204),
                    Color(0xFF8B2C0F),
                    Color(0xFFC04E15),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? Colors.transparent : const Color(0xFFE8E8E8),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.inter(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? Colors.white : DonationUi.textPrimary,
          ),
        ),
      ),
    );
  }
}
