import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ChakraLoaderPage extends StatefulWidget {
  const ChakraLoaderPage({
    super.key,
    this.asOverlay = false,
  });

  final bool asOverlay;

  @override
  State<ChakraLoaderPage> createState() => _ChakraLoaderPageState();
}

class _ChakraLoaderPageState extends State<ChakraLoaderPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final overlayColor = widget.asOverlay
        ? Colors.black.withValues(alpha: 0.45)
        : Colors.transparent;
    const loaderSize = 150.0;
    final loaderBody = ColoredBox(
      color: overlayColor,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.center,
            child: Transform.translate(
              offset: const Offset(0, -55),
              child: AnimatedBuilder(
                animation: _rotationController,
                builder: (context, child) {
                  final spin = _rotationController.value * 8 * math.pi;
                  return SizedBox(
                    width: loaderSize,
                    height: loaderSize,
                    child: Stack(
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
                        SvgPicture.asset(
                          'assets/svgs/whiteLogo.svg',
                          width: 40,
                          height: 40,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );

    if (widget.asOverlay) {
      return Positioned.fill(
        child: IgnorePointer(
          child: loaderBody,
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: loaderBody,
    );
  }
}
