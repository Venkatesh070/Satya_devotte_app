import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/core/services/offline_service.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/core/utils/rich_text_util.dart';
import 'package:satya_devotte_app/features/cms/models/ritual_model.dart';
import 'package:satya_devotte_app/features/donations/presentation/pages/make_donation_screen.dart';
import 'package:satya_devotte_app/features/profile/presentation/controllers/ritual_history_controller.dart';
import 'package:satya_devotte_app/shared/widgets/app_background.dart';
import 'package:satya_devotte_app/shared/widgets/rich_text_display.dart';
import 'package:satya_devotte_app/shared/widgets/step_rich_text_display.dart';

class RitualStepWizard extends StatefulWidget {
  const RitualStepWizard({
    super.key,
    required this.ritual,
    this.sessionId,
    this.initialDay,
    this.initialStep,
  });

  final RitualModel ritual;
  final String? sessionId;
  final int? initialDay;
  final int? initialStep;

  @override
  State<RitualStepWizard> createState() => _RitualStepWizardState();
}

class _RitualStepWizardState extends State<RitualStepWizard> {
  late final PageController _pageController;
  late int _currentPage;
  String? _sessionId;
  late int _currentDay;
  bool _dayCompleted = false;

  @override
  void initState() {
    super.initState();
    _sessionId = widget.sessionId;
    _currentDay = widget.initialDay ?? 1;
    _currentPage = widget.initialStep ?? 0;
    _pageController = PageController(initialPage: _currentPage);

    // Eagerly initialize session in background without blocking UI
    if (_sessionId == null) {
      _startSession();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  RitualDay? get _dayDef => widget.ritual.dayByNumber(_currentDay);

  List<RitualDayStep> get _steps {
    final day = _dayDef;
    if (day == null) return const [];
    if (day.steps.isNotEmpty) return day.steps;
    return day.subSteps
        .asMap()
        .entries
        .map(
          (e) => RitualDayStep(
            stepNumber: e.key + 1,
            title: 'Step ${e.key + 1}',
            description: e.value,
          ),
        )
        .toList();
  }

  bool get _hasRequiredItems =>
      _dayDef != null && _dayDef!.requiredItems.isNotEmpty;

  int get _totalPages => _buildPages().length;

  Future<void> _startSession() async {
    if (!Get.isRegistered<RitualHistoryController>()) return;
    try {
      final history = Get.find<RitualHistoryController>();
      final result = await history.startRitual(widget.ritual.id);
      final session = result?['session'];
      if (session is Map && mounted) {
        final id = (session['_id'] ?? session['id'])?.toString();
        if (id != null && id.isNotEmpty) {
          setState(() {
            _sessionId = id;
            _currentDay =
                (session['currentDay'] as num?)?.toInt() ?? _currentDay;
          });
        }
      }
    } catch (_) {}
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      final nextIdx = _currentPage + 1;

      // Animate smoothly without any loader
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      if (mounted) {
        setState(() => _currentPage = nextIdx);
      }

      // Update progress asynchronously in background
      final stepOffset = _hasRequiredItems ? 2 : 1;
      if (_sessionId != null &&
          nextIdx >= stepOffset &&
          nextIdx < stepOffset + _steps.length &&
          Get.isRegistered<RitualHistoryController>()) {
        unawaited(
          Get.find<RitualHistoryController>().updateProgress(
            _sessionId!,
            nextIdx - stepOffset + 1,
            currentDay: _currentDay,
          ),
        );
      }
    }
  }

  bool _isStartingDay = false;

  void _showDayRestrictionDialog(String message) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) {
              Navigator.of(dialogContext).pop();
              Get.back();
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
                        Get.back();
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

  Future<void> _startRitualSteps() async {
    if (_isStartingDay) return;
    setState(() => _isStartingDay = true);

    try {
      if (_sessionId == null && Get.isRegistered<RitualHistoryController>()) {
        final result = await Get.find<RitualHistoryController>().startRitual(
          widget.ritual.id,
        );
        final session = result?['session'];
        if (session is Map) {
          _sessionId = (session['_id'] ?? session['id'])?.toString();
        }
      }

      if (_sessionId != null && Get.isRegistered<RitualHistoryController>()) {
        final errorMsg = await Get.find<RitualHistoryController>().updateProgress(
          _sessionId!,
          1,
          currentDay: _currentDay,
        );

        if (errorMsg != null && errorMsg.isNotEmpty) {
          if (!mounted) return;
          _showDayRestrictionDialog(errorMsg);
          return;
        }
      }

      if (_steps.isEmpty) {
        _completeDay();
      } else {
        _nextPage();
      }
    } finally {
      if (mounted) {
        setState(() => _isStartingDay = false);
      }
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      final prevIdx = _currentPage - 1;
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      if (mounted) {
        setState(() => _currentPage = prevIdx);
      }

      final stepOffset = _hasRequiredItems ? 2 : 1;
      if (_sessionId != null &&
          prevIdx >= stepOffset &&
          Get.isRegistered<RitualHistoryController>()) {
        unawaited(
          Get.find<RitualHistoryController>().updateProgress(
            _sessionId!,
            prevIdx - stepOffset + 1,
            currentDay: _currentDay,
          ),
        );
      }
    } else {
      Get.back();
    }
  }

  void _completeDay() {
    // Fire completion to backend in background
    if (_sessionId != null && Get.isRegistered<RitualHistoryController>()) {
      unawaited(Get.find<RitualHistoryController>().completeDay(_sessionId!));
    }

    setState(() {
      _dayCompleted = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pageController.hasClients) return;
      final completionIndex = _buildPages().length - 1;
      _pageController.animateToPage(
        completionIndex,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage = completionIndex);
    });
  }

