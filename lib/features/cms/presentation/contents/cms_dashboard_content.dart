import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:satya_devotte_app/features/cms/presentation/pages/cms_shell_page.dart';

class CmsDashboardContent extends StatelessWidget {
  const CmsDashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isWeb = w >= 768;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isWeb ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Quick Actions ─────────────────────────────────
          if (!isWeb) ...[
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: CmsColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _QuickAction(
                    label: 'Manage Poojas',
                    icon: Icons.self_improvement,
                    color: CmsColors.orange,
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickAction(
                    label: 'Manage Festivals',
                    icon: Icons.celebration,
                    color: const Color(0xFF7B61FF),
                    onTap: () {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],

          // ── Stats grid ────────────────────────────────────
          _StatsGrid(isWeb: isWeb),
          const SizedBox(height: 24),

          // ── Two column on web ─────────────────────────────
          if (isWeb)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _TopPoojasList()),
                const SizedBox(width: 20),
                Expanded(flex: 2, child: _LeastOptedList()),
              ],
            )
          else ...[
            _TopPoojasList(),
            const SizedBox(height: 20),
            _LeastOptedList(),
          ],

          const SizedBox(height: 24),
          _DonationChart(),
        ],
      ),
    );
  }
}

// ── Quick Action Button ───────────────────────────────────────────
class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stats Grid ────────────────────────────────────────────────────
class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.isWeb});
  final bool isWeb;

  @override
  Widget build(BuildContext context) {
    final stats = [
      _StatData('Total Users', '520', Icons.people, const Color(0xFF4CAF50)),
      _StatData('Active Today', '24', Icons.person_pin, CmsColors.orange),
      _StatData(
        'Total Donations',
        '₹45,750',
        Icons.volunteer_activism,
        const Color(0xFF2196F3),
      ),
      _StatData(
        'Poojas',
        '12',
        Icons.self_improvement,
        const Color(0xFF9C27B0),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isWeb ? 4 : 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: isWeb ? 1.8 : 1.5,
      ),
      itemCount: stats.length,
      itemBuilder: (_, i) => _StatCard(data: stats[i]),
    );
  }
}

class _StatData {
  const _StatData(this.label, this.value, this.icon, this.color);
  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.data});
  final _StatData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CmsColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: data.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(data.icon, color: data.color, size: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: data.color,
                ),
              ),
              Text(
                data.label,
                style: const TextStyle(
                  fontSize: 11,
                  color: CmsColors.textSecond,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Top Poojas List ───────────────────────────────────────────────
class _TopPoojasList extends StatelessWidget {
  final _poojas = const [
    _PoojaData(
      'Ganesh Chaturthi Pooja',
      'Lord Ganesha',
      4.8,
      '#1',
      Color(0xFFF5A623),
    ),
    _PoojaData(
      'Lakshmi Pooja',
      'Goddess Lakshmi',
      4.6,
      '#2',
      Color(0xFF4CAF50),
    ),
    _PoojaData('Shiva Abhishekam', 'Lord Shiva', 4.5, '#3', Color(0xFF2196F3)),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CmsColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Poojas',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: CmsColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ..._poojas.map((p) => _PoojaRow(data: p)),
        ],
      ),
    );
  }
}

class _PoojaData {
  const _PoojaData(this.name, this.deity, this.rating, this.rank, this.color);
  final String name;
  final String deity;
  final double rating;
  final String rank;
  final Color color;
}

class _PoojaRow extends StatelessWidget {
  const _PoojaRow({required this.data});
  final _PoojaData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: data.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                data.rank,
                style: TextStyle(
                  color: data.color,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: CmsColors.textPrimary,
                  ),
                ),
                Text(
                  data.deity,
                  style: const TextStyle(
                    fontSize: 11,
                    color: CmsColors.textSecond,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              const Icon(Icons.star, size: 13, color: Color(0xFFF5A623)),
              const SizedBox(width: 3),
              Text(
                '${data.rating}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: CmsColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Least Opted Poojas ────────────────────────────────────────────
class _LeastOptedList extends StatelessWidget {
  final _poojas = const [
    _LeastData('Saraswati Vandana', 'Only 8 users opted', Color(0xFFFF7043)),
    _LeastData(
      'Hanuman Chalisa Path',
      'Only 12 users opted',
      Color(0xFFAB47BC),
    ),
    _LeastData('Durga Path', 'Only 5 users opted', Color(0xFF26A69A)),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CmsColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Least Opted Poojas',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: CmsColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ..._poojas.map((p) => _LeastRow(data: p)),
        ],
      ),
    );
  }
}

class _LeastData {
  const _LeastData(this.name, this.sub, this.color);
  final String name;
  final String sub;
  final Color color;
}

class _LeastRow extends StatelessWidget {
  const _LeastRow({required this.data});
  final _LeastData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 36,
            decoration: BoxDecoration(
              color: data.color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: CmsColors.textPrimary,
                  ),
                ),
                Text(
                  data.sub,
                  style: TextStyle(fontSize: 11, color: data.color),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey.shade300),
        ],
      ),
    );
  }
}

// ── Donation Chart ────────────────────────────────────────────────
class _DonationChart extends StatelessWidget {
  final _months = const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
  final _values = const [0.4, 0.6, 0.5, 0.8, 0.65, 0.9];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CmsColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Monthly Donation Trend',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: CmsColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '+14% growth from last month',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF4CAF50),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_months.length, (i) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AnimatedContainer(
                      duration: Duration(milliseconds: 300 + i * 100),
                      width: 28,
                      height: _values[i] * 80,
                      decoration: BoxDecoration(
                        color: i == _values.length - 1
                            ? CmsColors.orange
                            : CmsColors.orange.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _months[i],
                      style: const TextStyle(
                        fontSize: 10,
                        color: CmsColors.textSecond,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
