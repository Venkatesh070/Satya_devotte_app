import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/core/network/api_client.dart';
import 'package:satya_devotte_app/core/network/api_endpoints.dart';
import 'package:satya_devotte_app/core/services/offline_service.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';
import 'package:satya_devotte_app/features/profile/presentation/controllers/pooja_history_controller.dart';
import 'package:satya_devotte_app/features/pujas/presentation/models/pooja_view_model.dart';
import 'package:satya_devotte_app/shared/widgets/custom_button.dart';
import 'package:satya_devotte_app/shared/widgets/rich_text_display.dart';

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
        color: Color(0xFFFCF7EF),
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
                child: Icon(icon, size: 16, color: Color(0xFFFCF7EF)),
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
                fontSize: 14,
                fontWeight: FontWeight.bold,
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
          RichTextDisplay(
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
        color: Color(0xFFFCF7EF),
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
          RichTextDisplay(
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
        color: Color(0xFFFCF7EF),
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
            style: AppTypography.lora(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF8A6B4A),
            ),
          ),
          const SizedBox(height: 6),
          RichTextDisplay(
            value,
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
        color: Color(0xFFFCF7EF),
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
            style: AppTypography.lora(
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
        color: Color(0xFFFCF7EF),
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
          RichTextDisplay(
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
            RichTextDisplay(
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
                    RichTextDisplay(
                      item['title'].toString(),
                      style: AppTypography.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF7A4621),
                      ),
                    ),
                  const SizedBox(height: 3),
                  if ((item['description']?.toString() ?? '').isNotEmpty)
                    RichTextDisplay(
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

void showPujaPreviewModal(BuildContext context, PoojaView pooja) {
  final steps = pooja.steps;
  const gradientColors = [
    Color(0xFF2B55B1), // Blue
    Color(0xFFE35600), // Orange/Saffron
  ];

  final screenHeight = MediaQuery.sizeOf(context).height;

  Get.bottomSheet(
    SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(maxHeight: screenHeight * 0.85),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
        decoration: const BoxDecoration(
          color: Color(0xFFFCF7EF),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4.5,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            pooja.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F1F1F),
              height: 1.25,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _previewChip(
                Icons.timer_outlined,
                pooja.duration.isEmpty ? '2 hours' : pooja.duration,
              ),
              _previewChip(
                Icons.format_list_bulleted_rounded,
                '${steps.length} Steps',
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Steps',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(height: 10),
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  for (final step in steps)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: gradientColors,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '${step.number}',
                                style: const TextStyle(
                                  color: Color(0xFFFCF7EF),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                step.title,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF333333),
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: CustomButton(
              label: 'Begin Puja',
              borderRadius: 24,
              onTap: () {
                Get.back();
                final rawPooja = pooja.raw;
                dynamic scheduleId =
                    pooja.selectedScheduleId ??
                    rawPooja['scheduleId'] ??
                    rawPooja['selectedScheduleId'];
                if (scheduleId == null && pooja.schedules.isNotEmpty) {
                  final firstSched = pooja.schedules.first;
                  scheduleId = firstSched['_id'] ?? firstSched['id'];
                }
                Get.toNamed(
                  AppRoutes.poojaWizard,
                  arguments: {
                    'pooja': pooja,
                    if (scheduleId != null) 'scheduleId': scheduleId.toString(),
                  },
                );
              },
              textColor: AppColors.white,
              gradientColors: gradientColors,
            ),
          ),
        ],
      ),
    ),
    ),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}

Widget _previewChip(IconData icon, String label) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF1E0),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFFB5651D)),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFFB5651D),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}

String? statusForPooja(
  Map<String, dynamic> pooja, {
  List<dynamic>? pendingSessions,
  List<dynamic>? finishedSessions,
}) {
  List<dynamic> pending = pendingSessions ?? const [];
  List<dynamic> finished = finishedSessions ?? const [];

  if (pendingSessions == null &&
      finishedSessions == null &&
      Get.isRegistered<PoojaHistoryController>()) {
    final history = Get.find<PoojaHistoryController>();
    pending = history.pendingPoojas;
    finished = history.finishedPoojas;
  }

  final isPending = pending.whereType<Map>().any(
    (session) => sessionMatchesPooja(session, pooja),
  );
  if (isPending) return 'In Progress';

  final isFinished = finished.whereType<Map>().any(
    (session) => sessionMatchesPooja(session, pooja),
  );
  if (isFinished) return 'Finished';

  return null;
}

