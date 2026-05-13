import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/shared/widgets/app_background.dart';
import 'package:satya_devotte_app/features/rituals/presentation/models/pooja_view_model.dart';

class PoojaStepWizard extends StatefulWidget {
  const PoojaStepWizard({super.key, required this.pooja});
  final PoojaView pooja;

  @override
  State<PoojaStepWizard> createState() => _PoojaStepWizardState();
}

class _PoojaStepWizardState extends State<PoojaStepWizard> {
  late final PageController _pageController;
  int _currentPage = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _screens = _buildScreens();
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

  List<String> _stringList(dynamic raw) {
    if (raw is List) return raw.map((e) => e.toString()).toList();
    if (raw is String && raw.isNotEmpty) return [raw];
    return [];
  }

  void _nextPage() {
    if (_currentPage < _screens.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage++);
    }
  }

  // ← NEW: go to previous wizard page, or pop if on first page
  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage--);
    } else {
      Get.back();
    }
  }

  void _finish() {
    Get.back();
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
                                    'Check out this Pooja/App on Sathya Devotee! \n\n'
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
                                      'Share App/Pooja',
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
          children: [
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [
                  Color(0xFFFFD180),
                  Color(0xFFFF6D00),
                  Color(0xFFFFAB40),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: SizedBox(
                width: double.infinity,
                child: Text(
                  pooja.title,
                  textAlign: TextAlign.start,
                  style: AppTypography.lora(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              pooja.description,
              textAlign: TextAlign.start,
              style: AppTypography.inter(
                fontSize: 16,
                color: Color(0xFFFFD180),
                height: 1.5,
              ),
            ),
            const Spacer(),
            _WizardButton(label: 'Proceed', onTap: onNext),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
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
      onBack: onBack, // ← NEW
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 180),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [
                  Color(0xFFFFD180),
                  Color(0xFFFF6D00),
                  Color(0xFFFFAB40),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: SizedBox(
                width: double.infinity,
                child: Text(
                  title,
                  textAlign: TextAlign.start,
                  style: AppTypography.lora(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.start,
              style: AppTypography.inter(
                fontSize: 14,
                color: Color(0xFFFF9D00),
                height: 1.5,
              ),
            ),
            const Spacer(),
            _WizardButton(label: buttonLabel, onTap: onNext),
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
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [
                  Color(0xFFFFD180),
                  Color(0xFFFF6D00),
                  Color(0xFFFFAB40),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: SizedBox(
                width: double.infinity,
                child: Text(
                  title,
                  textAlign: TextAlign.start,
                  style: AppTypography.lora(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            items[index],
                            style: AppTypography.inter(
                              fontSize: 15,
                              color: Colors.white,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            _WizardButton(label: 'Next', onTap: onNext),
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
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [
                  Color(0xFFFFD180),
                  Color(0xFFFF6D00),
                  Color(0xFFFFAB40),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: SizedBox(
                width: double.infinity,
                child: Text(
                  title,
                  textAlign: TextAlign.start,
                  style: AppTypography.lora(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.09),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      items[index],
                      style: AppTypography.inter(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  );
                },
              ),
            ),
            _WizardButton(label: 'Next', onTap: onNext),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
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
    final t = text.trim().toLowerCase();
    if (t.startsWith('recite') ||
        t.startsWith('chant') ||
        text.trim().startsWith('"') ||
        text.trim().startsWith('\u201c') ||
        text.trim().startsWith('\u2018')) {
      return _StepCardType.mantra;
    }
    if (text.trim().contains('•') || t.contains('represents')) {
      return _StepCardType.significance;
    }
    return _StepCardType.instruction;
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
      if (type == _StepCardType.mantra) {
        // accumulate mantra lines together
        pendingMantraLines.add(line.trim());
      } else {
        // flush any buffered mantra first
        flushMantra();
        blocks.add(_StepBlock(text: line.trim(), type: type));
      }
    }
    flushMantra(); // flush trailing mantra lines

    return blocks;
  }

  Widget _buildStepCard(String text, _StepCardType type) {
    switch (type) {
      case _StepCardType.mantra:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF3B1E08).withOpacity(0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFFFD180).withOpacity(0.25),
            ),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: AppTypography.inter(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: const Color(0xFFFFD180),
              height: 1.8,
            ),
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
            Text(
              'Step ${step.number}/$totalSteps',
              style: AppTypography.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [
                  Color(0xFFFFD180),
                  Color(0xFFFF6D00),
                  Color(0xFFFFAB40),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: SizedBox(
                width: double.infinity,
                child: Text(
                  step.title,
                  textAlign: TextAlign.start,
                  style: AppTypography.lora(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Description blocks (grouped)
                    for (final block in blocks)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _buildStepCard(block.text, block.type),
                      ),

                    // subSteps always render as mantra cards
                    if (step.subSteps.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      for (final sub in step.subSteps)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildStepCard(sub, _StepCardType.mantra),
                        ),
                    ],
                  ],
                ),
              ),
            ),
            _WizardButton(
              label: step.number == totalSteps ? 'Complete Puja' : 'Next',
              onTap: onNext,
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
              'Pooja Completed\nSuccessfully!',
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
              onTap: () => Get.toNamed(AppRoutes.userDonations),
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFB10F33), Color(0xFF8E0B2A)],
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
                        color: const Color(0x22FFFFFF),
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
                            'Make a Donation',
                            style: AppTypography.lora(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Support noble causes & earn blessings',
                            style: AppTypography.inter(
                              color: const Color(0xFFFDE7EC),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0x26FFFFFF),
                      ),
                      child: const Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                        size: 22,
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
