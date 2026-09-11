// lib/features/cms/presentation/widgets/admin_verify_pickup_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:satya_devotte_app/features/cms/presentation/pages/cms_shell_page.dart';

/// Admin enters the customer's 6-digit pickup PIN to complete the order.
class AdminVerifyPickupDialog extends StatefulWidget {
  const AdminVerifyPickupDialog({super.key});

  static Future<String?> show(BuildContext context) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => const AdminVerifyPickupDialog(),
    );
  }

  @override
  State<AdminVerifyPickupDialog> createState() =>
      _AdminVerifyPickupDialogState();
}

class _AdminVerifyPickupDialogState extends State<AdminVerifyPickupDialog> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  String? _error;

  static const _pinLength = 6;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      if (_error != null) setState(() => _error = null);
      setState(() {});
    });
    _focus.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  String get _pin => _ctrl.text.trim();

  void _submit() {
    if (!RegExp(r'^\d{6}$').hasMatch(_pin)) {
      setState(
        () => _error = 'Enter the 6-digit collection PIN from the customer.',
      );
      return;
    }
    Navigator.of(context).pop(_pin);
  }

  @override
  Widget build(BuildContext context) {
    final filled = _pin.length;

    return Dialog(
      backgroundColor: CmsColors.white,
      elevation: 8,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: CmsColors.orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.pin_outlined,
                      color: CmsColors.orangeDark,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Verify collection PIN',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: CmsColors.textPrimary,
                            height: 1.25,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Ask the customer for the PIN shown in their app, then enter it below.',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: CmsColors.textSecond,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                'Collection PIN',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _error != null ? CmsColors.red : CmsColors.textSecond,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _focus.requestFocus(),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Invisible field captures keyboard / paste.
                    Opacity(
                      opacity: 0,
                      child: TextField(
                        controller: _ctrl,
                        focusNode: _focus,
                        keyboardType: TextInputType.number,
                        maxLength: _pinLength,
                        autofocus: true,
                        showCursor: false,
                        enableInteractiveSelection: false,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(_pinLength),
                        ],
                        decoration: const InputDecoration(
                          counterText: '',
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _submit(),
                      ),
                    ),
                    Row(
                      children: List.generate(_pinLength, (i) {
                        final hasDigit = i < filled;
                        final isActive = i == filled && _focus.hasFocus;
                        final hasError = _error != null;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: i == _pinLength - 1 ? 0 : 8,
                            ),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              height: 52,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: hasDigit
                                    ? CmsColors.orange.withValues(alpha: 0.08)
                                    : CmsColors.bg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: hasError
                                      ? CmsColors.red
                                      : isActive
                                          ? CmsColors.orange
                                          : hasDigit
                                              ? CmsColors.orange
                                                  .withValues(alpha: 0.55)
                                              : CmsColors.border,
                                  width: isActive || hasError ? 1.8 : 1.2,
                                ),
                              ),
                              child: Text(
                                hasDigit ? _pin[i] : '',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: CmsColors.textPrimary,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _error ?? '$filled / $_pinLength digits',
                      style: TextStyle(
                        fontSize: 12,
                        color: _error != null
                            ? CmsColors.red
                            : CmsColors.textSecond,
                      ),
                    ),
                  ),
                  if (filled > 0)
                    TextButton(
                      onPressed: () {
                        _ctrl.clear();
                        _focus.requestFocus();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: CmsColors.textSecond,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Clear', style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: CmsColors.textPrimary,
                        side: const BorderSide(color: CmsColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: filled == _pinLength ? _submit : null,
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text(
                        'Verify & complete',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CmsColors.orange,
                        foregroundColor: CmsColors.white,
                        disabledBackgroundColor:
                            CmsColors.orange.withValues(alpha: 0.35),
                        disabledForegroundColor:
                            CmsColors.white.withValues(alpha: 0.85),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
