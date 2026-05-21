import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/core/services/app_music_service.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';

/// Pause/play control for background app music.
class AppMusicControlButton extends StatelessWidget {
  const AppMusicControlButton({
    super.key,
    this.size = 48,
    this.borderRadius = 24,
    this.iconSize = 26,
  });

  final double size;
  final double borderRadius;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final music = Get.find<AppMusicService>();

    return Obx(() {
      final playing = music.isPlaying.value;
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: music.toggle,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Ink(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.gradientStart, AppColors.gradientEnd],
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33ED5A00),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: AppColors.white,
                size: iconSize,
              ),
            ),
          ),
        ),
      );
    });
  }
}
