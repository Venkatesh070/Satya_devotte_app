import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:satya_devotte_app/core/network/api_client.dart';
import 'package:satya_devotte_app/core/network/api_endpoints.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/shared/widgets/custom_button.dart';
import 'package:video_player/video_player.dart';
import 'package:satya_devotte_app/features/rituals/presentation/widgets/media_player_section.dart';
import 'package:satya_devotte_app/features/rituals/presentation/models/pooja_view_model.dart';
import 'package:satya_devotte_app/features/rituals/presentation/widgets/ritual_shared_widgets.dart';

/// Pooja / Ritual detail page – pixel-aligned to the Sathya Devotee
/// Figma reference (saffron temple header, circular deity portrait,
/// pill segmented tabs, white section cards, gradient \"Get Started\"
/// CTA at the bottom).
///
/// Loads `GET /api/v1/poojas/:id` and segregates every server field
/// (`purpose`, `deitySummary`, `preparation`, `steps`, `mantra`,
/// `spiritualMeaning`, `guidance`, `completion`, `blessings`) under
/// four scrollable tabs:
///
///   • Calender Puja's        – schedule / status / festivals
///   • About the Deity        – deitySummary + populated `deity` doc
///   • Rituals and Remedies   – purpose / preparation / steps / mantra /
///                              spiritualMeaning / guidance / completion
///   • Stories of Deity       – narrative sections from the deity doc
class RitualDetailPage extends StatefulWidget {
  const RitualDetailPage({super.key});

  @override
  State<RitualDetailPage> createState() => _RitualDetailPageState();
}

