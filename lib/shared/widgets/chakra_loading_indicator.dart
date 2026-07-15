import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';

class ChakraLoadingIndicator extends StatelessWidget {
  const ChakraLoadingIndicator({super.key, this.size = 24, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    if (color != null) {
      return LoadingAnimationWidget.fourRotatingDots(
        color: color!,
        size: size,
      );
    }
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Color(0xFFED5A00), Color(0xFFFFD180)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds),
      child: LoadingAnimationWidget.fourRotatingDots(
        color: Colors.white,
        size: size,
      ),
    );
  }
}