  List<Widget> _buildPages() {
    final day = _dayDef;
    final pages = <Widget>[
      // 1. Day Intro Screen
      _DayIntroScreen(
        ritual: widget.ritual,
        dayNumber: _currentDay,
        day: day,
        onNext: _hasRequiredItems ? _nextPage : _startRitualSteps,
        onBack: _previousPage,
        onOpenKnowMore: () {
          Get.to<void>(() => RitualKnowMoreScreen(ritual: widget.ritual));
        },
      ),
    ];

    // 2. Ingredients Screen (if required items exist)
    if (_hasRequiredItems) {
      pages.add(
        _RitualIngredientsScreen(
          ritual: widget.ritual,
          dayNumber: _currentDay,
          day: day!,
          onNext: _startRitualSteps,
          onBack: _previousPage,
        ),
      );
    }

    // 3. Daily Steps Screens (styled identical to pooja steps)
    final isSingleDay = widget.ritual.days.length <= 1;
    final completeLabel =
        isSingleDay ? 'Complete Ritual' : 'Complete Day $_currentDay';

    for (var i = 0; i < _steps.length; i++) {
      final step = _steps[i];
      final isLast = i == _steps.length - 1;
      pages.add(
        _RitualStepScreen(
          step: step,
          stepIndex: i + 1,
          totalSteps: _steps.length,
          dayNumber: _currentDay,
          onNext: isLast ? _completeDay : _nextPage,
          onBack: _previousPage,
          nextLabel: isLast ? completeLabel : 'Next',
        ),
      );
    }

    // 4. Ritual Day Completed Screen (with blessings & donation)
    if (_dayCompleted) {
      pages.add(
        _CompletionScreen(
          dayNumber: _currentDay,
          ritual: widget.ritual,
          onFinish: () => Get.back(result: true),
          onBack: _previousPage,
        ),
      );
    }

    return pages;
  }

