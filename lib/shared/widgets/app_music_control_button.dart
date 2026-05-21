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
    this.enableTooltip = false,
    this.tooltipMessage,
  });

  final double size;
  final double borderRadius;
  final double iconSize;

  /// Floating FAB uses gradient only (no shadow).
  final bool showShadow;

  /// Shows hover tooltip (web CMS). Uses [tooltipMessage] or play/pause text.
  final bool enableTooltip;

  /// Optional fixed tooltip; when null and [enableTooltip], toggles with playback.
  final String? tooltipMessage;

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

      final Widget button;
      if (showShadow) {
        button = Material(
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
      } else {
        button = GestureDetector(
          onTap: music.toggle,
          child: Container(
            width: size,
            height: size,
            decoration: decoration,
            child: Center(child: icon),
          ),
        );
      }

      if (!enableTooltip) return button;

      final message = tooltipMessage ??
          (playing
              ? 'Pause background music'
              : 'Play background music');

      return Tooltip(
        message: message,
        waitDuration: const Duration(milliseconds: 350),
        child: button,
      );
    });
  }
}
