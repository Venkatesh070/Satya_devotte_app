import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/core/network/api_client.dart';
import 'package:satya_devotte_app/core/network/api_endpoints.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
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

  Map<String, dynamic> _unwrap(dynamic raw) {
    if (raw is! Map) return const {};
    final map = Map<String, dynamic>.from(raw);
    final data = map['data'];
    if (data is Map) {
      final nested = Map<String, dynamic>.from(data);
      if (nested['ritual'] is Map) {
        return Map<String, dynamic>.from(nested['ritual'] as Map);
      }
      return nested;
    }
    return map;
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await Get.find<ApiClient>().dio.get(
        ApiEndpoints.ritual(widget.ritualId),
      );
      final ritual = RitualModel.fromJson(_unwrap(response.data));
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
                      child: _RitualDayCard(day: day),
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
      ...ritual.sections
          .where(
            (section) =>
                section.label.trim().isNotEmpty ||
                section.description.trim().isNotEmpty,
          )
          .map(
            (section) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RitualSectionCard(section: section),
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

class _RitualDayHeroImages extends StatelessWidget {
  const _RitualDayHeroImages({required this.images});

  final List<String> images;

  @override
  Widget build(BuildContext context) {
    Widget buildImage(String url) {
      return CachedNetworkImage(
        imageUrl: url,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          width: double.infinity,
          color: const Color(0xFFFAECD2),
          alignment: Alignment.center,
          child: const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (_, __, ___) => Container(
          width: double.infinity,
          color: const Color(0xFFFAECD2),
          alignment: Alignment.center,
          child: const Icon(
            Icons.broken_image_outlined,
            color: Color(0xFFB07A3A),
            size: 28,
          ),
        ),
      );
    }

    if (images.length == 1) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: buildImage(images.first),
      );
    }

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: PageView.builder(
        itemCount: images.length,
        itemBuilder: (_, index) => buildImage(images[index]),
      ),
    );
  }
}

class _RitualDayCard extends StatelessWidget {
  const _RitualDayCard({required this.day});

  final RitualDay day;

  @override
  Widget build(BuildContext context) {
    final title = day.title.trim().isEmpty
        ? 'Day ${day.stepNumber}'
        : 'Day ${day.stepNumber}: ${day.title.trim()}';

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7D5BC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Text(
              title,
              style: AppTypography.lora(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF4A1C00),
              ),
            ),
          ),
          if (day.images.isNotEmpty) ...[
            const SizedBox(height: 10),
            _RitualDayHeroImages(images: day.images),
          ],
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (day.description.trim().isNotEmpty) ...[
                  RichTextDisplay(
                    day.description,
                    style: AppTypography.inter(
                      fontSize: 13,
                      height: 1.4,
                      color: const Color(0xFF5C4634),
                    ),
                  ),
                ],
                if (day.subSteps.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Steps',
                    style: AppTypography.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF4A1C00),
                    ),
                  ),
                  const SizedBox(height: 6),
                  for (var i = 0; i < day.subSteps.length; i++) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${i + 1}.',
                          style: AppTypography.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFE35600),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: RichTextDisplay(
                            day.subSteps[i],
                            style: AppTypography.inter(
                              fontSize: 13,
                              height: 1.4,
                              color: const Color(0xFF5C4634),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (i != day.subSteps.length - 1) const SizedBox(height: 8),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RitualSectionCard extends StatelessWidget {
  const _RitualSectionCard({required this.section});

  final RitualSection section;

  @override
  Widget build(BuildContext context) {
    final description = section.description.trim();

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
            section.label,
            style: AppTypography.lora(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF4A1C00),
            ),
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 8),
            RichTextDisplay(
              description,
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
