import 'package:flutter/material.dart';

import 'package:satya_devotte_app/features/donations/data/models/donation_contribution.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final ContributionStatus status;

  ({String label, Color bg, Color fg}) _palette() {
    switch (status) {
      case ContributionStatus.paid:
        return (
          label: 'PAID',
          bg: const Color(0xFFE7F6EC),
          fg: const Color(0xFF1F8A4C),
        );
      case ContributionStatus.pending:
        return (
          label: 'PENDING',
          bg: const Color(0xFFFFF3E0),
          fg: const Color(0xFFB35A00),
        );
      case ContributionStatus.failed:
        return (
          label: 'FAILED',
          bg: const Color(0xFFFDECEC),
          fg: const Color(0xFFB10F1A),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _palette();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: p.bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        p.label,
        style: TextStyle(
          color: p.fg,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
