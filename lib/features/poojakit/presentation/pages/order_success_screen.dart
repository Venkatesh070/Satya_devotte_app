// lib/features/poojakit/presentation/pages/order_success_screen.dart

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/features/donations/data/models/verify_result.dart';

class OrderSuccessScreen extends StatefulWidget {
  const OrderSuccessScreen({super.key});

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final VerifyResult _result;
  late final AnimationController _animation;
  late final Animation<double> _badgeScale;
  late final Animation<double> _checkScale;
  late final Animation<double> _ringOpacity;

  @override
  void initState() {
    super.initState();
    final arg = Get.arguments;
    _result = arg is VerifyResult ? arg : VerifyResult.empty();
    _animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
    _badgeScale = CurvedAnimation(
      parent: _animation,
      curve: const Interval(0, .55, curve: Curves.elasticOut),
    );
    _checkScale = CurvedAnimation(
      parent: _animation,
      curve: const Interval(.25, .72, curve: Curves.easeOutBack),
    );
    _ringOpacity = CurvedAnimation(
      parent: _animation,
      curve: const Interval(.15, 1, curve: Curves.easeOut),
    );

    _animation.addStatusListener(_onAnimationComplete);
  }

  void _onAnimationComplete(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _animation.removeStatusListener(_onAnimationComplete);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      Get.offAllNamed(AppRoutes.home);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Get.toNamed(AppRoutes.userOrders);
      });
    });
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        Get.offAllNamed(AppRoutes.home);
      },
      child: Scaffold(
        backgroundColor: AppColors.appBgColor,
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, _) => CustomPaint(
                    painter: _SuccessBurstPainter(progress: _animation.value),
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _animation,
                        builder: (context, _) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              Opacity(
                                opacity: 1 - _ringOpacity.value,
                                child: Transform.scale(
                                  scale: 1 + (_animation.value * .9),
                                  child: Container(
                                    width: 108,
                                    height: 108,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(
                                          0xFF18A978,
                                        ).withValues(alpha: .35),
                                        width: 3,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Transform.scale(
                                scale: _badgeScale.value,
                                child: Container(
                                  width: 84,
                                  height: 84,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF18A978),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(0x3318A978),
                                        blurRadius: 24,
                                        offset: Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Transform.scale(
                                    scale: _checkScale.value,
                                    child: const Icon(
                                      Icons.check_rounded,
                                      color: Color(0xFFFCF7EF),
                                      size: 48,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 26),
                      Text(
                        'Order Placed Successfully',
                        textAlign: TextAlign.center,
                        style: AppTypography.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF2B1A0C),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _result.reference.isEmpty
                            ? 'Order ID : ${_result.status.name.toUpperCase()}'
                            : 'Order ID : ${_result.reference}',
                        textAlign: TextAlign.center,
                        style: AppTypography.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF6C5B46),
                        ),
                      ),
                      const SizedBox(height: 210),
                      Text(
                        'We will email you with all the updated and tracking of your order shortly.\nThank you for shopping with us',
                        textAlign: TextAlign.center,
                        style: AppTypography.inter(
                          fontSize: 9,
                          height: 1.35,
                          color: const Color(0xFF9A7C61),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuccessBurstPainter extends CustomPainter {
  const _SuccessBurstPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 92);
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;
    const colors = [
      Color(0xFFE95700),
      Color(0xFF253FA8),
      Color(0xFF18A978),
      Color(0xFFFFC857),
    ];

    for (var i = 0; i < 18; i++) {
      final angle = (math.pi * 2 / 18) * i;
      final distance = 34 + (progress * 70);
      final opacity = (1 - progress).clamp(0.0, 1.0);
      paint.color = colors[i % colors.length].withValues(alpha: opacity);
      final dot = center + Offset(math.cos(angle), math.sin(angle)) * distance;
      canvas.drawCircle(dot, 2.5 + (i % 3), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SuccessBurstPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