class _RitualDetailPageState extends State<RitualDetailPage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _pooja;
  Map<String, String> _festivalNames = const {};

  late final TabController _tabController;
  static const _tabs = <String>[
    'About the Ritual',
    'Rituals and Remedies',
    'About the Deity',
    'Stories',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: 0,
    );

    final args = Get.arguments;
    if (args is Map<String, dynamic>) {
      _pooja = args;
      final id = args['_id']?.toString() ?? args['id']?.toString();
      if (id != null && id.isNotEmpty) _loadDetail(id);
    } else if (args is String && args.isNotEmpty) {
      _loadDetail(args);
    } else {
      _error = 'No pooja selected.';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ───────────────────────── networking ──────────────────────────
  Future<void> _loadDetail(String id) async {
    if (_isLoading) return;
    setState(() {
      _isLoading = _pooja == null;
      _error = null;
    });
    try {
      final res = await Get.find<ApiClient>().dio.get<dynamic>(
        ApiEndpoints.pooja(id),
      );
      final payload = res.data;
      Map<String, dynamic>? pooja;
      final data = payload is Map<String, dynamic> ? payload['data'] : null;
      if (data is Map<String, dynamic>) {
        final inner = data['pooja'];
        pooja = inner is Map<String, dynamic> ? inner : data;
      } else if (payload is Map<String, dynamic>) {
        pooja = payload;
      }
      if (!mounted) return;
      setState(() => _pooja = pooja ?? _pooja);
      await _hydrateDeityIfNeeded();
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message ?? 'Failed to load pooja.');
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Failed to load pooja.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// When the populated `deity` field is just an ObjectId string we hit
  /// `/api/v1/deities/:id` so the About / Stories tabs can render the
  /// full set of cards (family, posture, description, weapons, chakra,
  /// astrology, …) shown in the Figma.
  Future<void> _hydrateDeityIfNeeded() async {
    final p = _pooja;
    if (p == null) return;
    final d = p['deity'];

    // If it's already a map, check if it already has the "stories" or "sections" we need.
    // If it does, we can skip the extra network call.
    if (d is Map) {
      final stories = d['stories'];
      debugPrint(
        'Deity doc already has stories: ${stories is List ? stories.length : 'no'}',
      );
      final sections = d['sections'];
      final hasDetailedInfo =
          (stories is List && stories.isNotEmpty) ||
          (sections is List && sections.isNotEmpty);
      if (hasDetailedInfo) return;
    }

    final id = d is String ? d : (d is Map ? (d['_id'] ?? d['id']) : null);
    if (id is! String || id.isEmpty) return;

    final isObjectId =
        id.length == 24 && RegExp(r'^[0-9a-fA-F]+$').hasMatch(id);
    if (!isObjectId) return;

    try {
      final res = await Get.find<ApiClient>().dio.get<dynamic>(
        ApiEndpoints.deity(id),
      );
      final payload = res.data;
      if (payload is! Map<String, dynamic>) return;

      Map<String, dynamic>? deity;
      final data = payload['data'];
      if (data is Map<String, dynamic>) {
        if (data['deity'] is Map) {
          deity = Map<String, dynamic>.from(data['deity'] as Map);
        } else if (data['deities'] is List &&
            (data['deities'] as List).isNotEmpty) {
          final first = (data['deities'] as List).first;
          if (first is Map) deity = Map<String, dynamic>.from(first);
        } else {
          deity = data;
        }
      } else if (payload['deity'] is Map) {
        deity = Map<String, dynamic>.from(payload['deity'] as Map);
      } else {
        deity = payload;
      }

      if (!mounted || deity == null) return;

      debugPrint('SUCCESS: Fetched detailed deity doc for ${deity['name']}');
      debugPrint(
        'Stories count: ${deity['stories'] is List ? (deity['stories'] as List).length : 0}',
      );

      final hasName = deity['name'] != null || deity['title'] != null;
      final hasStories =
          deity['stories'] != null ||
          deity['sections'] != null ||
          deity['description'] != null;

      if (hasName || hasStories) {
        setState(() {
          final Map<String, dynamic> current = Map<String, dynamic>.from(
            _pooja!,
          );
          final Map existingDeity = (current['deity'] is Map)
              ? (current['deity'] as Map)
              : {};

          // Strictly merge into a Map<String, dynamic> to avoid type mismatches
          final Map<String, dynamic> mergedDeity = {};
          existingDeity.forEach((k, v) => mergedDeity[k.toString()] = v);
          deity!.forEach((k, v) => mergedDeity[k.toString()] = v);

          current['deity'] = mergedDeity;
          _pooja = current;
        });
      }
    } catch (e) {
      debugPrint('Hydration via deity endpoint failed: $e');
    }
  }

  // ───────────────────────── build ───────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isLoading && _pooja == null) {
      return const Scaffold(
        backgroundColor: AppColors.appBgColor,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_pooja == null) {
      return Scaffold(
        backgroundColor: AppColors.appBgColor,
        appBar: AppBar(
          backgroundColor: AppColors.appBgColor,
          elevation: 0,
          foregroundColor: AppColors.textColor,
        ),
        body: Center(
          child: Text(
            _error ?? 'No ritual found',
            style: AppTypography.inter(color: AppColors.textColor),
          ),
        ),
      );
    }

    final p = PoojaView(_pooja!);

    return Scaffold(
      backgroundColor: AppColors.appBgColor,
      body: Stack(
        children: [
          NestedScrollView(
            headerSliverBuilder: (_, __) => [
              SliverToBoxAdapter(child: _HeroHeader(pooja: p)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const HeaderDivider(),
                      const SizedBox(height: 14),

                      if (p.description.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            p.description,
                            textAlign: TextAlign.center,
                            style: AppTypography.inter(
                              fontSize: 13.5,
                              height: 1.55,
                              color: const Color(0xFF4A1C00),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      const SizedBox(height: 14),
                      const HeaderDivider(),
                      const SizedBox(height: 14),
                      Text(
                        'More Options',
                        style: AppTypography.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF3B1E08),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _SegmentedTabs(controller: _tabController, tabs: _tabs),
                    ],
                  ),
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _CalendarTab(
                  key: ValueKey('cal_${p.title}'),
                  pooja: p,
                  festivalNames: _festivalNames,
                ),
                _RitualsTab(key: ValueKey('rit_${p.title}'), pooja: p),
                _AboutDeityTab(key: ValueKey('abt_${p.deityName}'), pooja: p),
                _StoriesTab(
                  key: ValueKey(
                    'story_${p.deityName}_${p.deityStories.length}',
                  ),
                  pooja: p,
                ),
              ],
            ),
          ),
          // Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(),
              elevation: 2,
              shadowColor: Color(0x22000000),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: Get.back,
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    size: 18,
                    color: Color(0xFF1F1F1F),
                  ),
                ),
              ),
            ),
          ),
          // Get Started CTA
          Positioned(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).padding.bottom + 16,
            child: CustomButton(
              label: 'Get Started',
              borderRadius: 14,
              onTap: () => Get.to(() => _StartedRitualPage(pooja: p)),
              textColor: AppColors.white,
              gradientColors: const [
                AppColors.gradientStart,
                AppColors.gradientEnd,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  Hero Header  (saffron decorative top + circular deity portrait)
// ════════════════════════════════════════════════════════════════
class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.pooja});
  final PoojaView pooja;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(color: AppColors.appBgColor),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              // 1. Background image (Temple header with dynamic hero image overlay)
              SizedBox(
                width: double.infinity,
                height: 200,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Background Image (Asset)
                    Image.asset(
                      'assets/images/appHeaderImg.png',
                      fit: BoxFit.fill,
                    ),

                    // Network Image (stretched over background)
                    Image.network(
                      pooja.heroImage!,
                      fit: BoxFit.fill, // IMPORTANT
                      alignment: Alignment.center,
                      color: Colors.black.withOpacity(0.2), // optional overlay
                      colorBlendMode: BlendMode.darken,
                    ),
                  ],
                ),
              ),
              // 3. Circular Deity Portrait
              Positioned(
                bottom: -50,
                child: _DeityPortrait(imageUrl: pooja.heroImage),
              ),
            ],
          ),

          const SizedBox(height: 64), // Space for the overlapping portrait
          Text(
            pooja.deityName,
            style: AppTypography.lora(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF3B1E08),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _DeityPortrait extends StatelessWidget {
  const _DeityPortrait({required this.imageUrl});
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 116,
      height: 116,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.appBgColor,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipOval(
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallback(),
              )
            : _fallback(),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFD89A), Color(0xFFE0884A)],
        ),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.temple_hindu, size: 52, color: Colors.white),
    );
  }
}

