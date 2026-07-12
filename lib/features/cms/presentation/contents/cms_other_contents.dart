import 'package:flutter/material.dart';

// ════════════════════════════════════════════════════════════════
// ANALYTICS
// ════════════════════════════════════════════════════════════════
class CmsAnalyticsContent extends StatelessWidget {
  const CmsAnalyticsContent({super.key});

  static const _navy = Color(0xFF1A2A4A);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('Overview'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: const [
              _AnalyticCard(
                'Total Sessions',
                '4,820',
                Icons.touch_app,
                Colors.blue,
              ),
              _AnalyticCard(
                'Avg. Daily Users',
                '312',
                Icons.person,
                Color(0xFF1A2A4A),
              ),
              _AnalyticCard(
                'Rituals Completed',
                '1,540',
                Icons.self_improvement,
                Color(0xFFE8590A),
              ),
              _AnalyticCard(
                'Notif. Open Rate',
                '68%',
                Icons.notifications,
                Colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionTitle('Top Rituals This Month'),
          const SizedBox(height: 12),
          ...[
            ('Ganesh Chaturthi Pooja', 0.85),
            ('Lakshmi Pooja', 0.72),
            ('Shiva Abhishekam', 0.61),
            ('Hanuman Chalisa', 0.54),
            ('Saraswati Vandana', 0.40),
          ].map((e) => _RitualBar(name: e.$1, value: e.$2)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1A2A4A),
      ),
    );
  }
}

class _AnalyticCard extends StatelessWidget {
  const _AnalyticCard(this.label, this.value, this.icon, this.color);
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFFCF7EF),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
          ),
        ],
      ),
    );
  }
}

class _RitualBar extends StatelessWidget {
  const _RitualBar({required this.name, required this.value});
  final String name;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: const TextStyle(fontSize: 13, color: Color(0xFF333333)),
              ),
              Text(
                '${(value * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A2A4A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 8,
              backgroundColor: const Color(0xFFEEEEEE),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFE8590A)),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// APPROVAL  (Super Admin only)
// ════════════════════════════════════════════════════════════════
