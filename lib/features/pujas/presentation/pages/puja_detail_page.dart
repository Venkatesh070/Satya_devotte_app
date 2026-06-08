import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:satya_devotte_app/core/network/api_client.dart';
import 'package:satya_devotte_app/core/network/api_endpoints.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/features/profile/presentation/controllers/pooja_history_controller.dart';
import 'package:satya_devotte_app/shared/widgets/custom_button.dart';
import 'package:video_player/video_player.dart';
import 'package:satya_devotte_app/features/pujas/presentation/models/pooja_view_model.dart';
import 'package:satya_devotte_app/features/pujas/presentation/widgets/puja_shared_widgets.dart';
import 'package:satya_devotte_app/features/pujas/presentation/pages/pooja_step_wizard.dart';

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
  Map<String, dynamic>? _selectedDeity;
  List<Map<String, dynamic>> _deityPoojas = const [];
  List<Map<String, dynamic>> _deityRituals = const [];
  final Map<String, String> _festivalNames = const {};

  late final TabController _tabController;
  late final PoojaHistoryController _historyController;
  static const _tabs = <String>[
    'Calendar Puja\'s',
    'About the Deity',
    'Rituals and Remedies',
    'Stories of Deity',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: 0,
    );
    _tabController.addListener(_onTabChanged);
    _historyController = Get.find<PoojaHistoryController>();
    _historyController.fetchHistory();

    final args = Get.arguments;
    if (args is Map && args['type'] == 'deity') {
      _selectedDeity = Map<String, dynamic>.from(args);
      _isLoading = true;
      final id = _entityId(args);
      if (id.isNotEmpty) {
        _loadDeityDetailAndPoojas(id);
      } else {
        _isLoading = false;
        _error = 'No deity selected.';
      }
    } else if (args is Map) {
      _pooja = Map<String, dynamic>.from(args);
      final id = args['_id']?.toString() ?? args['id']?.toString();
      if (id != null && id.isNotEmpty) _loadDetail(id);
    } else if (args is String && args.isNotEmpty) {
      _loadDetail(args);
    } else {
      _error = 'No pooja selected.';
    }
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  // ───────────────────────── networking ──────────────────────────
  Future<void> _loadDeityDetailAndPoojas(String deityId) async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    } else {
      _isLoading = true;
      _error = null;
    }

    Map<String, dynamic>? deity = _selectedDeity;
    try {
      final res = await Get.find<ApiClient>().dio.get<dynamic>(
        ApiEndpoints.deity(deityId),
      );
      deity = _extractDeity(res.data) ?? deity;
    } catch (e) {
      debugPrint('Deity detail fetch failed: $e');
    }

    List<Map<String, dynamic>> poojas = const [];
    try {
      poojas = await _loadPoojasForDeity(deityId, deity);
    } catch (e) {
      debugPrint('Associated pujas fetch failed: $e');
      if (mounted) {
        setState(() => _error = 'Failed to load calendar pujas.');
      }
    }

    List<Map<String, dynamic>> rituals = const [];
    try {
      final res = await Get.find<ApiClient>().dio.get<dynamic>(
        ApiEndpoints.rituals,
        queryParameters: {'deity': deityId, 'limit': 50},
      );
      rituals = _extractList(res.data);
      rituals = rituals
          .where((r) => _poojaBelongsToDeity(r, deityId, deity))
          .toList(growable: false);
    } catch (e) {
      debugPrint('Associated rituals fetch failed: $e');
    }

    if (!mounted) return;
    setState(() {
      _selectedDeity = deity;
      _deityPoojas = poojas
          .map((p) => _mergeDeityIntoPooja(p, deity))
          .toList(growable: false);
      _deityRituals = rituals;
      _pooja = _deityPoojas.isNotEmpty
          ? _deityPoojas.first
          : _deityShellPooja(deity ?? <String, dynamic>{'_id': deityId});
      _isLoading = false;
    });
  }

  Future<List<Map<String, dynamic>>> _loadPoojasForDeity(
    String deityId,
    Map<String, dynamic>? deity,
  ) async {
    Future<List<Map<String, dynamic>>> request({String? deityQuery}) async {
      final res = await Get.find<ApiClient>().dio.get<dynamic>(
        ApiEndpoints.poojas,
        queryParameters: {
          if (deityQuery != null && deityQuery.isNotEmpty) 'deity': deityQuery,
          'limit': 100,
        },
      );
      return _extractList(res.data);
    }

    try {
      final queried = await request(deityQuery: deityId);
      return queried
          .where((p) => _poojaBelongsToDeity(p, deityId, deity))
          .toList(growable: false);
    } on DioException {
      final all = await request();
      return all
          .where((p) => _poojaBelongsToDeity(p, deityId, deity))
          .toList(growable: false);
    }
  }

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

  static List<Map<String, dynamic>> _extractList(dynamic payload) {
    dynamic data = payload;
    if (payload is Map<String, dynamic>) {
      data = payload['data'] ?? payload;
      if (data is Map) {
        data =
            data['poojas'] ??
            data['results'] ??
            data['items'] ??
            data['docs'] ??
            data['data'] ??
            data['rituals'] ??
            data['ritual'] ??
            data;
      }
      if (data is Map) {
        data =
            data['poojas'] ??
            data['results'] ??
            data['items'] ??
            data['rituals'] ??
            data['ritual'] ??
            payload['poojas'] ??
            payload['results'] ??
            payload['items'] ??
            payload['rituals'] ??
            payload['ritual'];
      }
    }
    if (data is! List) {
      if (data is Map) return [Map<String, dynamic>.from(data)];
      return const [];
    }
    return data
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList(growable: false);
  }

  static Map<String, dynamic>? _extractDeity(dynamic payload) {
    if (payload is! Map<String, dynamic>) return null;
    final data = payload['data'];
    if (data is Map<String, dynamic>) {
      final deity = data['deity'];
      if (deity is Map) return Map<String, dynamic>.from(deity);
      final deities = data['deities'];
      if (deities is List && deities.isNotEmpty && deities.first is Map) {
        return Map<String, dynamic>.from(deities.first as Map);
      }
      return Map<String, dynamic>.from(data);
    }
    final deity = payload['deity'];
    if (deity is Map) return Map<String, dynamic>.from(deity);
    return Map<String, dynamic>.from(payload);
  }

  static Map<String, dynamic> _mergeDeityIntoPooja(
    Map<String, dynamic> pooja,
    Map<String, dynamic>? deity,
  ) {
    final current = Map<String, dynamic>.from(pooja);
    if (deity == null || deity.isEmpty) return current;
    final existing = current['deity'];
    if (existing is Map) {
      current['deity'] = {
        ...existing.map((k, v) => MapEntry(k.toString(), v)),
        ...deity,
      };
    } else {
      current['deity'] = deity;
    }
    return current;
  }

  static Map<String, dynamic> _deityShellPooja(Map<String, dynamic> deity) {
    final name = (deity['name'] ?? deity['title'] ?? '').toString();
    final description = (deity['description'] ?? deity['about'] ?? '')
        .toString();
    return {
      'title': name,
      'description': description,
      'deity': deity,
      'deitySummary': {
        'about': description,
        'blessings': deity['blessings'] ?? const [],
      },
      'media':
          deity['media'] ??
          {
            if (deity['imageUrl'] != null) 'images': [deity['imageUrl']],
          },
    };
  }

  static bool _poojaBelongsToDeity(
    Map<String, dynamic> pooja,
    String deityId,
    Map<String, dynamic>? deity,
  ) {
    final expectedId = deityId.trim();
    final expectedName = (deity?['name'] ?? deity?['title'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    final raw = pooja['deity'] ?? pooja['deityId'] ?? pooja['deity_id'];
    if (raw is Map) {
      final id = _entityId(raw);
      if (id == expectedId) return true;
      final name = (raw['name'] ?? raw['title'] ?? '').toString().toLowerCase();
      return expectedName.isNotEmpty && name == expectedName;
    }
    final value = (raw ?? '').toString().trim();
    if (value == expectedId) return true;
    return expectedName.isNotEmpty && value.toLowerCase() == expectedName;
  }

  static String _entityId(Map<dynamic, dynamic> map) {
    return (map['_id'] ?? map['id'] ?? '').toString().trim();
  }

  /// Same list logic as [_CalendarTab] — used to decide if Get Started is shown.
  List<Map<String, dynamic>> _calendarPoojasFor(PoojaView pooja) {
    final activePoojaId = _entityId(pooja.raw);
    if (_deityPoojas.isNotEmpty) return _deityPoojas;
    if (activePoojaId.isNotEmpty) return [_pooja!];
    return const [];
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

        // Also fetch rituals for this deity
        try {
          final ritRes = await Get.find<ApiClient>().dio.get<dynamic>(
            ApiEndpoints.rituals,
            queryParameters: {'deity': id, 'limit': 50},
          );
          final rituals = _extractList(ritRes.data);
          if (mounted) {
            setState(() {
              _deityRituals = rituals;
            });
          }
        } catch (e) {
          debugPrint('Hydration: rituals fetch failed: $e');
        }
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

    final activePooja = _pooja!;
    final p = PoojaView(activePooja);
    final hasCalendarPujas = _calendarPoojasFor(p).isNotEmpty;
    final showGetStartedButton =
        _tabController.index == 0 &&
        hasCalendarPujas &&
        _entityId(activePooja).isNotEmpty;

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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const HeaderDivider(),
                      const SizedBox(height: 14),

                      if (p.description.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            p.description,
                            textAlign: TextAlign.justify,
                            style: AppTypography.inter(
                              fontSize: 14,
                              height: 1.55,
                              color: const Color(0xFF1C1917),
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      const SizedBox(height: 14),
                      const HeaderDivider(),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _PinnedHeaderDelegate(
                  minExtentHeight: 92,
                  maxExtentHeight: 92,
                  child: Container(
                    color: Color(0xFFFAECD2),
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'More Options',
                          style: AppTypography.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF4A1C00),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _SegmentedTabs(controller: _tabController, tabs: _tabs),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                Obx(() {
                  final pending = _historyController.pendingPoojas.toList();
                  final finished = _historyController.finishedPoojas.toList();
                  return _CalendarTab(
                    key: ValueKey('cal_${p.title}'),
                    pooja: p,
                    poojas: _deityPoojas,
                    festivalNames: _festivalNames,
                    statusForPooja: (pooja) =>
                        _statusForPooja(pooja, pending, finished),
                    onSelectPooja: (pooja) {
                      setState(() {
                        _pooja = _mergeDeityIntoPooja(pooja, _selectedDeity);
                      });
                    },
                  );
                }),
                _AboutDeityTab(key: ValueKey('abt_${p.deityName}'), pooja: p),
                _RitualsTab(
                  key: ValueKey('rit_${p.title}'),
                  pooja: p,
                  rituals: _deityRituals,
                ),
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
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: Get.back,
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(
                    Icons.arrow_back,
                    size: 18,
                    color: Color(0xFF1F1F1F),
                  ),
                ),
              ),
            ),
          ),
          if (showGetStartedButton)
            Positioned(
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).padding.bottom + 16,
              child: CustomButton(
                label: 'Get Started',
                borderRadius: 14,
                onTap: () => Get.to(() => PoojaStepWizard(pooja: p)),
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

  String? _statusForPooja(
    Map<String, dynamic> pooja,
    List<dynamic> pendingSessions,
    List<dynamic> finishedSessions,
  ) {
    final pending = pendingSessions.whereType<Map>().any(
      (session) => _sessionMatchesPooja(session, pooja),
    );
    if (pending) return 'In Progress';

    final finished = finishedSessions.whereType<Map>().any(
      (session) => _sessionMatchesPooja(session, pooja),
    );
    if (finished) return 'Finished';

    return null;
  }

  bool _sessionMatchesPooja(Map session, Map<String, dynamic> pooja) {
    final sessionPooja = session['pooja'];
    if (sessionPooja is! Map) return false;
    final sessionPoojaId = _entityId(sessionPooja);
    final poojaId = _entityId(pooja);
    if (sessionPoojaId.isNotEmpty && poojaId.isNotEmpty) {
      return sessionPoojaId == poojaId;
    }
    final sessionTitle = (sessionPooja['title'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    final title = (pooja['title'] ?? '').toString().trim().toLowerCase();
    return sessionTitle.isNotEmpty && sessionTitle == title;
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
                    if (pooja.heroImage != null && pooja.heroImage!.isNotEmpty)
                      Image.network(
                        pooja.heroImage!,
                        fit: BoxFit.fill, // IMPORTANT
                        alignment: Alignment.center,
                        color: Colors.black.withOpacity(
                          0.2,
                        ), // optional overlay
                        colorBlendMode: BlendMode.darken,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                  ],
                ),
              ),
              // 3. Circular Deity Portrait
              Positioned(
                bottom: -25,
                child: _DeityPortrait(imageUrl: pooja.heroImage),
              ),
            ],
          ),

          const SizedBox(height: 30), // Space for the overlapping portrait
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
      width: 80,
      height: 80,
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

class _PinnedHeaderDelegate extends SliverPersistentHeaderDelegate {
  _PinnedHeaderDelegate({
    required this.minExtentHeight,
    required this.maxExtentHeight,
    required this.child,
  });

  final double minExtentHeight;
  final double maxExtentHeight;
  final Widget child;

  @override
  double get minExtent => minExtentHeight;

  @override
  double get maxExtent => maxExtentHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _PinnedHeaderDelegate oldDelegate) {
    return minExtentHeight != oldDelegate.minExtentHeight ||
        maxExtentHeight != oldDelegate.maxExtentHeight ||
        child != oldDelegate.child;
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
    final physicalItems = _meaningList(
      deityDoc?['physical_description'] ??
          deityDoc?['physicalDescription'] ??
          deityDoc?['appearance'],
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

    final connecting = deityDoc?['connecting'] as Map?;
    final chanting = deityDoc?['chanting'] as Map?;
    final homePractice = deityDoc?['home_practice'] as Map?;
    final devotionalExp = deityDoc?['devotional_experience'] as Map?;
    final structure = deityDoc?['structure'] as List?;

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

        // 5. Divine Structure (Modern or Legacy)
        if (structure != null && structure.isNotEmpty) ...[
          const SizedBox(height: 14),
          const SectionHeader(title: 'Divine Structure & Symbolism'),
          const SizedBox(height: 10),
          for (final s in structure.whereType<Map>())
            DeitySectionCard(section: s.cast<String, dynamic>()),
        ] else ...[
          // Legacy/Fallback Structure
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
          if (physicalItems.isNotEmpty)
            _LabeledTitleDescriptionList(
              label: 'Physical Description',
              items: physicalItems,
            )
          else if (physical.isNotEmpty)
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
        ],

        // 1. Connecting with the Divine
        if (connecting != null) ...[
          const SizedBox(height: 14),
          const SectionHeader(title: 'Connecting with the Divine'),
          const SizedBox(height: 10),
          if (_str(connecting['how_to_pray']).isNotEmpty)
            LabeledField(
              label: 'How to Pray / Connect',
              value: _str(connecting['how_to_pray']),
              multiline: true,
            ),
          if (_list(connecting['what_pleases']).isNotEmpty)
            LabeledChipsField(
              label: 'What Pleases the Deity',
              items: _list(connecting['what_pleases']),
              positive: true,
            ),
          if (_list(connecting['displeases']).isNotEmpty)
            LabeledChipsField(
              label: 'What Displeases the Deity',
              items: _list(connecting['displeases']),
              positive: false,
            ),
          if (_list(connecting['ideal_time']).isNotEmpty)
            LabeledChipsField(
              label: 'Ideal Time for Connection',
              items: _list(connecting['ideal_time']),
            ),
        ],

        // 2. Mantras & Chanting
        if (chanting != null) ...[
          const SizedBox(height: 14),
          const SectionHeader(title: 'Mantras & Chanting'),
          const SizedBox(height: 10),
          if (_str(chanting['mantra']).isNotEmpty)
            LabeledField(
              label: 'Main Mantra',
              value: _str(chanting['mantra']),
              multiline: true,
            ),
          if (_str(chanting['repetitions']).isNotEmpty)
            LabeledField(
              label: 'Repetitions',
              value: _str(chanting['repetitions']),
            ),
          if (_list(chanting['benefits']).isNotEmpty)
            LabeledChipsField(
              label: 'Benefits of Chanting',
              items: _list(chanting['benefits']),
              positive: true,
            ),
          if (_list(chanting['preferred_days']).isNotEmpty)
            LabeledChipsField(
              label: 'Preferred Days',
              items: _list(chanting['preferred_days']),
            ),
          if (_list(chanting['associated_colors']).isNotEmpty)
            LabeledChipsField(
              label: 'Associated Colors',
              items: _list(chanting['associated_colors']),
            ),
        ],

        // 3. Home Practice
        if (homePractice != null) ...[
          const SizedBox(height: 14),
          const SectionHeader(title: 'Home Practice'),
          const SizedBox(height: 10),
          if (homePractice['do_and_dont'] is Map) ...[
            if (_list((homePractice['do_and_dont'] as Map)['do']).isNotEmpty)
              LabeledChipsField(
                label: 'Do\'s',
                items: _list((homePractice['do_and_dont'] as Map)['do']),
                positive: true,
              ),
            if (_list((homePractice['do_and_dont'] as Map)['dont']).isNotEmpty)
              LabeledChipsField(
                label: 'Don\'ts',
                items: _list((homePractice['do_and_dont'] as Map)['dont']),
                positive: false,
              ),
          ],
          if (_str(homePractice['placement']).isNotEmpty)
            LabeledField(
              label: 'Placement / Altar Setup',
              value: _str(homePractice['placement']),
              multiline: true,
            ),
          if (_list(homePractice['offerings']).isNotEmpty)
            LabeledChipsField(
              label: 'Offerings',
              items: _list(homePractice['offerings']),
              positive: true,
            ),
        ],

        // 4. Devotional Experience
        if (devotionalExp != null) ...[
          const SizedBox(height: 14),
          const SectionHeader(title: 'Devotional Experience'),
          const SizedBox(height: 10),
          if (_str(devotionalExp['sign_of_connection']).isNotEmpty)
            LabeledField(
              label: 'Signs of Connection',
              value: _str(devotionalExp['sign_of_connection']),
              multiline: true,
            ),
          if (_str(devotionalExp['notes']).isNotEmpty)
            LabeledField(
              label: 'Special Notes',
              value: _str(devotionalExp['notes']),
              multiline: true,
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

class _LabeledTitleDescriptionList extends StatelessWidget {
  const _LabeledTitleDescriptionList({
    required this.label,
    required this.items,
  });

  final String label;
  final List<MeaningItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
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
            style: AppTypography.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF8A6B4A),
            ),
          ),
          const SizedBox(height: 8),
          for (int i = 0; i < items.length; i++) ...[
            if (items[i].title.isNotEmpty)
              Text(
                items[i].title,
                style: AppTypography.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF3B1E08),
                ),
              ),
            if (items[i].description.isNotEmpty) ...[
              if (items[i].title.isNotEmpty) const SizedBox(height: 4),
              Text(
                items[i].description,
                style: AppTypography.inter(
                  fontSize: 13.5,
                  height: 1.5,
                  color: const Color(0xFF3B1E08),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            if (i != items.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  Tab: Rituals & Remedies
// ════════════════════════════════════════════════════════════════
class _RitualsTab extends StatelessWidget {
  const _RitualsTab({super.key, required this.pooja, this.rituals = const []});
  final PoojaView pooja;
  final List<Map<String, dynamic>> rituals;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 140),
      children: [
        if (rituals.isNotEmpty) ...[
          Text(
            'Deity Information',
            style: AppTypography.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF4A1C00),
            ),
          ),
          const SizedBox(height: 12),
          for (final rit in rituals) ...[
            _RitualCard(ritual: rit),
            const SizedBox(height: 16),
          ],
        ],

        if (pooja.purpose.isNotEmpty) ...[
          if (rituals.isNotEmpty) const SizedBox(height: 12),
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
        // for (final s in storySections) ...[
        //   DeitySectionCard(section: s),
        //   const SizedBox(height: 12),
        // ],
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
    required this.poojas,
    required this.festivalNames,
    required this.statusForPooja,
    required this.onSelectPooja,
  });

  final PoojaView pooja;
  final List<Map<String, dynamic>> poojas;
  final Map<String, String> festivalNames;
  final String? Function(Map<String, dynamic> pooja) statusForPooja;
  final ValueChanged<Map<String, dynamic>> onSelectPooja;

  @override
  Widget build(BuildContext context) {
    final activePoojaId = (pooja.raw['_id'] ?? pooja.raw['id'] ?? '')
        .toString()
        .trim();
    final calendarPoojas = poojas.isNotEmpty
        ? poojas
        : activePoojaId.isNotEmpty
        ? [pooja.raw]
        : const <Map<String, dynamic>>[];

    if (calendarPoojas.isEmpty) {
      return _EmptyView(
        icon: Icons.calendar_month_outlined,
        message: 'No calendar pujas available for this deity yet.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 140),
      children: [
        for (final raw in calendarPoojas) ...[
          _CalendarPujaCard(
            pooja: PoojaView(raw),
            festivals: PoojaView(raw).festivalIds
                .map((id) => festivalNames[id] ?? id)
                .where((name) => name.trim().isNotEmpty)
                .toList(),
            selected: _samePooja(raw, pooja.raw),
            statusLabel: statusForPooja(raw),
            onTap: () => onSelectPooja(raw),
          ),
          if (raw != calendarPoojas.last) const SizedBox(height: 18),
        ],
      ],
    );
  }

  static bool _samePooja(Map<String, dynamic> a, Map<String, dynamic> b) {
    final aId = (a['_id'] ?? a['id'] ?? '').toString();
    final bId = (b['_id'] ?? b['id'] ?? '').toString();
    if (aId.isNotEmpty && bId.isNotEmpty) return aId == bId;
    return identical(a, b);
  }
}

class _CalendarPujaCard extends StatelessWidget {
  const _CalendarPujaCard({
    required this.pooja,
    required this.festivals,
    required this.selected,
    this.statusLabel,
    required this.onTap,
  });

  final PoojaView pooja;
  final List<String> festivals;
  final bool selected;
  final String? statusLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = pooja.title.isNotEmpty ? pooja.title : pooja.deityName;
    final subtitle = pooja.deityName.isNotEmpty
        ? pooja.deityName
        : pooja.category;
    final duration = pooja.duration.isNotEmpty ? pooja.duration : '45 min';
    final date = _formatCalendarDate(pooja.date);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF7E8) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFFE69138) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Column(
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
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1C1917),
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
                              fontSize: 11,
                              color: const Color(0xFF78716C),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        if (statusLabel != null) ...[
                          const SizedBox(height: 8),
                          _PujaSessionStatusBadge(label: statusLabel!),
                        ],
                        const SizedBox(height: 10),
                        if (date != null) ...[
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_month_outlined,
                                size: 15,
                                color: Color(0xFF1C1917),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  date,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF1C1917),
                                  ),
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
                              color: Color(0xFF1C1917),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              duration,
                              style: AppTypography.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF1C1917),
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
          ],
        ),
      ),
    );
  }

  static String? _formatCalendarDate(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;

    DateTime? parsed = DateTime.tryParse(value);
    parsed ??= _parseDayMonthYear(value);
    if (parsed == null) {
      final beforeTime = value.split(RegExp(r'\s+')).first.trim();
      return beforeTime.isEmpty ? null : beforeTime;
    }

    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final day = parsed.day.toString().padLeft(2, '0');
    return '$day ${months[parsed.month - 1]} ${parsed.year}';
  }

  static DateTime? _parseDayMonthYear(String value) {
    final match = RegExp(r'^(\d{1,2})-(\d{1,2})-(\d{4})$').firstMatch(value);
    if (match == null) return null;
    final day = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    final year = int.tryParse(match.group(3)!);
    if (day == null || month == null || year == null) return null;
    try {
      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
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
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFE25B4B), Color(0xFFCF9B3A)],
                ).createShader(bounds),
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF183EA4), Color(0xFFE35600)],
                  ).createShader(bounds),
                  child: Icon(
                    Icons.favorite_border,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
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

class _PujaSessionStatusBadge extends StatelessWidget {
  const _PujaSessionStatusBadge({required this.label});

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

class _RitualCard extends StatelessWidget {
  const _RitualCard({required this.ritual});
  final Map<String, dynamic> ritual;

  @override
  Widget build(BuildContext context) {
    final title = (ritual['title'] ?? '').toString();
    final description = (ritual['description'] ?? '').toString();
    final imageUrl = (ritual['imageUrl'] ?? ritual['image'] ?? '').toString();
    final List<dynamic> days = ritual['days'] is List ? ritual['days'] : [];
    final List<dynamic> sections = ritual['sections'] is List
        ? ritual['sections']
        : [];

    final List<String> tags = [];
    if (ritual['difficulty'] != null) tags.add(ritual['difficulty'].toString());
    if (ritual['accessType'] != null) tags.add(ritual['accessType'].toString());
    if (ritual['ritualDays'] != null) {
      tags.add('${ritual['ritualDays']} Days');
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Image.network(
                imageUrl,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 180,
                  color: const Color(0xFFFAECD2),
                  child: const Icon(
                    Icons.image_outlined,
                    color: Color(0xFFB07A3A),
                  ),
                ),
              ),
            )
          else
            Container(
              height: 180,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFFAECD2),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: const Icon(
                Icons.local_fire_department_outlined,
                size: 48,
                color: Color(0xFFB07A3A),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF3B1E08),
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.inter(
                      fontSize: 13,
                      height: 1.5,
                      color: const Color(0xFF4A1C00),
                    ),
                  ),
                ],
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: tags.map((tag) => _TagChip(label: tag)).toList(),
                  ),
                ],
                if (sections.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Text(
                    'Remedies & Additional Info',
                    style: AppTypography.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF7A4621),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...sections.map((sec) {
                    final label = (sec['label'] ?? sec['title'] ?? '')
                        .toString();
                    final contents = sec['contents'] is List
                        ? sec['contents'] as List
                        : [];
                    final description =
                        contents.isNotEmpty && contents.first is Map
                        ? (contents.first['description'] ??
                                  contents.first['content'] ??
                                  '')
                              .toString()
                        : '';

                    if (label.isEmpty && description.isEmpty)
                      return const SizedBox.shrink();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDF7F0),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF3E5D0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (label.isNotEmpty)
                            Text(
                              label,
                              style: AppTypography.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF3B1E08),
                              ),
                            ),
                          if (description.isNotEmpty) ...[
                            if (label.isNotEmpty) const SizedBox(height: 6),
                            Text(
                              description,
                              style: AppTypography.inter(
                                fontSize: 12.5,
                                height: 1.45,
                                color: const Color(0xFF4A1C00),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                ],
                if (days.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Text(
                    'Ritual Plan',
                    style: AppTypography.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF7A4621),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...days.map((day) => _DayItem(day: day)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DayItem extends StatefulWidget {
  const _DayItem({required this.day});
  final Map<dynamic, dynamic> day;

  @override
  State<_DayItem> createState() => _DayItemState();
}

class _DayItemState extends State<_DayItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final day = widget.day;
    final dayNumber = day['dayNumber'] ?? 0;
    final title = (day['title'] ?? '').toString();
    final mantra = (day['mantra'] ?? '').toString();
    final affirmation = (day['affirmation'] ?? '').toString();
    final List<dynamic> activities = day['activities'] is List
        ? day['activities']
        : [];

    return GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBF2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF3E5D0)),
          boxShadow: _isExpanded
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0xFFB07A3A),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$dayNumber',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3B1E08),
                    ),
                  ),
                ),
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: const Color(0xFF8A6B4A),
                ),
              ],
            ),
            if (mantra.isNotEmpty || affirmation.isNotEmpty) ...[
              const SizedBox(height: 10),
              if (mantra.isNotEmpty)
                _DaySubInfo(label: 'Mantra', content: mantra, icon: Icons.mic),
              if (affirmation.isNotEmpty)
                _DaySubInfo(
                  label: 'Affirmation',
                  content: affirmation,
                  icon: Icons.favorite_border,
                ),
            ],
            if (_isExpanded && activities.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFFF3E5D0)),
              const SizedBox(height: 12),
              Text(
                'Steps / Activities',
                style: AppTypography.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF7A4621),
                ),
              ),
              const SizedBox(height: 8),
              ...activities.asMap().entries.map((entry) {
                final idx = entry.key + 1;
                final activity = entry.value.toString();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6, left: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$idx.',
                        style: AppTypography.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFB07A3A),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          activity,
                          style: AppTypography.inter(
                            fontSize: 12.5,
                            height: 1.4,
                            color: const Color(0xFF4A1C00),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

class _DaySubInfo extends StatelessWidget {
  const _DaySubInfo({
    required this.label,
    required this.content,
    required this.icon,
  });
  final String label;
  final String content;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF8A6B4A)),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppTypography.inter(
                  fontSize: 12,
                  height: 1.4,
                  color: const Color(0xFF6A4423),
                ),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: content),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF3E5D0)),
      ),
      child: Text(
        label,
        style: AppTypography.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF8A6B4A),
        ),
      ),
    );
  }
}