/// Soft curved cream edge for the hero image, matching the Figma header.
class _HeroCurve extends StatelessWidget {
  const _HeroCurve({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 58),
      painter: _HeroCurvePainter(color),
    );
  }
}

class _HeroCurvePainter extends CustomPainter {
  const _HeroCurvePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, size.height * 0.3)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 1.0,
        size.width,
        size.height * 0.3,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height * 0.7);
    path.quadraticBezierTo(
      size.width * 0.2,
      size.height * 0.7,
      size.width * 0.5,
      size.height * 0.95,
    );
    path.quadraticBezierTo(
      size.width * 0.8,
      size.height * 0.7,
      size.width,
      size.height * 0.7,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// ════════════════════════════════════════════════════════════════
//  Segmented Pill Tabs
// ════════════════════════════════════════════════════════════════
class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs({required this.controller, required this.tabs});
  final TabController controller;
  final List<String> tabs;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: AnimatedBuilder(
        animation: controller,
        builder: (_, __) {
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: tabs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final selected = controller.index == i;
              return GestureDetector(
                onTap: () => controller.animateTo(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: selected
                        ? const LinearGradient(
                            colors: [
                              AppColors.gradientStart,
                              AppColors.gradientEnd,
                            ],
                          )
                        : null,
                    color: selected ? null : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? Colors.transparent
                          : const Color(0x33B07A3A),
                    ),
                    boxShadow: selected
                        ? const [
                            BoxShadow(
                              color: Color(0x33ED5A00),
                              blurRadius: 10,
                              offset: Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    tabs[i],
                    style: AppTypography.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : const Color(0xFF3B1E08),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  Tab: About the Deity
// ════════════════════════════════════════════════════════════════
// ════════════════════════════════════════════════════════════════
//  Tab: About the Deity
// ════════════════════════════════════════════════════════════════
class _AboutDeityTab extends StatelessWidget {
  const _AboutDeityTab({super.key, required this.pooja});
  final PoojaView pooja;

  String _str(dynamic v) => (v ?? '').toString().trim();
  List<String> _list(dynamic v) => _RitualsTab._stringList(v);

  @override
  Widget build(BuildContext context) {
    final summary = pooja.deitySummary;
    final purpose = pooja.purpose;
    final deityDoc = pooja.deityDoc;

    // Field resolution — every label tries multiple possible API paths
    // so the same widget renders whether the server returns a sparse
    // deitySummary or a fully populated deity document.
    final altNames = _list(
      deityDoc?['alternate_names'] ??
          deityDoc?['otherNames'] ??
          deityDoc?['names'] ??
          deityDoc?['derivation'],
    );
    final divineRole =
        _str(
          deityDoc?['divine_role'] ??
              deityDoc?['divineRole'] ??
              deityDoc?['description'] ??
              summary['about'],
        ).isEmpty
        ? _list(deityDoc?['roles']).join(', ')
        : _str(
            deityDoc?['divine_role'] ??
                deityDoc?['divineRole'] ??
                deityDoc?['description'] ??
                summary['about'],
          );

    final family = _str(
      deityDoc?['family'] ??
          deityDoc?['family_associations'] ??
          deityDoc?['lineage'],
    );
    final posture = _str(
      deityDoc?['posture'] ?? deityDoc?['seating'] ?? deityDoc?['iconography'],
    );
    final physical =
        _str(
          deityDoc?['physical_description'] ??
              deityDoc?['physicalDescription'] ??
              deityDoc?['appearance'],
        ).isEmpty
        ? _list(deityDoc?['appearance']).join(', ')
        : _str(
            deityDoc?['physical_description'] ??
                deityDoc?['physicalDescription'] ??
                deityDoc?['appearance'],
          );
    final whyPray = _str(
      deityDoc?['why_pray'] ?? deityDoc?['whyPray'] ?? purpose['why'],
    );
    final keyQualities = _list(
      deityDoc?['key_qualities'] ??
          deityDoc?['qualities'] ??
          deityDoc?['energies'] ??
          summary['blessings'],
    );
    final weapons = _meaningList(
      deityDoc?['weapons'] ?? deityDoc?['adornments'] ?? deityDoc?['symbols'],
    );
    final chakra = _str(deityDoc?['chakra'] ?? deityDoc?['chakras']);
    final astrology = _str(
      deityDoc?['vedic_astrology'] ??
          deityDoc?['astrology'] ??
          deityDoc?['numerology'],
    );
    final blessings = _list(summary['blessings'] ?? deityDoc?['blessings']);
    final deityNameDisplay = pooja.deityName.isNotEmpty
        ? pooja.deityName
        : pooja.title; // Always show *something*.

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 140),
      children: [
        const SectionHeader(title: 'Deity Information'),
        const SizedBox(height: 10),
        LabeledField(label: 'Deity Name', value: deityNameDisplay),
        if (altNames.isNotEmpty)
          LabeledChipsField(
            label: 'Derivation/ Other Names / Forms (if applicable)',
            items: altNames,
          ),
        if (divineRole.isNotEmpty)
          LabeledField(
            label: 'Divine Role (God/ Goddess of)',
            value: divineRole,
            multiline: true,
          ),
        if (family.isNotEmpty) ...[
          const SizedBox(height: 4),
          const SectionHeader(title: 'Divine Structure & Lineage'),
          const SizedBox(height: 10),
          LabeledField(
            label: 'Family / Divine Associations',
            value: family,
            multiline: true,
          ),
        ],
        if (posture.isNotEmpty)
          LabeledField(
            label: 'Seating / Posture (Iconography)',
            value: posture,
            multiline: true,
          ),
        if (physical.isNotEmpty)
          LabeledField(
            label: 'Physical Description',
            value: physical,
            multiline: true,
          ),
        if (weapons.isNotEmpty) ...[
          const SizedBox(height: 4),
          const SectionHeader(title: 'Symbols & Weapons'),
          const SizedBox(height: 10),
          for (final w in weapons)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: LabeledField(
                label: w.title,
                value: w.description,
                multiline: true,
              ),
            ),
        ],
        if (divineRole.isNotEmpty ||
            whyPray.isNotEmpty ||
            keyQualities.isNotEmpty ||
            chakra.isNotEmpty ||
            astrology.isNotEmpty) ...[
          const SizedBox(height: 4),
          const SectionHeader(title: 'Purpose of the Ritual'),
          const SizedBox(height: 10),
          if (divineRole.isNotEmpty)
            LabeledField(
              label: 'Who is the Deity?',
              value: divineRole,
              multiline: true,
            ),
          if (whyPray.isNotEmpty)
            LabeledField(
              label: 'Why Pray to This Deity',
              value: whyPray,
              multiline: true,
            ),
          if (keyQualities.isNotEmpty)
            LabeledChipsField(
              label: 'Key Qualities / Energies Represented',
              items: keyQualities,
              positive: true,
            ),
          if (chakra.isNotEmpty)
            LabeledField(
              label: 'Associated Chakras',
              value: chakra,
              multiline: true,
            ),
          if (astrology.isNotEmpty)
            LabeledField(
              label: 'Astrological Connection',
              value: astrology,
              multiline: true,
            ),
          if (blessings.isNotEmpty)
            LabeledChipsField(
              label: 'Blessings',
              items: blessings,
              positive: true,
            ),
        ],
        // Render any structured \"sections\" array provided by the deity doc.
        if (deityDoc != null && deityDoc['sections'] is List) ...[
          for (final s in (deityDoc['sections'] as List).whereType<Map>())
            DeitySectionCard(section: s.cast<String, dynamic>()),
        ],
      ],
    );
  }

  static List<MeaningItem> _meaningList(dynamic raw) {
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((m) {
      return MeaningItem(
        title: (m['title'] ?? m['name'] ?? '').toString(),
        description: (m['description'] ?? m['meaning'] ?? m['symbolism'] ?? '')
            .toString(),
      );
    }).toList();
  }
}

// ════════════════════════════════════════════════════════════════
//  Tab: Rituals & Remedies
// ════════════════════════════════════════════════════════════════
class _RitualsTab extends StatelessWidget {
  const _RitualsTab({super.key, required this.pooja});
  final PoojaView pooja;

  @override
  Widget build(BuildContext context) {
    final deityDoc = pooja.deityDoc;
    final sections = pooja.deitySections;
    final stories = pooja.deityStories;

    final storySections = sections.where((m) {
      final key = (m['key'] ?? '').toString().toLowerCase();
      final title = (m['title'] is Map)
          ? (m['title']['value'] ?? '').toString().toLowerCase()
          : (m['title'] ?? '').toString().toLowerCase();
      return key.contains('story') ||
          key.contains('legend') ||
          key.contains('lineage') ||
          key.contains('origin') ||
          title.contains('story') ||
          title.contains('legend') ||
          title.contains('lineage') ||
          title.contains('origin');
    }).toList();

    final fallbackStory =
        (deityDoc?['story'] ??
                deityDoc?['legend'] ??
                deityDoc?['origin'] ??
                deityDoc?['description'] ??
                pooja.deitySummary['about'] ??
                '')
            .toString();

    final hasAnyStory =
        fallbackStory.isNotEmpty ||
        storySections.isNotEmpty ||
        stories.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 140),
      children: [
        if (pooja.purpose.isNotEmpty)
          _SectionCard(
            icon: Icons.auto_awesome,
            title: 'Purpose',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (pooja.purpose['why'] != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      pooja.purpose['why'].toString(),
                      style: AppTypography.inter(
                        fontSize: 13.5,
                        height: 1.5,
                        color: const Color(0xFF4A1C00),
                      ),
                    ),
                  ),
                BulletList(
                  heading: 'Benefits',
                  items: _stringList(pooja.purpose['benefits']),
                ),
              ],
            ),
          ),
        if (hasAnyStory) ...[
          const SizedBox(height: 12),
          _SectionCard(
            icon: Icons.menu_book_outlined,
            title: 'Deity Story',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (fallbackStory.isNotEmpty) ...[
                  Text(
                    fallbackStory,
                    style: AppTypography.inter(
                      fontSize: 13.5,
                      height: 1.55,
                      color: const Color(0xFF4A1C00),
                    ),
                  ),
                  if (stories.isNotEmpty || storySections.isNotEmpty)
                    const SizedBox(height: 12),
                ],
                for (final s in stories) DeitySectionCard(section: s),
                for (final s in storySections) DeitySectionCard(section: s),
              ],
            ),
          ),
        ],
      ],
    );
  }

  static List<String> _stringList(dynamic raw) {
    if (raw is List) {
      return raw
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList();
    }
    if (raw is String && raw.trim().isNotEmpty) {
      return raw
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const [];
  }

  static List<MeaningItem> _meaningList(dynamic raw) {
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((m) {
      return MeaningItem(
        title: (m['title'] ?? '').toString(),
        description: (m['description'] ?? '').toString(),
      );
    }).toList();
  }
}

