import 'package:flutter/material.dart';

class GradientOutlineInputBorder extends OutlineInputBorder {
  const GradientOutlineInputBorder({
    required this.gradient,
    super.borderRadius,
    super.borderSide = const BorderSide(width: 1),
    super.gapPadding,
  });

  final Gradient gradient;

  @override
  GradientOutlineInputBorder copyWith({
    BorderSide? borderSide,
    BorderRadius? borderRadius,
    double? gapPadding,
    Gradient? gradient,
  }) {
    return GradientOutlineInputBorder(
      gradient: gradient ?? this.gradient,
      borderRadius: borderRadius ?? this.borderRadius,
      borderSide: borderSide ?? this.borderSide,
      gapPadding: gapPadding ?? this.gapPadding,
    );
  }

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    double? gapStart,
    double gapExtent = 0,
    double gapPercentage = 0,
    TextDirection? textDirection,
  }) {
    final width = borderSide.width;
    if (width <= 0 || borderSide.style == BorderStyle.none) return;

    final rrect = borderRadius
        .resolve(textDirection)
        .toRRect(rect.deflate(width / 2));
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;

    canvas.drawRRect(rrect, paint);
  }
}
