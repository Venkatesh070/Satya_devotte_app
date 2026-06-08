import 'dart:math' as math;

import 'package:flutter/material.dart';

class ChakraLoadingIndicator extends StatefulWidget {
  const ChakraLoadingIndicator({super.key, this.size = 24, this.color});

  final double size;
  final Color? color;

  @override
  State<ChakraLoadingIndicator> createState() => _ChakraLoadingIndicatorState();
}

class _ChakraLoadingIndicatorState extends State<ChakraLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.rotate(
            angle: _controller.value * 2 * math.pi,
            child: child,
          );
        },
        child: Image.asset(
          'assets/images/chakra4.png',
          color: widget.color,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}