class _StartedRitualPage extends StatelessWidget {
  const _StartedRitualPage({required this.pooja});
  final PoojaView pooja;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBgColor,
      appBar: AppBar(
        backgroundColor: AppColors.appBgColor,
        elevation: 0,
        foregroundColor: const Color(0xFF3B1E08),
        title: Text(
          pooja.title.isNotEmpty ? pooja.title : 'Ritual',
          style: AppTypography.lora(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF3B1E08),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          if (pooja.mantraView.primary.isNotEmpty)
            _MantraCard(mantra: pooja.mantraView, audioUrl: pooja.audioUrl),

          if (pooja.preparation.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionCard(
              icon: Icons.spa_outlined,
              title: 'Preparation',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BulletList(
                    heading: 'Personal',
                    items: _RitualsTab._stringList(
                      pooja.preparation['personal'],
                    ),
                  ),
                  _BulletList(
                    heading: 'Sacred Space',
                    items: _RitualsTab._stringList(pooja.preparation['space']),
                  ),
                  _BulletList(
                    heading: 'Items Required',
                    items: _RitualsTab._stringList(pooja.preparation['items']),
                    asChips: true,
                  ),
                ],
              ),
            ),
          ],

          if (pooja.steps.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionCard(
              icon: Icons.format_list_numbered,
              title: 'Steps to Perform',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [for (final s in pooja.steps) _StepTile(step: s)],
              ),
            ),
          ],

          if (pooja.spiritualMeaning.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionCard(
              icon: Icons.brightness_7_outlined,
              title: 'Spiritual Meaning',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MeaningGroup(
                    heading: 'Offerings',
                    items: _RitualsTab._meaningList(
                      pooja.spiritualMeaning['offeringsMeaning'],
                    ),
                  ),
                  _MeaningGroup(
                    heading: 'Actions',
                    items: _RitualsTab._meaningList(
                      pooja.spiritualMeaning['actionsMeaning'],
                    ),
                  ),
                  _MeaningGroup(
                    heading: 'Other Symbolism',
                    items: _RitualsTab._meaningList(
                      pooja.spiritualMeaning['otherSymbolism'],
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (pooja.guidance.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionCard(
              icon: Icons.self_improvement,
              title: 'Guidance',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BulletList(
                    heading: 'Right Mindset',
                    items: _RitualsTab._stringList(pooja.guidance['mindset']),
                    asChips: true,
                    positive: true,
                  ),
                  _BulletList(
                    heading: 'Avoid',
                    items: _RitualsTab._stringList(pooja.guidance['avoid']),
                    asChips: true,
                    positive: false,
                  ),
                ],
              ),
            ),
          ],

          if (pooja.completion.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionCard(
              icon: Icons.flag_outlined,
              title: 'Completion',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BulletList(
                    heading: 'Closure',
                    items: _RitualsTab._stringList(pooja.completion['closure']),
                  ),
                  _BulletList(
                    heading: 'Integration',
                    items: _RitualsTab._stringList(
                      pooja.completion['integration'],
                    ),
                  ),
                  _BulletList(
                    heading: 'Benefits',
                    items: _RitualsTab._stringList(
                      pooja.completion['benefits'],
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (pooja.blessings.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionCard(
              icon: Icons.favorite_border,
              title: 'Blessings',
              child: _ChipWrap(items: pooja.blessings, positive: true),
            ),
          ],

          if (pooja.videoUrls.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionCard(
              icon: Icons.play_circle_outline,
              title: 'Video Guidance',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final url in pooja.videoUrls)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: MediaPlayerSection(mediaUrl: url),
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

// ════════════════════════════════════════════════════════════════
//  Tab: Stories of Deity
// ════════════════════════════════════════════════════════════════
class _StoriesTab extends StatelessWidget {
  const _StoriesTab({super.key, required this.pooja});
  final PoojaView pooja;

  @override
  Widget build(BuildContext context) {
    final deityDoc = pooja.deityDoc;
    final stories = pooja.deityStories;
    final sections = pooja.deitySections;

    debugPrint('StoriesTab build: Found ${stories.length} stories in array');

    final storySections = sections.where((m) {
      final key = (m['key'] ?? '').toString().toLowerCase();
      final title = (m['title'] is Map)
          ? (m['title']['value'] ?? '').toString().toLowerCase()
          : (m['title'] ?? '').toString().toLowerCase();

      final keywords = [
        'story',
        'legend',
        'lineage',
        'origin',
        'history',
        'narrative',
        'background',
        'creation',
        'structure',
      ];

      return keywords.any((k) => key.contains(k) || title.contains(k));
    }).toList();

    // Primary narrative from the deity object itself
    final deityNarrative =
        (deityDoc?['story'] ??
                deityDoc?['legend'] ??
                deityDoc?['origin'] ??
                deityDoc?['description'] ??
                deityDoc?['about'] ??
                '')
            .toString();

    // If we have actual deity stories or sections, we DON'T want to show the
    // generic pooja summary "old story" at the top.
    final hasRealDeityContent = stories.isNotEmpty || storySections.isNotEmpty;

    // The fallback is only used if we have absolutely no other narrative.
    final fallbackSummary = (!hasRealDeityContent && deityNarrative.isEmpty)
        ? pooja.deitySummary['about']?.toString() ?? ''
        : '';

    if (stories.isEmpty &&
        storySections.isEmpty &&
        deityNarrative.isEmpty &&
        fallbackSummary.isEmpty) {
      return _EmptyView(
        icon: Icons.menu_book_outlined,
        message: 'No stories available for this deity yet.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 140),
      children: [
        // 1. Render actual stories from the 'stories' array (this is the long story you provided)
        for (final s in stories) ...[
          StoryCard(
            title: (s['title'] ?? s['name'] ?? '').toString(),
            description: (s['description'] ?? s['content'] ?? s['text'] ?? '')
                .toString(),
          ),
          const SizedBox(height: 16),
        ],

        // 2. If no 'stories' array, fallback to deity description/narrative
        if (stories.isEmpty && deityNarrative.isNotEmpty) ...[
          QuoteCard(text: deityNarrative),
          if (storySections.isNotEmpty) const SizedBox(height: 16),
        ],

        // 3. Last resort fallback (Pooja summary)
        if (stories.isEmpty &&
            deityNarrative.isEmpty &&
            fallbackSummary.isNotEmpty) ...[
          QuoteCard(text: fallbackSummary),
        ],

        // 4. Render other story-related sections (lineage, origin, etc.)
        for (final s in storySections) ...[
          DeitySectionCard(section: s),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _StoryCard extends StatelessWidget {
  const _StoryCard({required this.title, required this.description});
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    if (description.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF3B1E08),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 2,
              width: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFE69138).withOpacity(0.3),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            description,
            style: AppTypography.inter(
              fontSize: 14,
              height: 1.6,
              color: const Color(0xFF4A1C00),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  Tab: Calender Puja's
// ════════════════════════════════════════════════════════════════
class _CalendarTab extends StatelessWidget {
  const _CalendarTab({
    super.key,
    required this.pooja,
    required this.festivalNames,
  });

  final PoojaView pooja;
  final Map<String, String> festivalNames;

  @override
  Widget build(BuildContext context) {
    final resolved = pooja.festivalIds
        .map((id) => festivalNames[id] ?? id)
        .where((name) => name.trim().isNotEmpty)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 140),
      children: [_CalendarPujaCard(pooja: pooja, festivals: resolved)],
    );
  }
}

class _CalendarPujaCard extends StatelessWidget {
  const _CalendarPujaCard({required this.pooja, required this.festivals});

  final PoojaView pooja;
  final List<String> festivals;

  @override
  Widget build(BuildContext context) {
    final title = pooja.title.isNotEmpty ? pooja.title : pooja.deityName;
    final subtitle = pooja.deityName.isNotEmpty
        ? pooja.deityName
        : pooja.category;
    final duration = pooja.duration.isNotEmpty ? pooja.duration : '45 min';
    final date = pooja.date.isNotEmpty ? pooja.date : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CalendarThumb(imageUrl: pooja.heroImage),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.lora(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF3B1E08),
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF7A4621),
                        ),
                      ),
                    const SizedBox(height: 10),
                    if (date != null) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_month_outlined,
                            size: 15,
                            color: Color(0xFF3B1E08),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            date,
                            style: AppTypography.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF3B1E08),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                    ],
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 15,
                          color: Color(0xFF3B1E08),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          duration,
                          style: AppTypography.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF3B1E08),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (festivals.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            'Festivals',
            style: AppTypography.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF7A4621),
            ),
          ),
          const SizedBox(height: 8),
          _ChipWrap(items: festivals, positive: true),
        ],
      ],
    );
  }
}

class _CalendarThumb extends StatelessWidget {
  const _CalendarThumb({required this.imageUrl});
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 78,
      height: 78,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imageUrl != null && imageUrl!.isNotEmpty
                  ? Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _fallback(),
                    )
                  : _fallback(),
            ),
          ),
          Positioned(
            right: -10,
            bottom: -6,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
                border: Border.all(color: const Color(0xFFEAD9BC), width: 1),
              ),
              child: const Icon(
                Icons.favorite_border,
                size: 20,
                color: Color(0xFFCF9B3A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallback() {
    return Container(
      color: const Color(0xFFE8C27A),
      alignment: Alignment.center,
      child: const Icon(Icons.temple_hindu, size: 34, color: Colors.white),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  Reusable building blocks
// ════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, top: 4),
      child: Text(
        title,
        style: AppTypography.inter(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF3B1E08),
        ),
      ),
    );
  }
}

