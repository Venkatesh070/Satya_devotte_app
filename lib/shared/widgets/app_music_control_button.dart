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
    this.showShadow = true,
  });

  final double size;
  final double borderRadius;
  final double iconSize;

  /// Floating FAB uses gradient only (no shadow).
  final bool showShadow;

  static const _gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.gradientStart, AppColors.gradientEnd],
  );

  @override
  Widget build(BuildContext context) {
    final music = Get.find<AppMusicService>();

    return Obx(() {
      final playing = music.isPlaying.value;
      final decoration = BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: _gradient,
        boxShadow: showShadow
            ? const [
                BoxShadow(
                  color: Color(0x33ED5A00),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ]
            : null,
      );

      final icon = Icon(
        playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
        color: AppColors.white,
        size: iconSize,
      );

      if (showShadow) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: music.toggle,
            borderRadius: BorderRadius.circular(borderRadius),
            child: Ink(
              width: size,
              height: size,
              decoration: decoration,
              child: Center(child: icon),
            ),
          ),
        );
      }

      return GestureDetector(
        onTap: music.toggle,
        child: Container(
          width: size,
          height: size,
          decoration: decoration,
          child: Center(child: icon),
        ),
      );
    });
  }
}
