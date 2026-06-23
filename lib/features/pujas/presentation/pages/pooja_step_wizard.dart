import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/features/offline/presentation/pages/no_internet_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/features/profile/presentation/controllers/pooja_history_controller.dart';
import 'package:satya_devotte_app/features/pujas/domain/repositories/puja_repository.dart';
import 'package:satya_devotte_app/shared/widgets/app_background.dart';
import 'package:satya_devotte_app/features/donations/presentation/pages/make_donation_screen.dart';
import 'package:satya_devotte_app/features/profile/presentation/widgets/profile_ui.dart';
import 'package:satya_devotte_app/features/pujas/presentation/models/pooja_view_model.dart';
import 'package:satya_devotte_app/core/services/offline_service.dart';
import 'package:get/get.dart';

class PoojaStepWizard extends StatefulWidget {
  const PoojaStepWizard({
    super.key,
    required this.pooja,
    this.initialStep,
    this.sessionId,
  });
  final PoojaView pooja;
  final int? initialStep;
  final String? sessionId;

  @override
  State<PoojaStepWizard> createState() => _PoojaStepWizardState();
}

class _PoojaStepWizardState extends State<PoojaStepWizard> {
  late final PageController _pageController;
  late int _currentPage;
  List<Widget> _screens = [];
  String? _sessionId;
  bool _isLoadingFullPooja = false;
  bool _isStartingSession = false;
  late PoojaView _currentPooja;

  @override
  void initState() {
    super.initState();
    _currentPooja = widget.pooja;
    _currentPage = _normaliseStep(widget.initialStep);
    _sessionId = widget.sessionId;

    if (_currentPooja.preparation.isEmpty) {
      _loadFullPooja();
    } else {
      _screens = _buildScreens();
      _currentPage = _clampStep(_currentPage);
    }
    _pageController = PageController(initialPage: _currentPage);
  }

  Future<void> _loadFullPooja() async {
    setState(() => _isLoadingFullPooja = true);
    try {
      final ritualRepo = Get.find<RitualRepository>();
      final fullRitual = await ritualRepo.getRitualDetail(_currentPooja.id);
      if (fullRitual != null) {
        // Assume ritualRepo.getRitualDetail returns a PoojaEntity that can be mapped
        // For now, let's update _currentPooja if the structure allows
        // If your RitualEntity has a toModel/toMap method:
        // _currentPooja = PoojaView(fullRitual.toMap());
      }
    } catch (e) {
      debugPrint('Error loading full pooja: $e');
    } finally {
      if (mounted) {
        setState(() {
          _screens = _buildScreens();
          _currentPage = _clampStep(_currentPage);
          if (_pageController.hasClients) {
            _pageController.jumpToPage(_currentPage);
          }
          _isLoadingFullPooja = false;
        });
      }
    }
  }

