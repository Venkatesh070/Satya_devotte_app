import 'package:flutter/material.dart';

import 'package:satya_devotte_app/features/cms/data/models/admin_order_models.dart';
import 'package:satya_devotte_app/features/cms/presentation/pages/cms_shell_page.dart';
import 'package:satya_devotte_app/shared/widgets/order_tracking_progress.dart';

/// CMS wrapper around [OrderTrackingProgress] with admin panel colours.
class CmsOrderTrackingProgress extends StatelessWidget {
  const CmsOrderTrackingProgress({super.key, required this.order});

  final AdminOrder order;

  @override
  Widget build(BuildContext context) {
    return OrderTrackingProgress(
      order: order,
      activeColor: CmsColors.orangeDark,
      activeColorLight: CmsColors.orange,
      pendingColor: const Color(0xFFE0E0E0),
      titleColor: CmsColors.textPrimary,
      subtitleColor: CmsColors.textSecond,
      timeColor: CmsColors.textSecond,
    );
  }
}
