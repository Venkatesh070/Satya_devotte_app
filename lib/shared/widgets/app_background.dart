import 'dart:math' as math;

import 'package:flutter/material.dart';

class AppBackground extends StatefulWidget {
  const AppBackground({
    super.key,
    required this.child,
    this.showPattern = false,
    this.rotateFooter = false,
    this.animatePatterns = false,
  });

  final Widget child;
  final bool showPattern;
  final bool rotateFooter;
  final bool animatePatterns;

  static const String assetPath = 'assets/images/pooja_step_bg.png';
  static const String bottomChakraAssetPath = 'assets/images/flowerImg.png';
  static const String sideChakraAssetPath = 'assets/images/vector1.png';
  static const String topChakraAssetPath = 'assets/images/vector2.png';
  static const String glowAssetPath = 'assets/images/vector2.png';

  @override
  State<AppBackground> createState() => _AppBackgroundState();
}

class _AppBackgroundState extends State<AppBackground>
    with SingleTickerProviderStateMixin {
  AnimationController? _rotationController;

  bool get _needsAnimation =>
      widget.rotateFooter || (widget.showPattern && widget.animatePatterns);

  @override
  void initState() {
    super.initState();
    if (_needsAnimation) {
      _rotationController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 20),
      )..repeat();
    }
  }

  @override
  void didUpdateWidget(AppBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    final needsAnimation = _needsAnimation;
    if (needsAnimation && _rotationController == null) {
      _rotationController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 20),
      )..repeat();
    } else if (!needsAnimation && _rotationController != null) {
      _rotationController!.dispose();
      _rotationController = null;
    }
  }

  @override
  void dispose() {
    _rotationController?.dispose();
    super.dispose();
  }

  Widget _rotatingPattern({
    required Widget child,
    required bool counterClockwise,
  }) {
    final controller = _rotationController;
    if (controller == null) return child;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, patternChild) {
        final spin = controller.value * 2 * math.pi;
        return Transform.rotate(
          angle: counterClockwise ? -spin : spin,
          child: patternChild,
        );
      },
      child: child,
    );
  }

  Widget _footerImage({required double width, required double height}) {
    final image = Image.asset(
      AppBackground.bottomChakraAssetPath,
      width: width,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );

    final controller = _rotationController;
    if (widget.rotateFooter && controller != null) {
      return RotationTransition(turns: controller, child: image);
    }
    return image;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final bottomChakraSize = size.width * 1.28;
    final vectorSize = size.width * 0.86;
    final glowSize = size.width * 1.1;

    return SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            AppBackground.assetPath,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF120B05),
                    Color(0xFF8A151B),
                    Color(0xFFEF6400),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: (size.width - glowSize) / 2,
            bottom: -glowSize * 0.28,
            child: Image.asset(
              AppBackground.glowAssetPath,
              width: glowSize,
              height: glowSize,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
          Positioned(
            left: (size.width - bottomChakraSize) / 2,
            bottom: -bottomChakraSize * 0.50,
            child: _footerImage(
              width: bottomChakraSize,
              height: bottomChakraSize,
            ),
          ),
          if (widget.showPattern)
            Positioned(
              left: (size.width - vectorSize) / 2,
              top: size.height * 0.28,
              child: Opacity(
                opacity: 0.28,
                child: widget.animatePatterns
                    ? _rotatingPattern(
                        counterClockwise: false,
                        child: Image.asset(
                          AppBackground.topChakraAssetPath,
                          width: vectorSize,
                          height: vectorSize,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      )
                    : Image.asset(
                        AppBackground.topChakraAssetPath,
                        width: vectorSize,
                        height: vectorSize,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
              ),
            ),
          if (widget.showPattern)
            Positioned(
              left: (size.width - vectorSize) / 2,
              top: size.height * 0.54,
              child: Opacity(
                opacity: 1,
                child: widget.animatePatterns
                    ? _rotatingPattern(
                        counterClockwise: true,
                        child: Image.asset(
                          AppBackground.sideChakraAssetPath,
                          width: vectorSize,
                          height: vectorSize,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      )
                    : Image.asset(
                        AppBackground.sideChakraAssetPath,
                        width: vectorSize,
                        height: vectorSize,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
              ),
            ),
          widget.child,
        ],
      ),
    );
  }
}
