import 'package:flutter/material.dart';
import 'package:satya_devotte_app/features/donations/data/models/donation_contribution.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final ContributionStatus status;

  ({String label, Color mainColor, Color foldColor}) _palette() {
    switch (status) {
      case ContributionStatus.paid:
        return (
          label: 'Paid',
          mainColor: const Color(0xFF4CAF50),
          foldColor: const Color(0xFF2E7D32),
        );
      case ContributionStatus.pending:
        return (
          label: 'Pending',
          mainColor: const Color(0xFFF99853),
          foldColor: const Color(0xFFB85C00),
        );
      case ContributionStatus.failed:
        return (
          label: 'Failed',
          mainColor: const Color(0xFFEF5350),
          foldColor: const Color(0xFFC62828),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _palette();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: p.mainColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(3),
              bottomLeft: Radius.circular(3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            p.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
        ),
        CustomPaint(
          size: const Size(6, 6),
          painter: _RibbonFoldPainter(color: p.foldColor),
        ),
      ],
    );
  }
}

class _RibbonFoldPainter extends CustomPainter {
  const _RibbonFoldPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _RibbonFoldPainter oldDelegate) =>
      oldDelegate.color != color;
}
