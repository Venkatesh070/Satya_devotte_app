import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/core/network/api_client.dart';
import 'package:satya_devotte_app/core/network/api_endpoints.dart';
import 'package:satya_devotte_app/core/services/offline_service.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';
import 'package:satya_devotte_app/features/cms/data/datasources/ritual_remote_datasource.dart';
import 'package:satya_devotte_app/features/cms/models/ritual_model.dart';
import 'package:satya_devotte_app/features/profile/presentation/controllers/pooja_history_controller.dart';
import 'package:satya_devotte_app/features/profile/presentation/controllers/ritual_history_controller.dart';
import 'package:satya_devotte_app/features/pujas/presentation/models/pooja_view_model.dart';
import 'package:satya_devotte_app/features/pujas/presentation/pages/pooja_step_wizard.dart';
import 'package:satya_devotte_app/features/pujas/presentation/pages/ritual_step_wizard.dart';
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
            if (pooja.idealTime.trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6200).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFF6200).withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.access_time_filled_rounded,
                      size: 18,
                      color: Color(0xFFE35600),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ideal Time',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1F1F1F),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            pooja.idealTime,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF4A4A4A),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
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
                      if (scheduleId != null)
                        'scheduleId': scheduleId.toString(),
                    },
                  );
                },
                textColor: AppColors.white,
                gradientColors: gradientColors,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () {
                  Get.back();
                  openKnowMoreForPuja(
                    context,
                    id: pooja.id,
                    initialData: pooja.raw,
                  );
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: Color(0xFFE35600),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Know more about the puja →',
                      style: AppTypography.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFFE35600),
                        decoration: TextDecoration.underline,
                        decorationColor: Color(0xFFE35600),
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

String? statusForRitual(
  Map<String, dynamic> ritual, {
  List<dynamic>? pendingSessions,
  List<dynamic>? finishedSessions,
}) {
  List<dynamic> pending = pendingSessions ?? const [];
  List<dynamic> finished = finishedSessions ?? const [];

  if (pendingSessions == null &&
      finishedSessions == null &&
      Get.isRegistered<RitualHistoryController>()) {
    final history = Get.find<RitualHistoryController>();
    pending = history.pendingRituals;
    finished = history.finishedRituals;
  }

  final isPending = pending.whereType<Map>().any(
    (session) => sessionMatchesRitual(session, ritual),
  );
  if (isPending) return 'In Progress';

  final isFinished = finished.whereType<Map>().any(
    (session) => sessionMatchesRitual(session, ritual),
  );
  if (isFinished) return 'Finished';

  return null;
}

