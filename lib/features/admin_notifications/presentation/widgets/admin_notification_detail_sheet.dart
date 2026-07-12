import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:satya_devotte_app/features/admin_notifications/data/models/admin_notification_item.dart';
import 'package:satya_devotte_app/features/admin_notifications/presentation/controllers/cms_admin_notifications_controller.dart';

class AdminNotificationDetailSheet extends StatelessWidget {
  const AdminNotificationDetailSheet({
    super.key,
    required this.item,
    required this.onView,
  });

  final AdminNotificationItem item;
  final VoidCallback onView;

  static const Color _navy = Color(0xFF1A2A4A);

  @override
  Widget build(BuildContext context) {
    final created = DateFormat.yMMMd().add_jm().format(item.createdAt.toLocal());
    final refs = <String, String>{
      if (item.orderNumber != null) 'Order #': item.orderNumber!,
      if (item.contributionNumber != null)
        'Contribution #': item.contributionNumber!,
      if (item.requestNumber != null) 'Request #': item.requestNumber!,
      if (item.paymentReference != null)
        'Payment ref': item.paymentReference!,
    };

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.paddingOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _navy,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          Text(
            created,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),
          Text(
            item.body,
            style: const TextStyle(fontSize: 14, height: 1.45, color: _navy),
          ),
          if (refs.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'References',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 8),
            ...refs.entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.key,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                          Text(
                            e.value,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: _navy,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Copy',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: e.value));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Copied ${e.key}')),
                        );
                      },
                      icon: const Icon(Icons.copy_outlined, size: 18),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              onView();
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFF5A623),
              foregroundColor: Color(0xFFFCF7EF),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('View'),
          ),
        ],
      ),
    );
  }

  static Future<void> show(
    BuildContext context,
    AdminNotificationItem item,
  ) async {
    final ctrl = Get.find<CmsAdminNotificationsController>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => AdminNotificationDetailSheet(
        item: item,
        onView: () => ctrl.markReadAndOpen(item),
      ),
    );
  }
}
