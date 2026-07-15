import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';

class ChakraLoaderPage extends StatelessWidget {
  const ChakraLoaderPage({super.key, this.asOverlay = false});

  final bool asOverlay;

  @override
  Widget build(BuildContext context) {
    final overlayColor = asOverlay
        ? Colors.black.withValues(alpha: 0.6)
        : Colors.transparent;
    final loaderBody = Container(
      color: overlayColor,
      child: Stack(
        children: [
          if (asOverlay)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
                child: const SizedBox.shrink(),
              ),
            ),
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Center(
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFED5A00), Color(0xFFFFD180)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: LoadingAnimationWidget.fourRotatingDots(
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (asOverlay) {
      return Positioned.fill(child: AbsorbPointer(child: loaderBody));
    }

    return Scaffold(backgroundColor: Colors.transparent, body: loaderBody);
  }
}
