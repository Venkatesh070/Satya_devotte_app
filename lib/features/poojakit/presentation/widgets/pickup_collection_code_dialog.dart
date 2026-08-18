import 'package:flutter/material.dart';
import 'package:satya_devotte_app/core/utils/toast_util.dart';

/// Prompts the customer for the 6-digit warehouse collection code.
class PickupCollectionCodeDialog {
  PickupCollectionCodeDialog._();

  static Future<String?> show(BuildContext context) async {
    final ctrl = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Enter collection code'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter the 6-digit code from your email or order details.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                maxLength: 6,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: '6-digit code',
                  counterText: '',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final value = ctrl.text.trim();
                if (!RegExp(r'^\d{6}$').hasMatch(value)) {
                  ToastUtil.showError(
                    'Please enter the 6-digit collection code.',
                  );
                  return;
                }
                Navigator.of(ctx).pop(value);
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
    ctrl.dispose();
    return code;
  }
}
