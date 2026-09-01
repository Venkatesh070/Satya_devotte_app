import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/features/cms/models/ritual_model.dart';
import 'package:satya_devotte_app/features/profile/presentation/controllers/ritual_history_controller.dart';
import 'package:satya_devotte_app/shared/widgets/app_background.dart';
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
  bool _dayStarted = false;
  bool _isBusy = false;
  bool _ritualFinished = false;

  RitualHistoryController get _history => Get.find<RitualHistoryController>();

  @override
  void initState() {
    super.initState();
    _sessionId = widget.sessionId;
    _currentDay = widget.initialDay ?? 1;
    _currentPage = widget.initialStep ?? 0;
    _pageController = PageController(initialPage: _currentPage);
    _dayStarted = _currentPage > 0;
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

  int get _totalPages => 1 + _steps.length + (_ritualFinished ? 1 : 0);

  Future<bool> _ensureSession() async {
    if (_sessionId != null) return true;
    setState(() => _isBusy = true);
    try {
      final result = await _history.startRitual(widget.ritual.id);
      final session = result?['session'];
      if (session is Map) {
        final id = (session['_id'] ?? session['id'])?.toString();
        if (id != null && id.isNotEmpty) {
          setState(() {
            _sessionId = id;
            _currentDay = (session['currentDay'] as num?)?.toInt() ?? _currentDay;
          });
          return true;
        }
      }
      return false;
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<bool> _ensureDayStarted() async {
    if (_dayStarted) return true;
    if (!await _ensureSession()) return false;

    if (widget.ritual.isMultiDayRitual && _currentDay > 1) {
      setState(() => _isBusy = true);
      try {
        final result = await _history.startDay(_sessionId!);
        if (result == null) return false;
      } finally {
        if (mounted) setState(() => _isBusy = false);
      }
    }

    setState(() => _dayStarted = true);
    return true;
  }

  Future<void> _nextPage() async {
    if (_isBusy) return;

    if (_currentPage == 0) {
      if (!await _ensureDayStarted()) return;
    } else if (_sessionId == null) {
      if (!await _ensureSession()) return;
    }

    if (_currentPage < _totalPages - 1) {
      final nextIdx = _currentPage + 1;
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage = nextIdx);

      if (_sessionId != null && _currentPage > 0 && _currentPage <= _steps.length) {
        await _history.updateProgress(
          _sessionId!,
          _currentPage,
          currentDay: _currentDay,
        );
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
      setState(() => _currentPage = prevIdx);
      if (_sessionId != null && _currentPage > 0) {
        _history.updateProgress(
          _sessionId!,
          _currentPage,
          currentDay: _currentDay,
        );
      }
    } else {
      Get.back();
    }
  }

  Future<void> _completeDay() async {
    if (_isBusy) return;
    if (!await _ensureDayStarted()) return;
    if (_sessionId == null) return;

    setState(() => _isBusy = true);
    try {
      if (_steps.isNotEmpty && _currentPage < _steps.length) {
        await _history.updateProgress(
          _sessionId!,
          _steps.length,
          currentDay: _currentDay,
        );
      }

      final result = await _history.completeDay(_sessionId!);
      if (result == null) return;

      final session = result['session'];
      final finished = result['ritualFinished'] == true ||
          (session is Map && session['status'] == 'FINISHED');
      final dayDone = (result['dayCompleted'] as num?)?.toInt() ?? _currentDay;

      setState(() {
        _ritualFinished = finished;
      });

      if (finished) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !_pageController.hasClients) return;
          final lastPage = _buildPages().length - 1;
          _pageController.jumpToPage(lastPage);
          setState(() => _currentPage = lastPage);
        });
      } else {
        Get.back(result: true);
        Get.snackbar(
          'Day $dayDone completed',
          widget.ritual.isMultiDayRitual
              ? 'Come back tomorrow for Day ${dayDone + 1}.'
              : 'Well done!',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  List<Widget> _buildPages() {
    final day = _dayDef;
    final pages = <Widget>[
      _RequiredItemsScreen(
        ritual: widget.ritual,
        dayNumber: _currentDay,
        day: day,
        onNext: _steps.isEmpty ? _completeDay : _nextPage,
        onBack: _previousPage,
        isBusy: _isBusy,
        actionLabel: _steps.isEmpty
            ? 'Complete Day $_currentDay'
            : 'Start Day $_currentDay',
      ),
    ];

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
          nextLabel: isLast ? 'Complete Day $_currentDay' : 'Next',
          isBusy: _isBusy,
        ),
      );
    }

    if (_ritualFinished) {
      pages.add(
        _CompletionScreen(
          ritualTitle: widget.ritual.title,
          onFinish: () => Get.offAllNamed(AppRoutes.home),
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

class _WizardShell extends StatelessWidget {
  const _WizardShell({
    required this.child,
    required this.onBack,
    this.title,
  });

  final Widget child;
  final VoidCallback onBack;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back, color: Color(0xFFFCF7EF)),
                ),
                if (title != null)
                  Expanded(
                    child: Text(
                      title!,
                      style: AppTypography.lora(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFCF7EF),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _RequiredItemsScreen extends StatelessWidget {
  const _RequiredItemsScreen({
    required this.ritual,
    required this.dayNumber,
    required this.day,
    required this.onNext,
    required this.onBack,
    required this.isBusy,
    required this.actionLabel,
  });

  final RitualModel ritual;
  final int dayNumber;
  final RitualDay? day;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final bool isBusy;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    final items = day?.requiredItems ?? const <String>[];
    final dayTitle = day?.title.trim().isNotEmpty == true
        ? day!.title.trim()
        : 'Day $dayNumber';

    return _WizardShell(
      onBack: onBack,
      title: ritual.title,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Text(
              dayTitle,
              style: AppTypography.lora(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFFFD180),
              ),
            ),
            if (ritual.isMultiDayRitual) ...[
              const SizedBox(height: 8),
              Text(
                'Day $dayNumber of ${ritual.days.length}',
                style: AppTypography.inter(
                  fontSize: 14,
                  color: const Color(0xFFFCF7EF).withValues(alpha: 0.75),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Text(
              'Required items',
              style: AppTypography.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFFCF7EF),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: items.isEmpty
                  ? Text(
                      'No specific items listed for this day.',
                      style: AppTypography.inter(
                        fontSize: 14,
                        color: const Color(0xFFFCF7EF).withValues(alpha: 0.8),
                      ),
                    )
                  : ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFCF7EF).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          items[i],
                          style: AppTypography.inter(
                            fontSize: 14,
                            color: const Color(0xFFFCF7EF),
                          ),
                        ),
                      ),
                    ),
            ),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isBusy ? null : onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFCF7EF),
                  foregroundColor: const Color(0xFF255AE2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
                child: isBusy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        actionLabel,
                        style: AppTypography.inter(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

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
    required this.isBusy,
  });

  final RitualDayStep step;
  final int stepIndex;
  final int totalSteps;
  final int dayNumber;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final String nextLabel;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final title = step.title.trim().isEmpty
        ? 'Step $stepIndex'
        : step.title.trim();

    return _WizardShell(
      onBack: onBack,
      title: 'Day $dayNumber',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              'Step $stepIndex/$totalSteps',
              style: AppTypography.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFFCF7EF).withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: AppTypography.lora(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFFFD180),
              ),
            ),
            const SizedBox(height: 16),
            if (step.images.isNotEmpty) ...[
              SizedBox(
                height: 140,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: step.images.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: step.images[i],
                      width: 140,
                      height: 140,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Expanded(
              child: SingleChildScrollView(
                child: step.description.trim().isNotEmpty
                    ? StepRichTextDisplay.wizard(step.description)
                    : Text(
                        'Follow the instructions for this step.',
                        style: AppTypography.inter(
                          fontSize: 15,
                          color: const Color(0xFFFCF7EF),
                          height: 1.5,
                        ),
                      ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onBack,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFCF7EF),
                      side: BorderSide(
                        color: const Color(0xFFFCF7EF).withValues(alpha: 0.35),
                      ),
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                    child: const Text('Back'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isBusy ? null : onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFCF7EF),
                      foregroundColor: const Color(0xFF255AE2),
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                    child: isBusy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(nextLabel),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _CompletionScreen extends StatelessWidget {
  const _CompletionScreen({
    required this.ritualTitle,
    required this.onFinish,
    required this.onBack,
  });

  final String ritualTitle;
  final VoidCallback onFinish;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return _WizardShell(
      onBack: onBack,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Spacer(flex: 2),
            const Icon(
              Icons.check_circle_rounded,
              size: 80,
              color: Color(0xFF4CAF50),
            ),
            const SizedBox(height: 24),
            Text(
              'Ritual Completed!',
              textAlign: TextAlign.center,
              style: AppTypography.lora(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFCF7EF),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You completed "$ritualTitle".',
              textAlign: TextAlign.center,
              style: AppTypography.inter(
                fontSize: 16,
                color: const Color(0xFFFCF7EF).withValues(alpha: 0.85),
              ),
            ),
            const Spacer(flex: 2),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: onFinish,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFCF7EF),
                  foregroundColor: const Color(0xFF255AE2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
                child: const Text('Back to Home'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