  @override
  Widget build(BuildContext context) {
    final pages = _buildPages();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _previousPage();
      },
      child: AppBackground(
        showPattern: true,
        rotateFooter: true,
        animatePatterns: true,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: pages,
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Base Top Bar ──────────────────────────

class _BaseWizardScreen extends StatelessWidget {
  const _BaseWizardScreen({
    required this.child,
    this.onBack,
    this.useBackButtonTopLeft = false,
  });

  final Widget child;
  final VoidCallback? onBack;
  final bool useBackButtonTopLeft;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Top Left button — Home button (or Back for sub-pages)
                    GestureDetector(
                      onTap: useBackButtonTopLeft
                          ? (onBack ?? () => Get.back())
                          : () => Get.offAllNamed(AppRoutes.home),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(
                            0xFFFCF7EF,
                          ).withValues(alpha: 0.08),
                          border: Border.all(
                            color: const Color(
                              0xFFFCF7EF,
                            ).withValues(alpha: 0.14),
                          ),
                        ),
                        child: Icon(
                          useBackButtonTopLeft
                              ? Icons.arrow_back
                              : Icons.home_outlined,
                          color: const Color(0xFFFCF7EF),
                          size: useBackButtonTopLeft ? 18 : 20,
                        ),
                      ),
                    ),

                    // Logo
                    GestureDetector(
                      onTap: () => Get.offAllNamed(AppRoutes.home),
                      child: Image.asset(
                        'assets/images/logoWhite.png',
                        height: 32,
                        fit: BoxFit.contain,
                      ),
                    ),

                    // Right spacer for symmetry
                    const SizedBox(width: 38),
                  ],
                ),
              ),
              Expanded(child: child),
            ],
          ),
        ),
      ],
    );
  }
}

// ───────────────────────── Day Intro Screen ──────────────────────────

class _DayIntroScreen extends StatelessWidget {
  const _DayIntroScreen({
    required this.ritual,
    required this.dayNumber,
    required this.day,
    required this.onNext,
    required this.onBack,
    required this.onOpenKnowMore,
  });

  final RitualModel ritual;
  final int dayNumber;
  final RitualDay? day;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onOpenKnowMore;