bool sessionMatchesPooja(Map session, Map<String, dynamic> pooja) {
  final sessionPooja = session['pooja'];
  if (sessionPooja is! Map) return false;

  final sessionPoojaId = (sessionPooja['_id'] ?? sessionPooja['id'] ?? '')
      .toString()
      .trim();
  final poojaId = (pooja['_id'] ?? pooja['id'] ?? '').toString().trim();

  bool basicMatch = false;
  if (sessionPoojaId.isNotEmpty && poojaId.isNotEmpty) {
    basicMatch = sessionPoojaId == poojaId;
  } else {
    final sessionTitle = (sessionPooja['title'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    final title = (pooja['title'] ?? '').toString().trim().toLowerCase();
    basicMatch = sessionTitle.isNotEmpty && sessionTitle == title;
  }
  if (!basicMatch) return false;

  final isDaily = pooja['daily'] == true || pooja['isDaily'] == true;
  final rawSchedules = pooja['schedules'];
  final hasSchedules = rawSchedules is List && rawSchedules.isNotEmpty;

  if (isDaily || hasSchedules) {
    final pScheduleId = pooja['scheduleId'] ?? pooja['selectedScheduleId'];
    final sScheduleId =
        session['scheduleId'] ??
        session['schedule'] ??
        session['pooja']?['scheduleId'];
    if (pScheduleId != null &&
        sScheduleId != null &&
        pScheduleId.toString().isNotEmpty &&
        sScheduleId.toString().isNotEmpty) {
      return pScheduleId.toString() == sScheduleId.toString();
    }

    final pDate =
        pooja['customDate'] ?? pooja['date'] ?? pooja['scheduledDate'];
    final sDate =
        session['scheduleDate'] ?? session['date'] ?? session['scheduledDate'];
    if (pDate != null &&
        sDate != null &&
        pDate.toString().isNotEmpty &&
        sDate.toString().isNotEmpty) {
      return pDate.toString() == sDate.toString();
    }
  }

  return true;
}

class PujaSessionStatusBadge extends StatelessWidget {
  const PujaSessionStatusBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final isFinished = label.toLowerCase() == 'finished';
    final color = isFinished
        ? const Color(0xFF0F8F5F)
        : const Color(0xFFC06A00);
    final bg = isFinished ? const Color(0xFFE7F7EF) : const Color(0xFFFFF3D8);
    final border = isFinished
        ? const Color(0xFF86D7AE)
        : const Color(0xFFE8A13A);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isFinished ? Icons.check_circle_outline : Icons.play_circle_outline,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> openPujaPreview(
  BuildContext context, {
  required String id,
  Map<String, dynamic>? initialData,
}) async {
  Map<String, dynamic> poojaMap = Map<String, dynamic>.from(
    initialData ?? <String, dynamic>{'_id': id, 'id': id},
  );

  final existingSteps = poojaMap['steps'];
  final needsFetch =
      existingSteps == null || (existingSteps is List && existingSteps.isEmpty);

  if (needsFetch && id.isNotEmpty) {
    try {
      final offlineService = Get.find<OfflineService>();
      final cacheKey = 'pooja_detail_$id';
      if (offlineService.isOnline.value) {
        final res = await Get.find<ApiClient>().dio.get<dynamic>(
          ApiEndpoints.pooja(id),
        );
        final payload = res.data;
        if (payload is Map) {
          final data = payload['data'];
          if (data is Map) {
            final inner = data['pooja'];
            poojaMap = inner is Map
                ? Map<String, dynamic>.from(inner)
                : Map<String, dynamic>.from(data);
          } else {
            poojaMap = Map<String, dynamic>.from(payload);
          }
          await offlineService.cacheData(cacheKey, poojaMap);
        }
      } else {
        final cached = offlineService.getCachedData(cacheKey);
        if (cached is Map) poojaMap = Map<String, dynamic>.from(cached);
      }
    } catch (e) {
      debugPrint('Error fetching pooja detail for preview: $e');
    }
  }

  if (!context.mounted) return;
  showPujaPreviewModal(context, PoojaView(poojaMap));
}
