// lib/features/cms/presentation/widgets/admin_verify_pickup_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';

/// Admin enters the customer's 6-digit pickup PIN to complete the order.
class AdminVerifyPickupDialog extends StatefulWidget {
  const AdminVerifyPickupDialog({super.key});

  static Future<String?> show(BuildContext context) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AdminVerifyPickupDialog(),
    );
  }

  @override
  State<AdminVerifyPickupDialog> createState() =>
      _AdminVerifyPickupDialogState();
}

class _AdminVerifyPickupDialogState extends State<AdminVerifyPickupDialog> {
  final _ctrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final pin = _ctrl.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
      setState(() => _error = 'Enter the 6-digit PIN from the customer\'s app.');
      return;
    }
    Navigator.of(context).pop(pin);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Mark picked up (verify PIN)',
        style: AppTypography.inter(fontWeight: FontWeight.w700),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ask the customer for their collection PIN and enter it below to mark the order as collected.',
            style: AppTypography.inter(fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            keyboardType: TextInputType.number,
            maxLength: 6,
            autofocus: true,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'Pickup PIN',
              counterText: '',
              errorText: _error,
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Verify & complete'),
        ),
      ],
    );
  }
}