bool sessionMatchesRitual(Map session, Map<String, dynamic> ritual) {
  final sessionRitual = session['ritual'];
  if (sessionRitual is! Map) return false;

  final sessionRitualId = (sessionRitual['_id'] ?? sessionRitual['id'] ?? '')
      .toString()
      .trim();
  final ritualId = (ritual['_id'] ?? ritual['id'] ?? '').toString().trim();

  if (sessionRitualId.isNotEmpty && ritualId.isNotEmpty) {
    return sessionRitualId == ritualId;
  }

  final sessionTitle = (sessionRitual['title'] ?? '')
      .toString()
      .trim()
      .toLowerCase();
  final title = (ritual['title'] ?? '').toString().trim().toLowerCase();
  return sessionTitle.isNotEmpty && sessionTitle == title;
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

bool _isDetailedPoojaMap(Map<String, dynamic> map) {
  final steps = map['steps'];
  final hasSteps = steps is List && steps.isNotEmpty;
  final purpose = map['purpose'];
  final hasPurpose = purpose is Map && (purpose['why'] != null || purpose['benefits'] != null);
  final deitySummary = map['deitySummary'];
  final hasDeitySummary = deitySummary is Map && deitySummary.isNotEmpty;
  final mantra = map['mantra'];
  final hasMantra = (mantra is Map && mantra.isNotEmpty) || (mantra is String && mantra.isNotEmpty);
  final spiritual = map['spiritualMeaning'];
  final hasSpiritual = (spiritual is Map && spiritual.isNotEmpty) || (spiritual is String && spiritual.isNotEmpty);
  final guidance = map['guidance'];
  final hasGuidance = guidance is Map && guidance.isNotEmpty;
  final completion = map['completion'];
  final hasCompletion = completion is Map && completion.isNotEmpty;

  return hasSteps && (hasPurpose || hasDeitySummary || hasMantra || hasSpiritual || hasGuidance || hasCompletion);
}

Future<void> openPujaPreview(
  BuildContext context, {
  required String id,
  Map<String, dynamic>? initialData,
}) async {
  Map<String, dynamic> poojaMap = Map<String, dynamic>.from(
    initialData ?? <String, dynamic>{'_id': id, 'id': id},
  );
  if (id.isNotEmpty) {
    if ((poojaMap['_id'] ?? '').toString().trim().isEmpty) poojaMap['_id'] = id;
    if ((poojaMap['id'] ?? '').toString().trim().isEmpty) poojaMap['id'] = id;
  }

  final targetId = id.isNotEmpty ? id : (poojaMap['_id'] ?? poojaMap['id'] ?? '').toString();
  final needsFetch = !_isDetailedPoojaMap(poojaMap);

  if (needsFetch && targetId.isNotEmpty) {
    try {
      final offlineService = Get.find<OfflineService>();
      final cacheKey = 'pooja_detail_$targetId';
      if (offlineService.isOnline.value) {
        final res = await Get.find<ApiClient>().dio.get<dynamic>(
          ApiEndpoints.pooja(targetId),
        );
        final payload = res.data;
        if (payload is Map) {
          final data = payload['data'];
          Map<String, dynamic> fetched;
          if (data is Map) {
            final inner = data['pooja'];
            fetched = inner is Map
                ? Map<String, dynamic>.from(inner)
                : Map<String, dynamic>.from(data);
          } else {
            fetched = Map<String, dynamic>.from(payload);
          }
          poojaMap = {...poojaMap, ...fetched};
          await offlineService.cacheData(cacheKey, poojaMap);
        }
      } else {
        final cached = offlineService.getCachedData(cacheKey);
        if (cached is Map) {
          poojaMap = {...poojaMap, ...Map<String, dynamic>.from(cached)};
        }
      }
    } catch (e) {
      debugPrint('Error fetching pooja detail for preview: $e');
    }
  }

  if (!context.mounted) return;
  showPujaPreviewModal(context, PoojaView(poojaMap));
}

Future<void> openKnowMoreForPuja(
  BuildContext context, {
  required String id,
  Map<String, dynamic>? initialData,
}) async {
  Map<String, dynamic> poojaMap = Map<String, dynamic>.from(
    initialData ?? <String, dynamic>{'_id': id, 'id': id},
  );
  if (id.isNotEmpty) {
    if ((poojaMap['_id'] ?? '').toString().trim().isEmpty) poojaMap['_id'] = id;
    if ((poojaMap['id'] ?? '').toString().trim().isEmpty) poojaMap['id'] = id;
  }

  final targetId = id.isNotEmpty ? id : (poojaMap['_id'] ?? poojaMap['id'] ?? '').toString();
  final needsFetch = !_isDetailedPoojaMap(poojaMap);

  if (needsFetch && targetId.isNotEmpty) {
    try {
      final offlineService = Get.find<OfflineService>();
      final cacheKey = 'pooja_detail_$targetId';
      if (offlineService.isOnline.value) {
        final res = await Get.find<ApiClient>().dio.get<dynamic>(
          ApiEndpoints.pooja(targetId),
        );
        final payload = res.data;
        if (payload is Map) {
          final data = payload['data'];
          Map<String, dynamic> fetched;
          if (data is Map) {
            final inner = data['pooja'];
            fetched = inner is Map
                ? Map<String, dynamic>.from(inner)
                : Map<String, dynamic>.from(data);
          } else {
            fetched = Map<String, dynamic>.from(payload);
          }
          poojaMap = {...poojaMap, ...fetched};
          await offlineService.cacheData(cacheKey, poojaMap);
        }
      } else {
        final cached = offlineService.getCachedData(cacheKey);
        if (cached is Map) {
          poojaMap = {...poojaMap, ...Map<String, dynamic>.from(cached)};
        }
      }
    } catch (e) {
      debugPrint('Error fetching pooja detail for know more: $e');
    }
  }

  if (!context.mounted) return;
  Get.to(() => PoojaKnowMoreScreen(pooja: PoojaView(poojaMap)));
}

Future<void> openKnowMoreForRitual(
  BuildContext context, {
  required String id,
  RitualModel? initialModel,
}) async {
  RitualModel? ritual = initialModel;
  final needsFetch = ritual == null || ritual.sections.isEmpty;

  if (needsFetch && id.isNotEmpty) {
    try {
      final ritualData =
          await Get.find<RitualRemoteDataSource>().getRitualById(id);
      ritual = ritualData;
    } catch (e) {
      debugPrint('Error fetching ritual detail for know more: $e');
    }
  }

  if (!context.mounted) return;
  if (ritual != null) {
    Get.to<void>(() => RitualKnowMoreScreen(ritual: ritual!));
  }
}

class EyeKnowMoreButton extends StatelessWidget {
  const EyeKnowMoreButton({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: const BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF183EA4), Color(0xFFE35600)],
          ).createShader(bounds),
          child: const Icon(Icons.info, size: 24, color: Color(0xFFFCF7EF)),
        ),
      ),
    );
  }
}

