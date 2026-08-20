import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/features/cms/data/datasources/ritual_remote_datasource.dart';
import 'package:satya_devotte_app/features/cms/models/ritual_model.dart';
import 'package:satya_devotte_app/shared/widgets/rich_text_display.dart';

class UserRitualDetailPage extends StatefulWidget {
  const UserRitualDetailPage({super.key, required this.ritualId});

  final String ritualId;

  @override
  State<UserRitualDetailPage> createState() => _UserRitualDetailPageState();
}

class _UserRitualDetailPageState extends State<UserRitualDetailPage> {
  bool _isLoading = true;
  String? _error;
  RitualModel? _ritual;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final ritual = await Get.find<RitualRemoteDataSource>().getRitualById(
        widget.ritualId,
      );
      if (!mounted) return;
      setState(() {
        _ritual = ritual;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load this ritual.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ritual = _ritual;
    return Scaffold(
      backgroundColor: AppColors.appBgColor,
      appBar: AppBar(
        backgroundColor: AppColors.appBgColor,
        elevation: 0,
        foregroundColor: const Color(0xFF4A1C00),
        title: Text(
          ritual?.title.trim().isNotEmpty == true ? ritual!.title : 'Ritual',
          style: AppTypography.lora(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF4A1C00),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.gradientEnd),
            )
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: AppTypography.inter(
                        fontSize: 14,
                        color: const Color(0xFF4A1C00),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _load,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gradientEnd,
                        foregroundColor: const Color(0xFFFCF7EF),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : ritual == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 36),
              children: [
                if ((ritual.imageUrl ?? '').trim().isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: CachedNetworkImage(
                        imageUrl: ritual.imageUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => const ColoredBox(
                          color: Color(0xFFFAECD2),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  ritual.title,
                  style: AppTypography.lora(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF4A1C00),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if ((ritual.category ?? '').trim().isNotEmpty)
                      _MetaChip(label: ritual.category!),
                    if ((ritual.ritualDays ?? ritual.days.length) > 0)
                      _MetaChip(
                        label:
                            '${ritual.ritualDays ?? ritual.days.length} days',
                      ),
                    if ((ritual.recommendedDuration ?? '').trim().isNotEmpty)
                      _MetaChip(label: ritual.recommendedDuration!),
                    if ((ritual.difficulty).trim().isNotEmpty)
                      _MetaChip(label: ritual.difficulty),
                  ],
                ),
                if ((ritual.description ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 18),
                  RichTextDisplay(
                    ritual.description,
                    style: AppTypography.inter(
                      fontSize: 14,
                      height: 1.45,
                      color: const Color(0xFF5C4634),
                    ),
                  ),
                ],
                if ((ritual.purpose ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Text(
                    'Purpose',
                    style: AppTypography.lora(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF4A1C00),
                    ),
                  ),
                  const SizedBox(height: 8),
                  RichTextDisplay(
                    ritual.purpose,
                    style: AppTypography.inter(
                      fontSize: 14,
                      height: 1.45,
                      color: const Color(0xFF5C4634),
                    ),
                  ),
                ],
                if (ritual.days.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  Text(
                    'Days',
                    style: AppTypography.lora(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF4A1C00),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...ritual.days.map(
                    (day) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _SectionCard(
                        title: day.title.trim().isEmpty
                            ? 'Day ${day.dayNumber}'
                            : 'Day ${day.dayNumber}: ${day.title}',
                        body: day.activities.join('\n'),
                      ),
                    ),
                  ),
                ],
                if (ritual.sections.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Sections',
                    style: AppTypography.lora(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF4A1C00),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...ritual.sections.map(
                    (section) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _SectionCard(
                        title: section.label,
                        body: section.contents
                            .map((c) => [c.title, c.description]
                                .where((s) => s.trim().isNotEmpty)
                                .join('\n'))
                            .where((s) => s.trim().isNotEmpty)
                            .join('\n\n'),
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0E4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTypography.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: const Color(0xFFE35600),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7D5BC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.lora(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF4A1C00),
            ),
          ),
          if (body.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            RichTextDisplay(
              body,
              style: AppTypography.inter(
                fontSize: 13,
                height: 1.4,
                color: const Color(0xFF5C4634),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