  Future<void> _startSession() async {
    if (_isStartingSession) return;
    _isStartingSession = true;

    try {
      final historyCtrl = Get.find<PoojaHistoryController>();
      final result = await historyCtrl.startPooja(widget.pooja.id);
      if (result != null) {
        if (mounted) {
          setState(() {
            _sessionId = result['_id'] ?? result['id'];
            if (widget.initialStep == null) {
              final step = result['currentStep'] as int? ?? 0;
              if (step > 0 && step < _screens.length) {
                _currentPage = step;
                _pageController.jumpToPage(step);
              }
            }
          });
        }
      }
    } finally {
      _isStartingSession = false;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<Widget> _buildScreens() {
    final List<Widget> screens = [];

    // 1. Intro Screen
    screens.add(
      _IntroScreen(
        pooja: widget.pooja,
        onNext: _nextPage,
        onBack: _previousPage,
      ),
    );

    // 2. Before you begin
    screens.add(
      _SimpleInfoScreen(
        title: 'Before you begin',
        subtitle: 'Let\'s get started with the preparation for puja',
        buttonLabel: 'Start Preparation',
        onNext: _nextPage,
        onBack: _previousPage,
      ),
    );

    // 3. Personal Preparation
    final personalPrep = _stringList(widget.pooja.preparation['personal']);
    if (personalPrep.isNotEmpty) {
      screens.add(
        _ListScreen(
          title: 'Personal Preparation',
          items: personalPrep,
          onNext: _nextPage,
          onBack: _previousPage,
        ),
      );
    }

    // 4. Space Preparation
    final spacePrep = _stringList(widget.pooja.preparation['space']);
    if (spacePrep.isNotEmpty) {
      screens.add(
        _ListScreen(
          title: 'Space Preparation',
          items: spacePrep,
          onNext: _nextPage,
          onBack: _previousPage,
        ),
      );
    }

    // 5. Ingredients
    final items = _stringList(widget.pooja.preparation['items']);
    if (items.isNotEmpty) {
      screens.add(
        _IngredientsScreen(
          title: 'Prayer items / Ingredients Required:',
          items: items,
          onNext: _nextPage,
          onBack: _previousPage,
        ),
      );
    }

    // 6. Let's Begin
    screens.add(
      _SimpleInfoScreen(
        title: 'Let\'s Begin the Puja',
        subtitle:
            'Since you have done all the prerequisites for performing the puja, now you can start your puja with peace and no distractions.',
        buttonLabel: 'Start Puja',
        onNext: _nextPage,
        onBack: _previousPage,
      ),
    );

    // 7. Puja Steps
    for (int i = 0; i < widget.pooja.steps.length; i++) {
      screens.add(
        _PujaStepScreen(
          step: widget.pooja.steps[i],
          totalSteps: widget.pooja.steps.length,
          audioUrl: widget.pooja.audioUrl,
          onNext: _nextPage,
          onBack: _previousPage,
        ),
      );
    }

    // 8. Completion Screen
    screens.add(
      _CompletionScreen(
        pooja: widget.pooja,
        onFinish: _finish,
        onBack: _previousPage,
      ),
    );

    return screens;
  }

  int _normaliseStep(int? step) {
    if (step == null || step < 0) return 0;
    return step;
  }

  int _clampStep(int step) {
    if (_screens.isEmpty) return 0;
    return step.clamp(0, _screens.length - 1).toInt();
  }

  List<String> _stringList(dynamic raw) {
    if (raw is List) return raw.map((e) => e.toString()).toList();
    if (raw is String && raw.isNotEmpty) return [raw];
    return [];
  }

  void _nextPage() {
    if (_currentPage < _screens.length - 1) {
      final nextIdx = _currentPage + 1;

      // Start session lazily if not already started
      if (_sessionId == null) {
        _startSession();
      }

      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage = nextIdx);

      // Update progress if we have a session
      if (_sessionId != null) {
        Get.find<PoojaHistoryController>().updateProgress(_sessionId!, nextIdx);
      }
    }
  }

  // ← NEW: go to previous wizard page, or pop if on first page
  void _previousPage() {
    if (_currentPage > 0) {
      final prevIdx = _currentPage - 1;
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage = prevIdx);

      if (_sessionId != null) {
        print('DEBUG: Wizard updating progress to PREVIOUS index: $prevIdx');
        Get.find<PoojaHistoryController>().updateProgress(_sessionId!, prevIdx);
      }
    } else {
      Get.offAllNamed(AppRoutes.home);
    }
  }