class _MantraCard extends StatefulWidget {
  const _MantraCard({required this.mantra, this.audioUrl});
  final MantraView mantra;
  final String? audioUrl;

  @override
  State<_MantraCard> createState() => _MantraCardState();
}

class _MantraCardState extends State<_MantraCard> {
  VideoPlayerController? _audio;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    final url = widget.audioUrl;
    if (url != null && url.isNotEmpty) {
      _audio = VideoPlayerController.networkUrl(Uri.parse(url))
        ..initialize()
            .then((_) {
              if (!mounted) return;
              setState(() => _ready = true);
            })
            .catchError((_) {})
        ..addListener(_onAudioTick);
    }
  }

  void _onAudioTick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _audio?.removeListener(_onAudioTick);
    _audio?.dispose();
    super.dispose();
  }

  void _toggle() {
    final c = _audio;
    if (c == null || !_ready) return;
    if (c.value.isPlaying) {
      c.pause();
    } else {
      if (c.value.position >= c.value.duration) {
        c.seekTo(Duration.zero);
      }
      c.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = _audio?.value.isPlaying ?? false;
    final hasAudio = _audio != null;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.mantra.primary,
                      style: AppTypography.lora(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF3B1E08),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.repeat,
                          size: 12,
                          color: Color(0xFFB07A3A),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.mantra.repetitions.isEmpty
                              ? 'Sacred Mantra'
                              : widget.mantra.repetitions,
                          style: AppTypography.inter(
                            fontSize: 12,
                            color: const Color(0xFFB07A3A),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: hasAudio ? _toggle : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppColors.gradientStart, AppColors.gradientEnd],
                    ),
                    boxShadow: hasAudio
                        ? const [
                            BoxShadow(
                              color: Color(0x33ED5A00),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    !hasAudio
                        ? Icons.volume_off
                        : (isPlaying ? Icons.pause : Icons.play_arrow),
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
          if (hasAudio && _ready) ...[
            const SizedBox(height: 12),
            _AudioProgressBar(controller: _audio!),
          ],
          if (widget.mantra.meaning.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              widget.mantra.meaning,
              style: AppTypography.inter(
                fontSize: 12.5,
                height: 1.45,
                color: const Color(0xFF6A4423),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (widget.mantra.additional.isNotEmpty) ...[
            const SizedBox(height: 10),
            _ChipWrap(items: widget.mantra.additional, positive: true),
          ],
        ],
      ),
    );
  }
}

