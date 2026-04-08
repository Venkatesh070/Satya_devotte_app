import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/features/rituals/presentation/controllers/ritual_controller.dart';
import 'package:satya_devotte_app/features/rituals/presentation/widgets/ritual_card.dart';
import 'package:satya_devotte_app/shared/widgets/app_error_view.dart';

class RitualListPage extends GetView<RitualController> {
  const RitualListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rituals'),
        actions: [
          IconButton(
            onPressed: controller.syncRituals,
            icon: const Icon(Icons.sync),
          )
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.errorMessage.value.isNotEmpty) {
          return AppErrorView(
            message: controller.errorMessage.value,
            onRetry: controller.loadRituals,
          );
        }
        return ListView.builder(
          itemCount: controller.rituals.length,
          itemBuilder: (context, index) {
            final ritual = controller.rituals[index];
            return RitualCard(
              ritual: ritual,
              onTap: () => Get.toNamed(
                AppRoutes.ritualDetail,
                arguments: ritual.id,
              ),
            );
          },
        );
      }),
    );
  }
}