  void _finish() {
    if (_sessionId != null) {
      Get.find<PoojaHistoryController>().finishPoojaBySession(_sessionId!);
    } else {
      Get.find<PoojaHistoryController>().finishPooja(widget.pooja.id);
    }
    Get.offAllNamed(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    // ← NEW: PopScope handles Android system back button
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _previousPage();
      },
      child: AppBackground(
        showPattern: false,
        rotateFooter: true,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: _screens,
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── UI Components ──────────────────────────

class _BaseWizardScreen extends StatelessWidget {
  const _BaseWizardScreen({
    required this.child,
    this.showBackButton = true,
    this.audioUrl,
    this.showPattern = false,
    this.onBack, // ← NEW
  });
  final Widget child;
  final bool showBackButton;
  final String? audioUrl;
  final bool showPattern;
  final VoidCallback? onBack; // ← NEW

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      showPattern: showPattern,
      rotateFooter: true,
      animatePatterns: showPattern,
      child: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: // Inside _BaseWizardScreen's build → SafeArea → Column → Padding → Row:
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Back button — always shown
                      GestureDetector(
                        onTap: onBack,
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.08),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.14),
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 18,
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

                      // Right Actions
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Play Mantra button — only when audioUrl is present
                          if (audioUrl != null) ...[
                            GestureDetector(
                              onTap: () {
                                // TODO: trigger audio playback
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.07),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.18),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Gradient play circle
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [
                                            Color(0xFFFFBF00),
                                            Color(0xFFFF6200),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.play_arrow,
                                        color: Colors.white,
                                        size: 13,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Play mantra',
                                      style: AppTypography.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],

                          // Share button
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                debugPrint('Share button tapped');
                                const shareText =
                                    'Check out this Puja/App on Sathya! \n\n'
                                    'Download for Android: https://play.google.com/store/apps/details?id=com.sathyadevotee.app \n'
                                    'Download for iOS: https://apps.apple.com/app/sathya-devotee/id123456789';
                                Share.share(shareText).catchError((e) {
                                  debugPrint('Share error: $e');
                                });
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: Colors.white.withOpacity(0.08),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.14),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.share_outlined,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Share App/Puja',
                                      style: AppTypography.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IntroScreen extends StatelessWidget {
  const _IntroScreen({
    required this.pooja,
    required this.onNext,
    required this.onBack,
  }); // ← CHANGED
  final PoojaView pooja;
  final VoidCallback onNext;
  final VoidCallback onBack; // ← NEW

  @override
  Widget build(BuildContext context) {
    return _BaseWizardScreen(
      showPattern: true,
      onBack: onBack, // ← NEW
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Spacer(),
            _WizardFadeSlideIn(
              child: _WizardGradientTitle(text: pooja.title, fontSize: 28),
            ),
            const SizedBox(height: 20),
            _WizardFadeSlideIn(
              delay: const Duration(milliseconds: 120),
              child: Text(
                pooja.description,
                textAlign: TextAlign.start,
                style: AppTypography.inter(
                  fontSize: 16,
                  color: Color(0xFFFFD180),
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _WizardFadeSlideIn(
              delay: const Duration(milliseconds: 180),
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Get.to(() => _PoojaKnowMoreScreen(pooja: pooja)),
                  behavior: HitTestBehavior.opaque,
                  child: Text(
                    'Know more about the puja →',
                    style:
                        AppTypography.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ).copyWith(
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.white,
                          decorationThickness: 2.0,
                        ),
                  ),
                ),
              ),
            ),
            const Spacer(),
            _WizardFadeSlideIn(
              delay: const Duration(milliseconds: 240),
              child: _WizardButton(label: 'Proceed', onTap: onNext),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _PoojaKnowMoreScreen extends StatelessWidget {
  const _PoojaKnowMoreScreen({required this.pooja});

  final PoojaView pooja;

  String get _whyPerformed {
    final why = pooja.purpose['why']?.toString().trim() ?? '';
    if (why.isNotEmpty) return why;
    return pooja.description.trim();
  }

  List<String> get _expectedOutcomes =>
      _poojaStringList(pooja.purpose['benefits']);

  String get _deityAbout {
    final summary = pooja.deitySummary['about']?.toString().trim() ?? '';
    if (summary.isNotEmpty) return summary;
    final doc = pooja.deityDoc;
    if (doc == null) return '';
    return (doc['about'] ??
            doc['description'] ??
            doc['who'] ??
            doc['summary'] ??
            '')
        .toString()
        .trim();
  }

  List<String> get _coreBlessings {
    final fromSummary = _poojaStringList(pooja.deitySummary['blessings']);
    if (fromSummary.isNotEmpty) return fromSummary;
    return pooja.blessings;
  }

  @override
  Widget build(BuildContext context) {
    final sections = <Widget>[];

    final why = _whyPerformed;
    if (why.isNotEmpty) {
      sections.add(
        _KnowMoreInfoCard(title: 'Why is this ritual performed?', body: why),
      );
    }

    final outcomes = _expectedOutcomes;
    if (outcomes.isNotEmpty) {
      sections.add(
        _KnowMoreInfoCard(
          title: 'What outcomes can be expected?',
          bullets: outcomes,
        ),
      );
    }

    final deityAbout = _deityAbout;
    if (deityAbout.isNotEmpty) {
      sections.add(
        _KnowMoreInfoCard(title: 'Who is the Deity?', body: deityAbout),
      );
    }

    final blessings = _coreBlessings;
    if (blessings.isNotEmpty) {
      sections.add(
        _KnowMoreInfoCard(
          title: 'Core Blessings of this Deity',
          bullets: blessings,
        ),
      );
    }

    if (sections.isEmpty) {
      sections.add(
        const _KnowMoreInfoCard(
          title: 'About this puja',
          body: 'More information will be available soon.',
        ),
      );
    }

    return _BaseWizardScreen(
      showPattern: true,
      onBack: () => Get.back(),
      child: DefaultTextStyle(
        style: const TextStyle(decoration: TextDecoration.none),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFFFFBF00), Color(0xFFFF6200)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ).createShader(bounds),
                blendMode: BlendMode.srcIn,
                child: Text(
                  'Know More about the Puja',
                  style: AppTypography.lora(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFFD180),
                    height: 1.2,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.separated(
                  itemCount: sections.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (_, index) => sections[index],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _KnowMoreInfoCard extends StatelessWidget {
  const _KnowMoreInfoCard({required this.title, this.body, this.bullets});

  final String title;
  final String? body;
  final List<String>? bullets;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0XFFEAE1D5).withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.lora(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFFFD180),
              decoration: TextDecoration.none,
            ),
          ),
          if (body != null && body!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              body!,
              style: AppTypography.inter(
                fontSize: 14,
                height: 1.55,
                color: Colors.white.withOpacity(0.92),
                decoration: TextDecoration.none,
              ),
            ),
          ],
          if (bullets != null && bullets!.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final item in bullets!)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ',
                      style: AppTypography.inter(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.92),
                        decoration: TextDecoration.none,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item,
                        style: AppTypography.inter(
                          fontSize: 14,
                          height: 1.5,
                          color: Colors.white.withOpacity(0.92),
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

List<String> _poojaStringList(dynamic raw) {
  if (raw is List) {
    return raw
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }
  if (raw is String && raw.trim().isNotEmpty) {
    return raw
        .split(RegExp(r'[,;\n]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }
  return const [];
}

class _SimpleInfoScreen extends StatelessWidget {
  const _SimpleInfoScreen({
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onNext,
    required this.onBack, // ← NEW
  });
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onNext;
  final VoidCallback onBack; // ← NEW

  @override
  Widget build(BuildContext context) {
    return _BaseWizardScreen(
      showPattern: true,
      onBack: onBack,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 180),
            _WizardFadeSlideIn(
              child: _WizardGradientTitle(text: title, fontSize: 28),
            ),
            const SizedBox(height: 10),
            _WizardFadeSlideIn(
              delay: const Duration(milliseconds: 120),
              child: Text(
                subtitle,
                textAlign: TextAlign.start,
                style: AppTypography.inter(
                  fontSize: 14,
                  color: Color(0xFFFF9D00),
                  height: 1.5,
                ),
              ),
            ),
            const Spacer(),
            _WizardFadeSlideIn(
              delay: const Duration(milliseconds: 240),
              child: _WizardButton(label: buttonLabel, onTap: onNext),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _ListScreen extends StatelessWidget {
  const _ListScreen({
    required this.title,
    required this.items,
    required this.onNext,
    required this.onBack, // ← NEW
  });
  final String title;
  final List<String> items;
  final VoidCallback onNext;
  final VoidCallback onBack; // ← NEW

  @override
  Widget build(BuildContext context) {
    return _BaseWizardScreen(
      onBack: onBack, // ← NEW
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            _WizardFadeSlideIn(
              child: _WizardGradientTitle(text: title, fontSize: 24),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  return _WizardFadeSlideIn(
                    delay: Duration(milliseconds: 160 + (index * 70)),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        items[index],
                        style: AppTypography.inter(
                          fontSize: 15,
                          color: Colors.white,
                          height: 1.4,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            _WizardFadeSlideIn(
              delay: Duration(milliseconds: 220 + (items.length * 70)),
              child: _WizardButton(label: 'Next', onTap: onNext),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _IngredientsScreen extends StatelessWidget {
  const _IngredientsScreen({
    required this.title,
    required this.items,
    required this.onNext,
    required this.onBack, // ← NEW
  });
  final String title;
  final List<String> items;
  final VoidCallback onNext;
  final VoidCallback onBack; // ← NEW

  @override
  Widget build(BuildContext context) {
    return _BaseWizardScreen(
      onBack: onBack, // ← NEW
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            _WizardFadeSlideIn(
              child: _WizardGradientTitle(text: title, fontSize: 24),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  return _WizardFadeSlideIn(
                    delay: Duration(milliseconds: 140 + (index * 60)),
                    child: _IngredientChecklistTile(label: items[index]),
                  );
                },
              ),
            ),
            _WizardFadeSlideIn(
              delay: Duration(milliseconds: 200 + (items.length * 60)),
              child: _WizardButton(label: 'Next', onTap: onNext),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _IngredientChecklistTile extends StatefulWidget {
  const _IngredientChecklistTile({required this.label});

  final String label;

  @override
  State<_IngredientChecklistTile> createState() =>
      _IngredientChecklistTileState();
}

class _IngredientChecklistTileState extends State<_IngredientChecklistTile> {
  bool _checked = false;

  void _toggle(bool? value) {
    setState(() => _checked = value ?? !_checked);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _toggle(!_checked),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
        decoration: BoxDecoration(
          color: _checked
              ? const Color(0xFFFFD180).withValues(alpha: 0.14)
              : Colors.white.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _checked
                ? const Color(0xFFFFD11A).withValues(alpha: 0.28)
                : Colors.white.withValues(alpha: 0.04),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.label,
                style: AppTypography.inter(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.9),
                  height: 1.25,
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: _checked,
                onChanged: _toggle,
                checkColor: const Color(0xFF4A1C00),
                activeColor: const Color(0xFFFFD11A),
                side: BorderSide(
                  color: Colors.white.withValues(alpha: 0.86),
                  width: 1.8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2),
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
      ),
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
                        ? Colors.white.withOpacity(0.4)
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

class _PujaStepScreen extends StatelessWidget {
  const _PujaStepScreen({
    required this.step,
    required this.totalSteps,
    required this.onNext,
    this.audioUrl,
    required this.onBack,
  });
  final StepView step;
  final int totalSteps;
  final VoidCallback onNext;
  final String? audioUrl;
  final VoidCallback onBack;

  _StepCardType _detectType(String text) {
    final trimmed = text.trim();
    final t = trimmed.toLowerCase();
    if (t.startsWith('recite') ||
        t.startsWith('chant') ||
        trimmed.startsWith('"') ||
        trimmed.startsWith('\u201c') ||
        trimmed.startsWith('\u2018')) {
      return _StepCardType.mantra;
    }
    if (text.trim().contains('•') || t.contains('represents')) {
      return _StepCardType.significance;
    }
    return _StepCardType.instruction;
  }

  bool _introducesMantra(String text) {
    final t = text.toLowerCase();
    return t.contains('prayer') ||
        t.contains('mantra') ||
        t.contains('chant') ||
        t.contains('recite');
  }

  bool _looksLikeActionInstruction(String text) {
    final t = text.trim().toLowerCase();
    const actionStarts = [
      'light ',
      'say ',
      'ring ',
      'offer ',
      'place ',
      'take ',
      'sprinkle ',
      'apply ',
      'hold ',
      'sit ',
      'stand ',
      'bow ',
      'close ',
      'open ',
      'keep ',
      'prepare ',
      'clean ',
      'wash ',
      'pour ',
      'wave ',
      'perform ',
    ];
    return actionStarts.any(t.startsWith);
  }

  String _formatMantraText(String text) {
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

  /// Groups consecutive mantra lines into a single block,
  /// keeps instruction/significance lines as individual blocks.
  List<_StepBlock> _parseBlocks(String description) {
    final lines = description
        .split('\n')
        .where((e) => e.trim().isNotEmpty)
        .toList();

    final List<_StepBlock> blocks = [];
    final List<String> pendingMantraLines = [];
    var expectingMantra = false;

    void flushMantra() {
      if (pendingMantraLines.isNotEmpty) {
        blocks.add(
          _StepBlock(
            text: pendingMantraLines.join('\n'),
            type: _StepCardType.mantra,
          ),
        );
        pendingMantraLines.clear();
      }
    }

    for (final line in lines) {
      final type = _detectType(line);
      if (type == _StepCardType.mantra ||
          (expectingMantra && !_looksLikeActionInstruction(line))) {
        pendingMantraLines.add(line.trim());
      } else {
        flushMantra();
        blocks.add(_StepBlock(text: line.trim(), type: type));
        expectingMantra = _introducesMantra(line);
      }
    }
    flushMantra(); // flush trailing mantra lines

    return blocks;
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
              Text(
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
            color: const Color(0xFF2A1005).withOpacity(0.8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFF9D00).withOpacity(0.2)),
          ),
          child: Text(
            text,
            style: AppTypography.inter(
              fontSize: 13,
              color: Colors.white.withOpacity(0.75),
              height: 1.6,
            ),
          ),
        );

      case _StepCardType.instruction:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            text,
            style: AppTypography.inter(
              fontSize: 15,
              color: Colors.white,
              height: 1.6,
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final blocks = _parseBlocks(step.description);

    return _BaseWizardScreen(
      audioUrl: audioUrl,
      onBack: onBack,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _WizardFadeSlideIn(
              child: Text(
                'Step ${step.number}/$totalSteps',
                style: AppTypography.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _WizardFadeSlideIn(
              delay: const Duration(milliseconds: 100),
              child: _WizardGradientTitle(text: step.title, fontSize: 24),
            ),
            const SizedBox(height: 20),
            if (step.imageUrls.isNotEmpty) ...[
              _WizardFadeSlideIn(
                delay: const Duration(milliseconds: 140),
                child: _AutoScrollCarousel(imageUrls: step.imageUrls),
              ),
              const SizedBox(height: 16),
            ],
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < blocks.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _WizardFadeSlideIn(
                          delay: Duration(milliseconds: 180 + (i * 70)),
                          child: _buildStepCard(blocks[i].text, blocks[i].type),
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
                              _StepCardType.mantra,
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
                label: step.number == totalSteps ? 'Complete Puja' : 'Next',
                onTap: onNext,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ── helpers ──────────────────────────────────────────────────────

class _CompletionScreen extends StatelessWidget {
  const _CompletionScreen({
    required this.pooja,
    required this.onFinish,
    required this.onBack,
  });
  final PoojaView pooja;
  final VoidCallback onFinish;
  final VoidCallback onBack;

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
                color: Colors.white.withOpacity(0.1),
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
              'Puja Completed\nSuccessfully!',
              textAlign: TextAlign.center,
              style: AppTypography.lora(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'May Lord ${pooja.deityName} bless you with peace and prosperity.',
              textAlign: TextAlign.center,
              style: AppTypography.inter(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
                height: 1.5,
              ),
            ),
            const Spacer(flex: 2),

            // Donation Section
            GestureDetector(
              onTap: () async {
                if (!Get.find<OfflineService>().checkAndShowDialog()) {
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
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.volunteer_activism_outlined,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Make a Contribution',
                            style: AppTypography.inter(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Help us give you an outstanding experience',
                            style: AppTypography.lora(
                              color: Colors.white,
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
                        'Contribute',
                        style: AppTypography.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),
            _WizardButton(label: 'Back to Home', onTap: onFinish),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

const _wizardTitleGradient = LinearGradient(
  colors: [Color(0xFFFFD180), Color(0xFFFF6D00), Color(0xFFFFAB40)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

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
    final baseStyle = AppTypography.lora(
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      height: 1.2,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: text, style: baseStyle),
          textAlign: textAlign,
          textDirection: Directionality.of(context),
          maxLines: null,
        )..layout(maxWidth: constraints.maxWidth);

        return Text(
          text,
          textAlign: textAlign,
          style: baseStyle.copyWith(
            decoration: TextDecoration.none,
            foreground: Paint()
              ..shader = _wizardTitleGradient.createShader(
                Rect.fromLTWH(0, 0, painter.width, painter.height),
              ),
          ),
        );
      },
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

enum _StepCardType { instruction, mantra, significance }

class _StepBlock {
  const _StepBlock({required this.text, required this.type});
  final String text;
  final _StepCardType type;
}

class _WizardButton extends StatelessWidget {
  const _WizardButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
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
  }
}
