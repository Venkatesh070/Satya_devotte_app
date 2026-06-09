import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/core/services/app_music_service.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/features/donations/data/models/verify_result.dart';
import 'package:satya_devotte_app/features/donations/presentation/widgets/donation_ui.dart';
import 'package:satya_devotte_app/features/profile/presentation/widgets/profile_ui.dart';

class DonationSuccessScreen extends StatefulWidget {
  const DonationSuccessScreen({super.key});

  @override
  State<DonationSuccessScreen> createState() => _DonationSuccessScreenState();
}

class _DonationSuccessScreenState extends State<DonationSuccessScreen>
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

    // Auto-navigate after delay
    Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      Get.offAllNamed(AppRoutes.home);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.toNamed(AppRoutes.userContributions);
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
    final amount = _result.amount;
    final currency = _result.currency ?? 'ZAR';
    final amountText = amount == null
        ? null
        : NumberFormat.currency(
            name: currency,
            symbol: '${currency == 'ZAR' ? 'R' : currency} ',
            decimalDigits: amount.truncateToDouble() == amount ? 0 : 2,
          ).format(amount);
    final title = _result.contribution?.donationTitle ?? 'Donation';
    final number = _result.contribution?.contributionNumber ?? '';
    final date = _result.contribution?.formattedDate ?? '';

    return Scaffold(
      backgroundColor: DonationUi.background,
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  Center(
                    child: AnimatedBuilder(
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
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: DonationUi.successGreen.withValues(
                                        alpha: .35,
                                      ),
                                      width: 3,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Transform.scale(
                              scale: _badgeScale.value,
                              child: Container(
                                width: 96,
                                height: 96,
                                decoration: const BoxDecoration(
                                  color: DonationUi.successGreen,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0x331F8A4C),
                                      blurRadius: 24,
                                      offset: Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Transform.scale(
                                  scale: _checkScale.value,
                                  child: const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 56,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Thank you for your donation!',
                    textAlign: TextAlign.center,
                    style: AppTypography.lora(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: DonationUi.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: DonationUi.cardFill,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: DonationUi.cardBorder),
                    ),
                    child: Column(
                      children: [
                        _Row('Purpose', title),
                        if (amountText != null) ...[
                          const SizedBox(height: 12),
                          _Row('Amount', amountText),
                        ],
                        if (number.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _Row('Receipt', '#$number'),
                        ],
                        if (date.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _Row('Date', date),
                        ],
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Redirecting to history...',
                    textAlign: TextAlign.center,
                    style: AppTypography.inter(
                      fontSize: 12,
                      color: DonationUi.textMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.inter(fontSize: 13, color: DonationUi.textMuted),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTypography.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: DonationUi.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _SuccessBurstPainter extends CustomPainter {
  const _SuccessBurstPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 100);
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    final colors = [
      const Color(0xFFED5A00), // headerOrange
      const Color(0xFF1F4CB7), // amountBlue
      const Color(0xFF1F8A4C), // successGreen
      const Color(0xFFFFC857),
    ];

    final random = math.Random(42);
    for (int i = 0; i < 30; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final distance = 60 + random.nextDouble() * 120 * progress;
      final particleSize = (1 - progress) * (2 + random.nextDouble() * 4);
      final offset = Offset(
        center.dx + math.cos(angle) * distance,
        center.dy + math.sin(angle) * distance,
      );

      paint.color = colors[random.nextInt(colors.length)].withValues(
        alpha: 1 - progress,
      );
      canvas.drawCircle(offset, particleSize, paint);
    }
  }

  @override
  bool shouldRepaint(_SuccessBurstPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
