import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/features/donations/presentation/widgets/donation_ui.dart';
import 'package:satya_devotte_app/features/poojakit/bindings/user_orders_binding.dart';
import 'package:satya_devotte_app/features/poojakit/state/user_orders_controller.dart';

/// Figma Puja History — cream list with title + date/time.
class ProfilePoojaHistoryPage extends StatelessWidget {
  const ProfilePoojaHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<UserOrdersController>()) {
      UserOrdersBinding().dependencies();
    }
    final c = Get.find<UserOrdersController>();
    if (c.orders.isEmpty && !c.isLoading) {
      c.fetchOrders();
    }

    return Scaffold(
      backgroundColor: DonationUi.background,
      appBar: DonationSimpleAppBar(title: 'Puja History', onBack: Get.back),
      body: Obx(() {
        if (c.isLoading && c.orders.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (c.orders.isEmpty) {
          return Center(
            child: Text(
              'No puja history yet',
              style: AppTypography.inter(color: DonationUi.textMuted),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          itemCount: c.orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            final order = c.orders[i];
            final title = order.items.isNotEmpty
                ? order.items.first.title
                : 'Puja';
            final when = order.createdAt != null
                ? DateFormat('MMMM do, yyyy | h:mm a')
                    .format(order.createdAt!.toLocal())
                : '';
            return Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: () => Get.toNamed(
                  AppRoutes.userOrderDetail,
                  arguments: order.id,
                ),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: DonationUi.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: DonationUi.textPrimary,
                        ),
                      ),
                      if (when.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          when,
                          style: AppTypography.inter(
                            fontSize: 12,
                            color: DonationUi.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