class _AudioProgressBar extends StatelessWidget {
  const _AudioProgressBar({required this.controller});
  final VideoPlayerController controller;

  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inMinutes)}:${two(d.inSeconds.remainder(60))}';
  }

  @override
  Widget build(BuildContext context) {
    final v = controller.value;
    final total = v.duration.inMilliseconds == 0
        ? 1
        : v.duration.inMilliseconds;
    final progress = (v.position.inMilliseconds / total).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor: const Color(0x22B07A3A),
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppColors.gradientEnd,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _fmt(v.position),
              style: AppTypography.inter(
                fontSize: 10.5,
                color: const Color(0xFF8A6B4A),
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              _fmt(v.duration),
              style: AppTypography.inter(
                fontSize: 10.5,
                color: const Color(0xFF8A6B4A),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
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
        color: Colors.white,
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
                child: Icon(icon, size: 16, color: Colors.white),
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

class _Paragraph extends StatelessWidget {
  const _Paragraph({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: AppTypography.inter(
          fontSize: 13.5,
          height: 1.5,
          color: const Color(0xFF4A1C00),
        ),
      ),
    );
  }
}

class _BulletList extends StatelessWidget {
  const _BulletList({
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
            _ChipWrap(items: items, positive: positive)
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

class _ChipWrap extends StatelessWidget {
  const _ChipWrap({required this.items, required this.positive});
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

class _StepTile extends StatelessWidget {
  const _StepTile({required this.step});
  final StepView step;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(right: 12, top: 2),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.gradientStart, AppColors.gradientEnd],
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              '${step.number}',
              style: AppTypography.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: AppTypography.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF3B1E08),
                  ),
                ),
                if (step.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    step.description,
                    style: AppTypography.inter(
                      fontSize: 13,
                      height: 1.45,
                      color: const Color(0xFF4A1C00),
                    ),
                  ),
                ],
                if (step.subSteps.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...step.subSteps.map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(bottom: 4, left: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 5, right: 8),
                            child: Icon(
                              Icons.check_circle,
                              size: 12,
                              color: Color(0xFFB07A3A),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              s,
                              style: AppTypography.inter(
                                fontSize: 12.5,
                                height: 1.45,
                                color: const Color(0xFF6A4423),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MeaningGroup extends StatelessWidget {
  const _MeaningGroup({required this.heading, required this.items});
  final String heading;
  final List<MeaningItem> items;

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
          ...items.map(
            (m) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8EC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x22B07A3A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m.title,
                    style: AppTypography.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF3B1E08),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    m.description,
                    style: AppTypography.inter(
                      fontSize: 12.5,
                      height: 1.45,
                      color: const Color(0xFF4A1C00),
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

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.icon, required this.message});
  final IconData icon;
  final String message;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: const Color(0xFF8A6B4A)),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.inter(
                fontSize: 13.5,
                color: const Color(0xFF7A5A3D),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
