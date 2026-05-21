import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Onboarding-style header: [onBoardBg3], rotating flower, chakra stack.
class OnboardingStyleBackground extends StatelessWidget {
  const OnboardingStyleBackground({
    super.key,
    required this.rotationController,
    this.chakraVerticalOffset = -55,
    this.wrapInPositioned = true,
  });

  final AnimationController rotationController;
  final double chakraVerticalOffset;
  final bool wrapInPositioned;

  @override
  Widget build(BuildContext context) {
    final stack = Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/onBoardBg3.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: -200,
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.topCenter,
              child: AnimatedBuilder(
                animation: rotationController,
                builder: (context, child) {
                  final spin = rotationController.value * 2 * math.pi;
                  return Transform.rotate(angle: spin, child: child);
                },
                child: Image.asset('assets/images/flowerImg.png'),
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 64, sigmaY: 64),
              child: SizedBox(
                width: 294.69,
                height: 294.69,
                child: Image.asset(
                  'assets/images/onBoardRightCorner.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Transform.translate(
              offset: Offset(0, chakraVerticalOffset),
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
                        ),
                      ),
                      Transform.rotate(
                        angle: -spin,
                        child: Transform.scale(
                          scale: 0.90,
                          child: Image.asset(
                            'assets/images/chakra2.png',
                            filterQuality: FilterQuality.high,
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
                          ),
                        ),
                      ),
                      Opacity(
                        opacity: 0.8,
                        child: Image.asset(
                          'assets/images/onBoardBgOverlay.png',
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      );
    return wrapInPositioned ? Positioned.fill(child: stack) : stack;
  }
}

/// Bottom footer image used on onboarding and login.
class OnboardingStyleFooter extends StatelessWidget {
  const OnboardingStyleFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: IgnorePointer(
        child: Image.asset(
          'assets/images/onBoardFooter.png',
          width: MediaQuery.sizeOf(context).width,
          fit: BoxFit.fitWidth,
          alignment: Alignment.bottomCenter,
        ),
      ),
    );
  }
}