  @override
  Widget build(BuildContext context) {
    final title = day?.title.trim().isNotEmpty == true
        ? day!.title.trim()
        : '${ritual.title} - Day $dayNumber';

    final totalDays = ritual.ritualDay ??
        (ritual.days.isNotEmpty ? ritual.days.length : 0);
    final dayLabel = totalDays > 1
        ? 'Day $dayNumber of $totalDays'
        : 'Day $dayNumber';

    final description = day?.description.trim().isNotEmpty == true
        ? day!.description.trim()
        : (ritual.description ?? '').trim();

    return _BaseWizardScreen(
      onBack: onBack,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(),
            _WizardFadeSlideIn(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFBF00).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFFFBF00).withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: Color(0xFFFFD180),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      dayLabel,
                      style: AppTypography.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFFD180),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            _WizardFadeSlideIn(
              delay: const Duration(milliseconds: 60),
              child: _WizardGradientTitle(text: title, fontSize: 28),
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 20),
              _WizardFadeSlideIn(
                delay: const Duration(milliseconds: 120),
                child: RichTextDisplay(
                  description,
                  textAlign: TextAlign.start,
                  style: AppTypography.inter(
                    fontSize: 16,
                    color: const Color(0xFFFFD180),
                    height: 1.5,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            _WizardFadeSlideIn(
              delay: const Duration(milliseconds: 180),
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: onOpenKnowMore,
                  behavior: HitTestBehavior.opaque,
                  child: Text(
                    'Know more about the ritual →',
                    style:
                        AppTypography.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFFCF7EF),
                        ).copyWith(
                          decoration: TextDecoration.underline,
                          decorationColor: const Color(0xFFFCF7EF),
                          decorationThickness: 2.0,
                        ),
                  ),
                ),
              ),
            ),
            const Spacer(),
            _WizardFadeSlideIn(
              delay: const Duration(milliseconds: 240),
              child: _WizardButton(
                label: 'Proceed',
                onTap: onNext,
                onBack: onBack,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ───────────────────── Know More About the Ritual Screen ─────────────

class RitualKnowMoreScreen extends StatelessWidget {
  const RitualKnowMoreScreen({super.key, required this.ritual});

  final RitualModel ritual;

  @override
  Widget build(BuildContext context) {
    final sections = ritual.sections;

    return AppBackground(
      showPattern: true,
      rotateFooter: true,
      animatePatterns: true,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: _BaseWizardScreen(
          useBackButtonTopLeft: true,
          onBack: () => Get.back(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                if ((ritual.category ?? '').trim().isNotEmpty) ...[
                  _WizardFadeSlideIn(
                    child: Text(
                      ritual.category!.trim(),
                      style: AppTypography.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFFCF7EF).withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                _WizardFadeSlideIn(
                  delay: const Duration(milliseconds: 80),
                  child: _WizardGradientTitle(
                    text: 'Know More about the Ritual',
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: sections.isNotEmpty
                      ? ListView.separated(
                          itemCount: sections.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 14),
                          itemBuilder: (_, index) {
                            final section = sections[index];
                            return _WizardFadeSlideIn(
                              delay: Duration(milliseconds: 140 + (index * 60)),
                              child: _KnowMoreSectionCard(
                                title: section.label,
                                description: section.description,
                              ),
                            );
                          },
                        )
                      : ListView(
                          children: [
                            if ((ritual.purpose ?? '').trim().isNotEmpty)
                              _WizardFadeSlideIn(
                                delay: const Duration(milliseconds: 140),
                                child: _KnowMoreSectionCard(
                                  title: 'Why is this ritual performed?',
                                  description: ritual.purpose!,
                                ),
                              ),
                            if ((ritual.description ?? '').trim().isNotEmpty)
                              _WizardFadeSlideIn(
                                delay: const Duration(milliseconds: 200),
                                child: _KnowMoreSectionCard(
                                  title: 'What is this ritual about?',
                                  description: ritual.description!,
                                ),
                              ),
                            if ((ritual.bestDayTime ?? '').trim().isNotEmpty)
                              _WizardFadeSlideIn(
                                delay: const Duration(milliseconds: 260),
                                child: _KnowMoreSectionCard(
                                  title: 'Best Day and Time',
                                  description: ritual.bestDayTime!,
                                ),
                              ),
                          ],
                        ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _KnowMoreSectionCard extends StatelessWidget {
  const _KnowMoreSectionCard({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0XFFEAE1D5).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFFD180).withValues(alpha: 0.16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.lora(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFFD180),
            ),
          ),
          if (description.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            StepRichTextDisplay.wizard(description),
          ],
        ],
      ),
    );
  }
}

// ───────────────────── Ingredients Checklist Screen ──────────────────

class _RitualIngredientsScreen extends StatefulWidget {
  const _RitualIngredientsScreen({
    required this.ritual,
    required this.dayNumber,
    required this.day,
    required this.onNext,
    required this.onBack,
  });

  final RitualModel ritual;
  final int dayNumber;
  final RitualDay day;
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  State<_RitualIngredientsScreen> createState() =>
      _RitualIngredientsScreenState();
}

class _RitualIngredientsScreenState extends State<_RitualIngredientsScreen> {
  final Set<int> _checkedIndices = {};

  @override
  Widget build(BuildContext context) {
    final items = widget.day.requiredItems;

    return _BaseWizardScreen(
      onBack: widget.onBack,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _WizardFadeSlideIn(
              child: Text(
                '${widget.ritual.title} – Day ${widget.dayNumber}',
                style: AppTypography.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFFCF7EF).withValues(alpha: 0.75),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _WizardFadeSlideIn(
              delay: const Duration(milliseconds: 80),
              child: const _WizardGradientTitle(
                text: 'Prayer items / Ingredients Required:',
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final isChecked = _checkedIndices.contains(index);
                  return _WizardFadeSlideIn(
                    delay: Duration(milliseconds: 120 + (index * 50)),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          if (isChecked) {
                            _checkedIndices.remove(index);
                          } else {
                            _checkedIndices.add(index);
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF2A1005,
                          ).withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isChecked
                                ? const Color(0xFFFFD180)
                                : const Color(
                                    0xFFFCF7EF,
                                  ).withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                items[index],
                                style: AppTypography.inter(
                                  fontSize: 14,
                                  color: const Color(0xFFFCF7EF),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: isChecked
                                    ? const Color(0xFFFFBF00)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: isChecked
                                      ? const Color(0xFFFFBF00)
                                      : const Color(
                                          0xFFFCF7EF,
                                        ).withValues(alpha: 0.4),
                                  width: 1.5,
                                ),
                              ),
                              child: isChecked
                                  ? const Icon(
                                      Icons.check,
                                      size: 16,
                                      color: Color(0xFF4A1C00),
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            _WizardFadeSlideIn(
              delay: Duration(milliseconds: 160 + (items.length * 50)),
              child: _WizardButton(
                label: 'Start Ritual',
                onTap: widget.onNext,
                onBack: widget.onBack,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ───────────────────── Step by Step Screen ──────────────────────

enum _StepCardType { instruction, mantra, significance }

class _StepBlock {
  const _StepBlock({required this.text, required this.type});
  final String text;
  final _StepCardType type;
}

class _RitualStepScreen extends StatelessWidget {
  const _RitualStepScreen({
    required this.step,
    required this.stepIndex,
    required this.totalSteps,
    required this.dayNumber,
    required this.onNext,
    required this.onBack,
    required this.nextLabel,
  });

  final RitualDayStep step;
  final int stepIndex;
  final int totalSteps;
  final int dayNumber;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final String nextLabel;

  static bool _isRecitation(String text) {
    final t = text.trim().toLowerCase();
    return t.startsWith('om ') ||
        t.startsWith('“om ') ||
        t.startsWith('"om ') ||
        t.startsWith('recite') ||
        t.startsWith('chant') ||
        t.contains('times)') ||
        t.contains('namah');
  }

  static _StepCardType _detectType(String text) {
    if (_isRecitation(text)) {
      return _StepCardType.mantra;
    }
    if (text.trim().contains('•') ||
        text.toLowerCase().contains('represents')) {
      return _StepCardType.significance;
    }
    return _StepCardType.instruction;
  }

  static String _formatMantraText(String text) {
    return text
        .split('\n')
        .map((line) {
          return line
              .trim()
              .replaceFirst(
                RegExp(r'^(recite|chant)\s*:?\s*', caseSensitive: false),
                '',
              )
              .replaceAll('\u201c', '"')
              .replaceAll('\u201d', '"');
        })
        .where((line) => line.isNotEmpty)
        .join('\n');
  }

  static List<_StepBlock> _parseBlocks(String description) {
    return description
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .map((line) => _StepBlock(text: line, type: _detectType(line)))
        .toList();
  }

  Widget _buildStepCard(String text, _StepCardType type) {
    switch (type) {
      case _StepCardType.mantra:
        final mantraText = _formatMantraText(text);
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFB63A19).withValues(alpha: 0.48),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFFFD180).withValues(alpha: 0.16),
            ),
          ),
          child: Column(
            children: [
              Text(
                'Recite :',
                textAlign: TextAlign.center,
                style: AppTypography.lora(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFFFD180),
                ),
              ),
              const SizedBox(height: 4),
              RichTextDisplay(
                mantraText,
                textAlign: TextAlign.center,
                style: AppTypography.lora(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFFFD180),
                  height: 1.35,
                ),
              ),
            ],
          ),
        );

      case _StepCardType.significance:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF2A1005).withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFFF9D00).withValues(alpha: 0.2),
            ),
          ),
          child: RichTextDisplay(
            text,
            style: AppTypography.inter(
              fontSize: 13,
              color: const Color(0xFFFCF7EF).withValues(alpha: 0.75),
              height: 1.6,
            ),
          ),
        );

      case _StepCardType.instruction:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFCF7EF).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: RichTextDisplay(
            text,
            style: AppTypography.inter(
              fontSize: 15,
              color: const Color(0xFFFCF7EF),
              height: 1.6,
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final description = step.description.trim();
    final usesRichDescription = isDeltaJson(description);
    final blocks = usesRichDescription
        ? const <_StepBlock>[]
        : _parseBlocks(description);

    final title = step.title.trim().isNotEmpty
        ? step.title.trim()
        : 'Step $stepIndex';

    return _BaseWizardScreen(
      onBack: onBack,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _WizardFadeSlideIn(
              child: Text(
                'Step $stepIndex/$totalSteps',
                style: AppTypography.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFCF7EF).withValues(alpha: 0.6),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _WizardFadeSlideIn(
              delay: const Duration(milliseconds: 100),
              child: _WizardGradientTitle(text: title, fontSize: 24),
            ),
            const SizedBox(height: 20),
            if (step.images.isNotEmpty) ...[
              _WizardFadeSlideIn(
                delay: const Duration(milliseconds: 140),
                child: _AutoScrollCarousel(imageUrls: step.images),
              ),
              const SizedBox(height: 16),
            ],
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Single container without double wrapper!
                    if (usesRichDescription && description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _WizardFadeSlideIn(
                          delay: const Duration(milliseconds: 180),
                          child: StepRichTextDisplay.wizard(description),
                        ),
                      )
                    else
                      for (var i = 0; i < blocks.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _WizardFadeSlideIn(
                            delay: Duration(milliseconds: 180 + (i * 70)),
                            child: _buildStepCard(
                              blocks[i].text,
                              blocks[i].type,
                            ),
                          ),
                        ),
                    if (step.subSteps.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      for (var i = 0; i < step.subSteps.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _WizardFadeSlideIn(
                            delay: Duration(
                              milliseconds: 180 + ((blocks.length + i) * 70),
                            ),
                            child: _buildStepCard(
                              step.subSteps[i],
                              _StepCardType.instruction,
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
            _WizardFadeSlideIn(
              delay: Duration(
                milliseconds:
                    260 + ((blocks.length + step.subSteps.length) * 70),
              ),
              child: _WizardButton(
                label: nextLabel,
                onTap: onNext,
                onBack: onBack,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── Shared Wizard Helpers ──────────────────────────

class _WizardButton extends StatelessWidget {
  const _WizardButton({
    required this.label,
    required this.onTap,
    this.onBack,
    this.showBack = true,
  });

  final String label;
  final VoidCallback onTap;
  final VoidCallback? onBack;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final backBtn = SizedBox(
      height: 56,
      child: OutlinedButton(
        onPressed: onBack ?? () => Get.back(),
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          foregroundColor: const Color(0xFFFCF7EF),
          side: BorderSide(
            color: const Color(0xFFFCF7EF).withValues(alpha: 0.35),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: Text(
          'Back',
          style: AppTypography.inter(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
    );

    final proceedBtn = SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: const Color(0xFFFCF7EF),
          foregroundColor: const Color(0xFF255AE2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 0,
        ),
        child: Text(
          label,
          style: AppTypography.inter(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
    );

    if (showBack) {
      return Row(
        children: [
          Expanded(child: backBtn),
          const SizedBox(width: 12),
          Expanded(child: proceedBtn),
        ],
      );
    }

    return SizedBox(width: double.infinity, child: proceedBtn);
  }
}

class _WizardGradientTitle extends StatelessWidget {
  const _WizardGradientTitle({
    required this.text,
    this.fontSize = 28,
    this.textAlign = TextAlign.start,
  });

  final String text;
  final double fontSize;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Color(0xFFFFBF00), Color(0xFFFF6200)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(bounds),
      blendMode: BlendMode.srcIn,
      child: Text(
        text,
        textAlign: textAlign,
        style: AppTypography.lora(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: const Color(0xFFFFD180),
          height: 1.25,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}

class _WizardFadeSlideIn extends StatefulWidget {
  const _WizardFadeSlideIn({required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  State<_WizardFadeSlideIn> createState() => _WizardFadeSlideInState();
}

class _WizardFadeSlideInState extends State<_WizardFadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future<void>.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

class _AutoScrollCarousel extends StatefulWidget {
  const _AutoScrollCarousel({required this.imageUrls});
  final List<String> imageUrls;

  @override
  State<_AutoScrollCarousel> createState() => _AutoScrollCarouselState();
}

class _AutoScrollCarouselState extends State<_AutoScrollCarousel> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _startAutoScroll();
  }

  void _startAutoScroll() {
    if (widget.imageUrls.length <= 1) return;
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return false;
      _currentPage = (_currentPage + 1) % widget.imageUrls.length;
      await _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      return true;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) return const SizedBox.shrink();
    if (widget.imageUrls.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          _cleanUrl(widget.imageUrls.first),
          width: double.infinity,
          height: 180,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      );
    }
    return SizedBox(
      height: 180,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imageUrls.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    _cleanUrl(widget.imageUrls[index]),
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              );
            },
          ),
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.imageUrls.length, (index) {
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: _currentPage == index
                        ? const LinearGradient(
                            colors: [Color(0xFFFFBF00), Color(0xFFFF6200)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: _currentPage != index
                        ? const Color(0xFFFCF7EF).withValues(alpha: 0.4)
                        : null,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  String _cleanUrl(String url) {
    return url.replaceAll('`', '').trim();
  }
}

// ───────────────────── Day Completed Screen ──────────────────────

class _CompletionScreen extends StatelessWidget {
  const _CompletionScreen({
    required this.dayNumber,
    required this.ritual,
    required this.onFinish,
    required this.onBack,
  });

  final int dayNumber;
  final RitualModel ritual;
  final VoidCallback onFinish;
  final VoidCallback onBack;

  String get _blessingText {
    // 1. Day's satyaBlessings
    final day = ritual.dayByNumber(dayNumber);
    if (day != null && day.satyaBlessings.trim().isNotEmpty) {
      return day.satyaBlessings.trim();
    }

    // 2. Check sections for blessing
    for (final section in ritual.sections) {
      final k = section.key.toLowerCase();
      final l = section.label.toLowerCase();
      if (k.contains('blessing') || l.contains('blessing')) {
        if (section.description.trim().isNotEmpty) {
          return section.description.trim();
        }
      }
    }

    // 3. Check purpose if available
    if ((ritual.purpose ?? '').trim().isNotEmpty) {
      return ritual.purpose!.trim();
    }

    // 4. Static blessings fallback
    if (ritual.title.trim().isNotEmpty) {
      return 'May the divine blessings of ${ritual.title} bestow upon you peace, protection, and boundless prosperity.';
    }
    return 'May Lord bless you with divine peace, prosperity, and happiness.';
  }

  @override
  Widget build(BuildContext context) {
    return _BaseWizardScreen(
      onBack: onBack,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const Spacer(flex: 2),
            // Success Icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFFCF7EF).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 80,
                color: Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              ritual.days.length <= 1
                  ? 'Ritual Completed\nSuccessfully!'
                  : 'Ritual Day - $dayNumber Completed\nSuccessfully!',
              textAlign: TextAlign.center,
              style: AppTypography.lora(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFCF7EF),
                height: 1.2,
              ),
            ),
            const SizedBox(height: 20),
            // Highlighted Blessings Container
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD180).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFFFD180).withValues(alpha: 0.4),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        size: 18,
                        color: Color(0xFFFFD180),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Divine Blessings',
                        style: AppTypography.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFFD180),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  RichTextDisplay(
                    _blessingText,
                    textAlign: TextAlign.center,
                    style: AppTypography.inter(
                      fontSize: 15,
                      color: const Color(0xFFFCF7EF),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(flex: 2),

            // Donation Section
            GestureDetector(
              onTap: () async {
                if (Get.isRegistered<OfflineService>() &&
                    !Get.find<OfflineService>().checkAndShowDialog()) {
                  return;
                }
                MakeDonationScreen.show(context);
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF421204),
                      Color(0xFF8B2C0F),
                      Color(0xFFC04E15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCF7EF).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.volunteer_activism_outlined,
                        color: Color(0xFFFCF7EF),
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Make a Donation',
                            style: AppTypography.inter(
                              color: const Color(0xFFFCF7EF).withValues(alpha: 0.8),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Help us give you an outstanding experience',
                            style: AppTypography.lora(
                              color: const Color(0xFFFCF7EF),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE87C3E),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Donate',
                        style: AppTypography.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFFCF7EF),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),
            _WizardButton(
              label: 'Back to Ritual',
              onTap: onFinish,
              showBack: false,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

