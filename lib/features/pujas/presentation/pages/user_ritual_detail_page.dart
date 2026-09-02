import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/features/cms/data/datasources/ritual_remote_datasource.dart';
import 'package:satya_devotte_app/features/cms/models/ritual_model.dart';
import 'package:satya_devotte_app/features/profile/presentation/controllers/ritual_history_controller.dart';
import 'package:satya_devotte_app/features/pujas/presentation/pages/ritual_step_wizard.dart';
import 'package:satya_devotte_app/features/pujas/presentation/widgets/puja_shared_widgets.dart';
import 'package:satya_devotte_app/shared/widgets/rich_text_display.dart';
import 'package:satya_devotte_app/shared/widgets/step_rich_text_display.dart';

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

  RitualHistoryController get _history => Get.find<RitualHistoryController>();

  @override
  void initState() {
    super.initState();
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _history.fetchHistory();
    });
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

  Map<String, dynamic>? _pendingSession(RitualModel ritual) {
    return _history.findPendingSession(ritual.id);
  }

  String? _statusLabel(RitualModel ritual) {
    return statusForRitual({
      '_id': ritual.id,
      'id': ritual.id,
      'title': ritual.title,
    });
  }

  Future<void> _openWizard(RitualModel ritual) async {
    final session = _pendingSession(ritual);
    final sessionId = session != null
        ? (session['_id'] ?? session['id'])?.toString()
        : null;
    final currentDay = (session?['currentDay'] as num?)?.toInt() ?? 1;
    final currentStep = (session?['currentStep'] as num?)?.toInt() ?? 0;

    final result = await Get.to<bool>(
      () => RitualStepWizard(
        ritual: ritual,
        sessionId: sessionId,
        initialDay: currentDay,
        initialStep: currentStep > 0 ? currentStep : 0,
      ),
    );

    if (result == true || mounted) {
      await _history.fetchHistory();
      if (mounted) setState(() {});
    }
  }

  Widget? _buildBottomBar(RitualModel ritual) {
    final status = _statusLabel(ritual);
    if (status == 'Finished') {
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _openWizard(ritual),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4A1C00),
                    side: const BorderSide(color: Color(0xFFE7D5BC)),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text('Start again'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final session = _pendingSession(ritual);
    final currentDay = (session?['currentDay'] as num?)?.toInt() ?? 1;
    final label = session != null
        ? 'Continue Day $currentDay'
        : 'Begin Ritual';

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () => _openWizard(ritual),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gradientEnd,
              foregroundColor: const Color(0xFFFCF7EF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: Text(
              label,
              style: AppTypography.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
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
      bottomNavigationBar: ritual == null
          ? null
          : Obx(() => _buildBottomBar(ritual) ?? const SizedBox.shrink()),
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
          : Obx(() {
              final status = _statusLabel(ritual);
              final session = _pendingSession(ritual);
              final nextDue = session?['nextDayDueDateKey']?.toString();

              return ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 36),
                children: [
                  if (status != null) ...[
                    PujaSessionStatusBadge(label: status),
                    const SizedBox(height: 12),
                  ],
                  if (nextDue != null && nextDue.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0E4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE7D5BC)),
                      ),
                      child: Text(
                        'Complete Day ${session?['currentDay'] ?? 1} by $nextDue',
                        style: AppTypography.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFE35600),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
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
                      if ((ritual.ritualDay ?? '').trim().isNotEmpty)
                        _MetaChip(label: ritual.ritualDay!.trim())
                      else if (ritual.days.isNotEmpty)
                        _MetaChip(
                          label:
                              '${ritual.days.length} day${ritual.days.length == 1 ? '' : 's'}',
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
                        child: _RitualDayCard(
                          day: day,
                          isCurrentDay:
                              session != null &&
                              day.stepNumber ==
                                  ((session['currentDay'] as num?)?.toInt() ??
                                      1),
                          isCompleted:
                              session != null &&
                              _isDayCompleted(session, day.stepNumber),
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
              );
            }),
    );
  }

  bool _isDayCompleted(Map session, int dayNumber) {
    final completed = session['completedDays'];
    if (completed is! List) return false;
    return completed.whereType<Map>().any(
      (d) => (d['dayNumber'] as num?)?.toInt() == dayNumber,
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

class _RitualDayCard extends StatelessWidget {
  const _RitualDayCard({
    required this.day,
    this.isCurrentDay = false,
    this.isCompleted = false,
  });

  final RitualDay day;
  final bool isCurrentDay;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    final title = day.title.trim().isEmpty
        ? 'Day ${day.stepNumber}'
        : 'Day ${day.stepNumber}: ${day.title.trim()}';

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: isCurrentDay ? 0.92 : 0.72),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentDay
              ? const Color(0xFFE35600)
              : const Color(0xFFE7D5BC),
          width: isCurrentDay ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.lora(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF4A1C00),
                    ),
                  ),
                ),
                if (isCompleted)
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF0F8F5F),
                    size: 20,
                  )
                else if (isCurrentDay)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0E4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Today',
                      style: AppTypography.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFE35600),
                      ),
                    ),
                  ),
              ],
            ),
          ),
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
                if (day.requiredItems.isNotEmpty) ...[
                  if (day.description.trim().isNotEmpty)
                    const SizedBox(height: 12),
                  Text(
                    'Required items',
                    style: AppTypography.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF4A1C00),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: day.requiredItems
                        .map(
                          (item) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF8F0),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFE7D5BC),
                              ),
                            ),
                            child: Text(
                              item,
                              style: AppTypography.inter(
                                fontSize: 12,
                                color: const Color(0xFF5C4634),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
                if (day.satyaBlessings.trim().isNotEmpty) ...[
                  if (day.description.trim().isNotEmpty ||
                      day.requiredItems.isNotEmpty)
                    const SizedBox(height: 12),
                  Text(
                    'Blessings from Sathya',
                    style: AppTypography.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF4A1C00),
                    ),
                  ),
                  const SizedBox(height: 6),
                  RichTextDisplay(
                    day.satyaBlessings,
                    style: AppTypography.inter(
                      fontSize: 13,
                      height: 1.4,
                      color: const Color(0xFF5C4634),
                    ),
                  ),
                ],
                if (day.steps.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Steps',
                    style: AppTypography.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF4A1C00),
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (var i = 0; i < day.steps.length; i++) ...[
                    _RitualInnerStepCard(step: day.steps[i], index: i + 1),
                    if (i != day.steps.length - 1) const SizedBox(height: 10),
                  ],
                ] else if (day.subSteps.isNotEmpty) ...[
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

class _RitualInnerStepCard extends StatelessWidget {
  const _RitualInnerStepCard({required this.step, required this.index});

  final RitualDayStep step;
  final int index;

  @override
  Widget build(BuildContext context) {
    final title = step.title.trim().isEmpty
        ? 'Step $index'
        : step.title.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F0),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE7D5BC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$index. $title',
            style: AppTypography.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF4A1C00),
            ),
          ),
          if (step.description.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            StepRichTextDisplay.detail(step.description),
          ],
          if (step.images.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: step.images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, imageIndex) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: step.images[imageIndex],
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ],
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
