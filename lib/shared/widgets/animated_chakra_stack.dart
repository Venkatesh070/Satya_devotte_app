import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Rotating chakra rings (chakra1–4 + overlay).
class AnimatedChakraStack extends StatelessWidget {
  const AnimatedChakraStack({
    super.key,
    required this.rotationController,
    this.verticalOffset = -24,
    this.showOverlay = true,
    this.logo,
  });

  final AnimationController rotationController;
  final double verticalOffset;
  final bool showOverlay;
  final Widget? logo;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Transform.translate(
        offset: Offset(0, verticalOffset),
        child: AnimatedBuilder(
          animation: rotationController,
          builder: (context, child) {
            final spin = rotationController.value * 2 * math.pi;
            return Stack(
              alignment: Alignment.center,
              children: [
                Transform.rotate(
                  angle: spin,
                  child: Image.asset(
                    'assets/images/chakra1.png',
                    filterQuality: FilterQuality.high,
                    gaplessPlayback: true,
                  ),
                ),
                Transform.rotate(
                  angle: -spin,
                  child: Transform.scale(
                    scale: 0.90,
                    child: Image.asset(
                      'assets/images/chakra2.png',
                      filterQuality: FilterQuality.high,
                      gaplessPlayback: true,
                    ),
                  ),
                ),
                Transform.rotate(
                  angle: spin,
                  child: Transform.scale(
                    scale: 0.80,
                    child: Image.asset(
                      'assets/images/chakra3.png',
                      filterQuality: FilterQuality.high,
                      gaplessPlayback: true,
                    ),
                  ),
                ),
                Transform.rotate(
                  angle: -spin,
                  child: Transform.scale(
                    scale: 0.53,
                    child: Image.asset(
                      'assets/images/chakra4.png',
                      filterQuality: FilterQuality.high,
                      gaplessPlayback: true,
                    ),
                  ),
                ),
                if (showOverlay)
                  Opacity(
                    opacity: 0.8,
                    child: Image.asset(
                      'assets/images/onBoardBgOverlay.png',
                      filterQuality: FilterQuality.high,
                      gaplessPlayback: true,
                    ),
                  ),
                if (logo != null) logo!,
              ],
            );
          },
        ),
      ),
    );
  }
}