String resolveRitualRestrictionMessage({
  required String rawError,
  required int targetDay,
  int? currentSessionDay,
  int? lastCompletedDay,
  String? ritualTitle,
}) {
  final lower = rawError.toLowerCase().trim();

  // 1. Multiple rituals on the same day / already performed a ritual today
  if (lower.contains('another ritual') ||
      lower.contains('multiple ritual') ||
      lower.contains('already performed a ritual') ||
      lower.contains('already completed a ritual') ||
      lower.contains('already in progress') ||
      lower.contains('two rituals') ||
      lower.contains('same day') ||
      lower.contains('one ritual per day') ||
      lower.contains('already performed today') ||
      lower.contains('already completed today') ||
      lower.contains('ritual completed today') ||
      lower.contains('already performed a ritual for today')) {
    return 'Multiple rituals cannot be performed on the same day. Please return tomorrow to perform this ritual.';
  }

  // 2. Future day out of sequence (e.g. Day 3 attempted when Day 1 is done and Day 2 is next)
  final nextExpectedDay = (lastCompletedDay != null && lastCompletedDay > 0)
      ? lastCompletedDay + 1
      : (currentSessionDay ?? 1);

  if (targetDay > nextExpectedDay ||
      lower.contains('sequence') ||
      lower.contains('previous day') ||
      lower.contains('cannot skip') ||
      lower.contains('before day') ||
      lower.contains('not unlocked') ||
      lower.contains('complete day') ||
      lower.contains('invalid day') ||
      lower.contains('future')) {
    return 'Please complete Day $nextExpectedDay first before starting Day $targetDay. Ritual days must be performed in sequential order.';
  }

  // 3. Day of the same ritual already performed today (trying to perform next day on the same day)
  if (lower.contains('day') &&
      (lower.contains('tomorrow') ||
          lower.contains('next day') ||
          lower.contains('today') ||
          lower.contains('already completed'))) {
    final completedDay = lastCompletedDay ?? (targetDay > 1 ? targetDay - 1 : 1);
    return 'You have already completed Day $completedDay today. Day $targetDay can only be performed tomorrow. Only one ritual day can be performed per day.';
  }

  // 4. Fallback for clean errors or generic fallback
  if (lower.contains('schedule') ||
      lower.contains('restrict') ||
      lower.contains('not allowed')) {
    return 'This ritual cannot be performed at this time. Please follow the designated ritual schedule.';
  }

  if (rawError.isNotEmpty &&
      !rawError.contains('DioException') &&
      !rawError.contains('HttpException') &&
      !rawError.contains('SocketException') &&
      !rawError.contains('{') &&
      !rawError.contains('status code')) {
    return rawError;
  }

  return 'Multiple rituals cannot be performed on the same day. Please return tomorrow to continue your ritual.';
}

void showRitualRestrictionDialog(
  BuildContext context, {
  required String message,
  VoidCallback? onClose,
}) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) {
            Navigator.of(dialogContext).pop();
            if (onClose != null) {
              onClose();
            } else {
              Get.back();
            }
          }
        },
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF2A1005),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFFFD180).withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD180).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.calendar_month_outlined,
                    size: 28,
                    color: Color(0xFFFFD180),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Ritual Schedule',
                  textAlign: TextAlign.center,
                  style: AppTypography.lora(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFFD180),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTypography.inter(
                    fontSize: 14,
                    height: 1.5,
                    color: const Color(0xFFFCF7EF).withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      if (onClose != null) {
                        onClose();
                      } else {
                        Get.back();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFCF7EF),
                      foregroundColor: const Color(0xFF255AE2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Close',
                      style: AppTypography.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF255AE2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
