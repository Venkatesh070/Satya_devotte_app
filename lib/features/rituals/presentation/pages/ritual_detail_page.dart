import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/features/rituals/presentation/controllers/ritual_controller.dart';
import 'package:satya_devotte_app/features/rituals/presentation/widgets/media_player_section.dart';
import 'package:satya_devotte_app/features/rituals/presentation/widgets/step_timeline.dart';

class RitualDetailPage extends GetView<RitualController> {
  const RitualDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ritualId = Get.arguments as String;
    controller.loadRitualDetail(ritualId);

    return Scaffold(
      appBar: AppBar(title: const Text('Ritual Detail')),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        final ritual = controller.selectedRitual.value;
        if (ritual == null) {
          return const Center(child: Text('No ritual found'));
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ritual.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(ritual.description),
              const SizedBox(height: 16),
              MediaPlayerSection(mediaUrl: ritual.mediaUrl),
              const SizedBox(height: 16),
              StepTimeline(steps: ritual.steps),
            ],
          ),
        );
      }),
    );
  }
}
