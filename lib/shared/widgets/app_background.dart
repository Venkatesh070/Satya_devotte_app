import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({
    super.key,
    required this.child,
    this.showPattern = false,
  });

  final Widget child;
  final bool showPattern;

  static const String assetPath = 'assets/images/pooja_step_bg.png';
  static const String bottomChakraAssetPath = 'assets/images/footerImg.png';
  static const String sideChakraAssetPath = 'assets/images/vector1.png';
  static const String topChakraAssetPath = 'assets/images/vector2.png';

  // ← This is the glow blob you exported from Figma
  static const String glowAssetPath = 'assets/images/vector2.png';
  // 👆 Replace with whatever you named the exported glow PNG

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final bottomChakraSize = size.width * 1.28;
    final vectorSize = size.width * 0.86;
    final glowSize = size.width * 1.1; // slightly wider than screen

    return SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── 1. Base background ──
          Image.asset(
            assetPath,
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

          // ── 2. Glow blob — bottom center (matches Figma) ──
          Positioned(
            left: (size.width - glowSize) / 2, // centered horizontally
            bottom: -glowSize * 0.15, // slightly off-screen bottom
            child: Image.asset(
              glowAssetPath,
              width: glowSize,
              height: glowSize,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),

          // ── 3. Bottom chakra (on top of glow) ──
          Positioned(
            left: (size.width - bottomChakraSize) / 2,
            bottom: -bottomChakraSize * 0.09,
            child: Image.asset(
              bottomChakraAssetPath,
              width: bottomChakraSize,
              height: bottomChakraSize,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),

          // ── 4. Pattern overlays ──
          if (showPattern)
            Positioned(
              left: (size.width - vectorSize) / 2,
              top: size.height * 0.28,
              child: Opacity(
                opacity: 0.28,
                child: Image.asset(
                  topChakraAssetPath,
                  width: vectorSize,
                  height: vectorSize,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),

          if (showPattern)
            Positioned(
              left: (size.width - vectorSize) / 2,
              top: size.height * 0.54,
              child: Opacity(
                opacity: 1,
                child: Image.asset(
                  sideChakraAssetPath,
                  width: vectorSize,
                  height: vectorSize,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),

          child,
        ],
      ),
    );
  }
}
