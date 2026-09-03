import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:get/get.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/features/cms/data/datasources/ritual_remote_datasource.dart';
import 'package:satya_devotte_app/features/cms/models/ritual_model.dart';
import 'package:satya_devotte_app/features/profile/presentation/controllers/ritual_history_controller.dart';
import 'package:satya_devotte_app/features/pujas/presentation/pages/ritual_step_wizard.dart';
import 'package:satya_devotte_app/features/pujas/presentation/widgets/puja_shared_widgets.dart';
import 'package:satya_devotte_app/shared/widgets/chakra_loading_indicator.dart';
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

  RitualHistoryController get _history => Get.find<RitualHistoryController>();

  @override
  void initState() {
    super.initState();
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<RitualHistoryController>()) {
        _history.fetchHistory();
      }
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
    if (!Get.isRegistered<RitualHistoryController>()) return null;
    return _history.findPendingSession(ritual.id);
  }

  String? _statusLabel(RitualModel ritual) {
    return statusForRitual({
      '_id': ritual.id,
      'id': ritual.id,
      'title': ritual.title,
    });
  }

  bool _isDayCompleted(Map session, int dayNumber) {
    final completed = session['completedDays'];
    if (completed is! List) return false;
    return completed.whereType<Map>().any(
      (d) => (d['dayNumber'] as num?)?.toInt() == dayNumber,
    );
  }

  Future<void> _openDay(RitualModel ritual, int dayNumber) async {
    final session = _pendingSession(ritual);
    final sessionId = session != null
        ? (session['_id'] ?? session['id'])?.toString()
        : null;

    final result = await Get.to<bool>(
      () => RitualStepWizard(
        ritual: ritual,
        sessionId: sessionId,
        initialDay: dayNumber,
        initialStep: 0,
      ),
    );

    if (result == true || mounted) {
      if (Get.isRegistered<RitualHistoryController>()) {
        await _history.fetchHistory();
      }
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _ritual == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFFFF4E0),
        body: Center(child: ChakraLoadingIndicator()),
      );
    }

    if (_ritual == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFFFF4E0),
        appBar: AppBar(
          backgroundColor: const Color(0xFFFFF4E0),
          elevation: 0,
          foregroundColor: const Color(0xFF4A1C00),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _error ?? 'No ritual found',
                  textAlign: TextAlign.center,
                  style: AppTypography.inter(
                    fontSize: 14,
                    color: const Color(0xFF4A1C00),
                  ),
                ),
                const SizedBox(height: 14),
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
        ),
      );
    }

    final ritual = _ritual!;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF4E0),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Stack(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 220,
                      child: _ShapedRitualHeaderBanner(
                        networkUrl: ritual.imageUrl,
                      ),
                    ),
                    Positioned(
                      top: MediaQuery.paddingOf(context).top + 8,
                      left: 16,
                      child: GestureDetector(
                        onTap: () => Get.back(),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.35),
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Color(0xFFFCF7EF),
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
                  child: Obx(() {
                    final session = _pendingSession(ritual);
                    final finished = _history.findFinishedSession(ritual.id);
                    final totalDays =
                        ritual.ritualDay ??
                        (ritual.days.isNotEmpty ? ritual.days.length : 1);

                    int completedCount = 0;
                    if (finished != null) {
                      completedCount =
                          (finished['completedDays'] as List?)?.length ??
                          totalDays;
                      if (completedCount == 0) completedCount = totalDays;
                    } else if (session != null) {
                      completedCount =
                          (session['completedDays'] as List?)?.length ?? 0;
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          ritual.title,
                          style: AppTypography.lora(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF3B1E08),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Days / Completed indicator: ALWAYS x/y days completed
                        Text(
                          '$completedCount/$totalDays days completed',
                          style: AppTypography.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFE35600),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Description
                        if ((ritual.description ?? '').trim().isNotEmpty) ...[
                          RichTextDisplay(
                            ritual.description!,
                            style: AppTypography.inter(
                              fontSize: 14,
                              height: 1.5,
                              color: const Color(0xFF5C4634),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Preferred day and timings
                        if ((ritual.bestDayTime ?? '').trim().isNotEmpty) ...[
                          RichText(
                            text: TextSpan(
                              style: AppTypography.inter(
                                fontSize: 13,
                                height: 1.5,
                                color: const Color(0xFF5C4634),
                              ),
                              children: [
                                const TextSpan(
                                  text: 'Preferred day and timings : ',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                TextSpan(text: ritual.bestDayTime!),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Ritual Schedule
                        // RichText(
                        //   text: TextSpan(
                        //     style: AppTypography.inter(
                        //       fontSize: 13,
                        //       height: 1.5,
                        //       color: const Color(0xFF5C4634),
                        // ),
                        // children: [
                        //   const TextSpan(
                        //     text: 'Ritual Schedule: ',
                        //     style: TextStyle(fontWeight: FontWeight.w700),
                        //   ),
                        //   TextSpan(
                        //     text:
                        //         (ritual.startingDay ?? '')
                        //                 .trim()
                        //                 .isNotEmpty
                        //             ? 'Starts on ${ritual.startingDay!} and repeats every week. The ritual can only be initiated on the designated day. If it is not started on the scheduled day, you will need to wait until the following week to begin.'
                        //             : 'The ritual can only be initiated on scheduled days. Once started, follow the daily program in order.',
                        //   ),
                        // ],
                        //   ),
                        // ),
                        const SizedBox(height: 12),

                        // Ritual Continuity
                        RichText(
                          text: TextSpan(
                            style: AppTypography.inter(
                              fontSize: 13,
                              height: 1.5,
                              color: const Color(0xFF5C4634),
                            ),
                            children: const [
                              TextSpan(
                                text: 'Ritual Continuity: ',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              TextSpan(
                                text:
                                    'Once the ritual has been started, it must be followed continuously. If you miss any 1 day or skip a scheduled day, the ritual will reset, and you will need to start again from the beginning.',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Rituals / Days Section
                        if (ritual.days.isNotEmpty) ...[
                          Text(
                            'Rituals',
                            style: AppTypography.lora(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF4A1C00),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...ritual.days.map((day) {
                            final isCompleted =
                                session != null &&
                                _isDayCompleted(session, day.stepNumber);
                            final isCurrent =
                                session != null &&
                                day.stepNumber ==
                                    ((session['currentDay'] as num?)?.toInt() ??
                                        1);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _RitualDayCard(
                                day: day,
                                ritualTitle: ritual.title,
                                isCompleted: isCompleted,
                                isCurrent: isCurrent,
                                onTap: () => _openDay(ritual, day.stepNumber),
                              ),
                            );
                          }),
                        ],
                      ],
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RitualDayCard extends StatelessWidget {
  const _RitualDayCard({
    required this.day,
    required this.ritualTitle,
    required this.isCompleted,
    required this.isCurrent,
    required this.onTap,
  });

  final RitualDay day;
  final String ritualTitle;
  final bool isCompleted;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = day.title.trim().isNotEmpty
        ? day.title.trim()
        : 'Day ${day.stepNumber}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBF5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCompleted
                ? const Color(0xFF81C784)
                : isCurrent
                    ? const Color(0xFFE35600)
                    : const Color(0xFFE7D5BC),
            width: (isCompleted || isCurrent) ? 1.5 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.lora(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF4A1C00),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Day ${day.stepNumber}',
                    style: AppTypography.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF8A6B4A),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (isCompleted)
              const Icon(Icons.check_circle, color: Color(0xFF0F8F5F), size: 22)
            else if (isCurrent)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0E4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE35600)),
                ),
                child: Text(
                  'Current',
                  style: AppTypography.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFE35600),
                  ),
                ),
              )
            else
              const Icon(
                Icons.chevron_right,
                color: Color(0xFFB07A3A),
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}

class _ShapedRitualHeaderBanner extends StatefulWidget {
  final String? networkUrl;
  const _ShapedRitualHeaderBanner({this.networkUrl});

  @override
  State<_ShapedRitualHeaderBanner> createState() =>
      _ShapedRitualHeaderBannerState();
}

class _ShapedRitualHeaderBannerState extends State<_ShapedRitualHeaderBanner> {
  ui.Image? _maskImage;

  @override
  void initState() {
    super.initState();
    _loadMask();
  }

  Future<void> _loadMask() async {
    try {
      final ByteData data = await rootBundle.load(
        'assets/images/appHeaderImg.png',
      );
      final ui.Codec codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
      );
      final ui.FrameInfo fi = await codec.getNextFrame();
      if (mounted) setState(() => _maskImage = fi.image);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final hasNetwork =
        widget.networkUrl != null && widget.networkUrl!.trim().isNotEmpty;

    if (_maskImage == null || !hasNetwork) {
      return Image.asset('assets/images/appHeaderImg.png', fit: BoxFit.fill);
    }

    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (Rect bounds) {
        final double sx = bounds.width / _maskImage!.width;
        final double sy = bounds.height / _maskImage!.height;
        final matrix = Matrix4.identity().scaled(sx, sy, 1.0).storage;
        return ImageShader(_maskImage!, TileMode.clamp, TileMode.clamp, matrix);
      },
      child: CachedNetworkImage(
        imageUrl: widget.networkUrl!,
        fit: BoxFit.cover,
        alignment: const Alignment(0, -0.4),
        placeholder: (_, __) =>
            Image.asset('assets/images/appHeaderImg.png', fit: BoxFit.cover),
        errorWidget: (_, __, ___) =>
            Image.asset('assets/images/appHeaderImg.png', fit: BoxFit.cover),
      ),
    );
  }
}
