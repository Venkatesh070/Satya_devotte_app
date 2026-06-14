import 'package:flutter/material.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
  });
  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.gradientStart, AppColors.gradientEnd],
                  ),
                ),
                child: Icon(icon, size: 16, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.lora(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF3B1E08),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class StoryCard extends StatelessWidget {
  const StoryCard({super.key, required this.title, required this.description});
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    if (description.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFFFCF7EF),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            Text(
              title,
              style: AppTypography.lora(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF1C1917),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),
            // Container(
            //   height: 2,
            //   width: 40,
            //   decoration: BoxDecoration(
            //     color: const Color(0xFFE69138).withOpacity(0.3),
            //     borderRadius: BorderRadius.circular(1),
            //   ),
            // ),
            // const SizedBox(height: 16),
          ],
          Text(
            description,
            style: AppTypography.inter(
              fontSize: 14,
              height: 1.6,
              color: const Color(0xFF1C1917),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class QuoteCard extends StatelessWidget {
  const QuoteCard({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.format_quote_rounded,
            size: 28,
            color: Color(0xFFB07A3A),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: AppTypography.inter(
              fontSize: 13.5,
              height: 1.6,
              color: const Color(0xFF4A1C00),
            ),
          ),
        ],
      ),
    );
  }
}

class BulletList extends StatelessWidget {
  const BulletList({
    super.key,
    required this.heading,
    required this.items,
    this.asChips = false,
    this.positive = true,
  });
  final String heading;
  final List<String> items;
  final bool asChips;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading,
            style: AppTypography.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF7A4621),
            ),
          ),
          const SizedBox(height: 8),
          if (asChips)
            ChipWrap(items: items, positive: positive)
          else
            ...items.map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 7, right: 10),
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Color(0xFFB07A3A),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        t,
                        style: AppTypography.inter(
                          fontSize: 13.5,
                          height: 1.5,
                          color: const Color(0xFF4A1C00),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ChipWrap extends StatelessWidget {
  const ChipWrap({super.key, required this.items, required this.positive});
  final List<String> items;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final bg = positive ? const Color(0xFFFFF1DD) : const Color(0xFFFFE3DC);
    final fg = positive ? const Color(0xFF7A4621) : const Color(0xFF8E2A12);
    final border = positive ? const Color(0x44B07A3A) : const Color(0x44B0432A);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .map(
            (t) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: border),
              ),
              child: Text(
                t,
                style: AppTypography.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.value,
    this.multiline = false,
  });
  final String label;
  final String value;
  final bool multiline;

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF8A6B4A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: multiline ? null : 2,
            overflow: multiline ? TextOverflow.visible : TextOverflow.ellipsis,
            style: AppTypography.inter(
              fontSize: 13.5,
              height: 1.5,
              color: const Color(0xFF3B1E08),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class LabeledChipsField extends StatelessWidget {
  const LabeledChipsField({
    super.key,
    required this.label,
    required this.items,
    this.positive = true,
  });
  final String label;
  final List<String> items;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF8A6B4A),
            ),
          ),
          const SizedBox(height: 8),
          ChipWrap(items: items, positive: positive),
        ],
      ),
    );
  }
}

class HeaderDivider extends StatelessWidget {
  const HeaderDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Image(
        image: AssetImage('assets/images/home/divider.png'),
        width: 145,
        fit: BoxFit.contain,
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, top: 4),
      child: Text(
        title,
        style: AppTypography.inter(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF4A1C00),
        ),
      ),
    );
  }
}

class DeitySectionCard extends StatelessWidget {
  const DeitySectionCard({super.key, required this.section});
  final Map<String, dynamic> section;

  String _title() {
    final t = section['title'];
    if (t is Map && t['value'] != null) return t['value'].toString();
    if (t is String) return t;
    return (section['key'] ?? 'Section').toString();
  }

  @override
  Widget build(BuildContext context) {
    final title = _title();
    final content = (section['content'] as List?) ?? const [];
    final summaryText = (section['description'] ?? section['text'] ?? '')
        .toString();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.lora(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF1C1917),
              height: 1.3,
            ),
          ),
          if (summaryText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              summaryText,
              style: AppTypography.inter(
                fontSize: 13,
                height: 1.55,
                color: const Color(0xFF4A1C00),
              ),
            ),
          ],
          if (content.isNotEmpty) const SizedBox(height: 10),
          for (final item in content.whereType<Map>())
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if ((item['title']?.toString() ?? '').isNotEmpty)
                    Text(
                      item['title'].toString(),
                      style: AppTypography.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF7A4621),
                      ),
                    ),
                  const SizedBox(height: 3),
                  if ((item['description']?.toString() ?? '').isNotEmpty)
                    Text(
                      item['description'].toString(),
                      style: AppTypography.inter(
                        fontSize: 13,
                        height: 1.5,
                        color: const Color(0xFF4A1C00),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
