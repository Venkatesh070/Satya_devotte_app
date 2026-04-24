import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/core/network/api_client.dart';
import 'package:satya_devotte_app/core/network/api_endpoints.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';

class RitualListPage extends StatefulWidget {
  const RitualListPage({super.key});

  @override
  State<RitualListPage> createState() => _RitualListPageState();
}

class _RitualListPageState extends State<RitualListPage> {
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = false;
  String? _error;
  List<PoojaListItem> _items = const [];
  String _searchQuery = '';
  final Map<String, Set<String>> _appliedFilters = <String, Set<String>>{
    'Deity': <String>{},
    'Tithis': <String>{},
    'Dosha': <String>{},
    'Benefits': <String>{},
    'Location': <String>{},
  };

  static const Map<String, List<String>> _filterOptions = <String, List<String>>{
    'Deity': <String>[
      'Hanumanji',
      'Ganeshji',
      'Shivji',
      'Lakshmi',
      'Durga',
      'Vishnu',
      'Kaal Bhairav',
      'Shani Dev',
      'Rahu',
    ],
    'Tithis': <String>[
      'Amavasya',
      'Pournami',
      'Ekadashi',
      'Pradosham',
      'Ashtami',
    ],
    'Dosha': <String>[
      'Rahu Ketu',
      'Manglik',
      'Shani',
      'Pitra',
      'Kaal Sarp',
    ],
    'Benefits': <String>[
      'Health',
      'Wealth',
      'Career',
      'Marriage',
      'Protection',
    ],
    'Location': <String>[
      'Hyderabad',
      'Bengaluru',
      'Chennai',
      'Mumbai',
      'Delhi',
    ],
  };

  @override
  void initState() {
    super.initState();
    _loadPoojas();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPoojas() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await Get.find<ApiClient>().dio.get<dynamic>(
        ApiEndpoints.poojas,
      );
      final payload = response.data;
      final data = payload is Map<String, dynamic> ? payload['data'] : null;
      final poojas = data is Map<String, dynamic> ? data['poojas'] : null;
      final list = poojas is List
          ? poojas
          : (data is List ? data : (payload is List ? payload : const []));
      final mapped = list
          .whereType<Map<String, dynamic>>()
          .map(PoojaListItem.fromJson)
          .toList();
      if (!mounted) return;
      setState(() => _items = mapped);
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message ?? 'Failed to load poojas.');
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Failed to load poojas.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<PoojaListItem> get _filteredItems {
    final q = _searchQuery.trim().toLowerCase();
    return _items.where((item) {
      if (q.isEmpty) return true;
      final textMatch =
          item.title.toLowerCase().contains(q) ||
          item.deity.toLowerCase().contains(q) ||
          item.description.toLowerCase().contains(q);
      if (!textMatch) return false;

      // Deity exact filter from API field.
      final deitySet = _appliedFilters['Deity']!;
      if (deitySet.isNotEmpty && !deitySet.contains(item.deity)) return false;

      // Remaining filters are mapped heuristically from item text.
      bool matchesByText(String key) {
        final selected = _appliedFilters[key]!;
        if (selected.isEmpty) return true;
        final haystack =
            '${item.title} ${item.description} ${item.category}'.toLowerCase();
        return selected.any((s) => haystack.contains(s.toLowerCase()));
      }

      return matchesByText('Tithis') &&
          matchesByText('Dosha') &&
          matchesByText('Benefits') &&
          matchesByText('Location');
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBgColor,
      body: SafeArea(
        top: false,
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.gradientEnd,
          onRefresh: _loadPoojas,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: _FixedHeaderDelegate(
                  minExtentHeight: MediaQuery.paddingOf(context).top + 250,
                  maxExtentHeight: MediaQuery.paddingOf(context).top + 250,
                  child: _buildHeader(),
                ),
              ),
              if (_isLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildErrorState(),
                )
              else
                _buildList(),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Header (gradient + search + chips) ──────────────────
  Widget _buildHeader() {
    final topInset = MediaQuery.paddingOf(context).top;
    return SizedBox(
      height: topInset + 250,
      child: Stack(
        children: [
          const Positioned(
            top: -280,
            left: 0,
            right: 0,
            child: Image(
              image: AssetImage('assets/images/appHeaderImg.png'),
              fit: BoxFit.fitWidth,
              alignment: Alignment.topCenter,
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, topInset + 14, 16, 10),
            child: Column(
              children: [
                _buildSearchField(),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: Row(
                    children: [
                      _QuickFilterChip(
                        label: 'Filters',
                        icon: Icons.tune,
                        onTap: () => _openFiltersBottomSheet(),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: _buildHeaderFilterChips(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildHeaderFilterChips() {
    final selected = <_SelectedFilterEntry>[];
    for (final entry in _appliedFilters.entries) {
      for (final value in entry.value) {
        selected.add(_SelectedFilterEntry(category: entry.key, value: value));
      }
    }

    if (selected.isEmpty) {
      return [
        _QuickFilterChip(
          label: 'Deity',
          onTap: () => _openFiltersBottomSheet(initialCategory: 'Deity'),
        ),
        const SizedBox(width: 8),
        _QuickFilterChip(
          label: 'Benefits',
          onTap: () => _openFiltersBottomSheet(initialCategory: 'Benefits'),
        ),
        const SizedBox(width: 8),
        _QuickFilterChip(
          label: 'Location',
          onTap: () => _openFiltersBottomSheet(initialCategory: 'Location'),
        ),
      ];
    }

    final chips = <Widget>[];
    for (var i = 0; i < selected.length; i++) {
      final item = selected[i];
      chips.add(
        _AppliedFilterChip(
          label: item.value,
          onTap: () => _openFiltersBottomSheet(initialCategory: item.category),
          onRemove: () {
            setState(() {
              _appliedFilters[item.category]!.remove(item.value);
            });
          },
        ),
      );
      if (i != selected.length - 1) {
        chips.add(const SizedBox(width: 8));
      }
    }
    return chips;
  }

  Widget _buildSearchField() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          const Icon(Icons.search, color: Color(0xFFCF6F2B), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              cursorColor: Colors.black,
              style: AppTypography.inter(fontSize: 14, color: const Color(0xFF232323)),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'Search for Shiv Puja',
                hintStyle: AppTypography.inter(
                  fontSize: 14,
                  color: const Color(0xFF8F8F8F),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── List body ───────────────────────────────────────────
  Widget _buildList() {
    final items = _filteredItems;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final listBottomPadding = bottomInset + 110;
    if (items.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Text(
              'No poojas found.',
              style: AppTypography.inter(
                fontSize: 14,
                color: const Color(0xFF7A5A3D),
              ),
            ),
          ),
        ),
      );
    }
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, listBottomPadding),
      sliver: SliverList.separated(
        itemCount: items.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == items.length) {
            return Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Center(
                child: Text(
                  'You have reached to the end of the screen.',
                  style: AppTypography.inter(
                    fontSize: 12,
                    color: const Color(0xFF8A6B4A),
                  ),
                ),
              ),
            );
          }
          final item = items[index];
          return _PoojaCard(
            item: item,
            onTap: () => Get.toNamed<dynamic>(
              AppRoutes.ritualDetail,
              arguments: item.id,
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 42, color: Color(0xFF8A6B4A)),
          const SizedBox(height: 10),
          Text(
            _error ?? 'Something went wrong.',
            textAlign: TextAlign.center,
            style: AppTypography.inter(
              fontSize: 14,
              color: const Color(0xFF4A1C00),
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: _loadPoojas,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gradientEnd,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Future<void> _openFiltersBottomSheet({String initialCategory = 'Deity'}) async {
    String activeCategory = initialCategory;
    final tempFilters = <String, Set<String>>{
      for (final e in _appliedFilters.entries) e.key: {...e.value},
    };

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final options = _filterOptions[activeCategory] ?? const <String>[];
          final selected = tempFilters[activeCategory]!;
          return SafeArea(
            top: false,
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.72,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                    child: Row(
                      children: [
                        Text(
                          'Puja Filters',
                          style: AppTypography.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E1E1E),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 112,
                          color: const Color(0xFFF7F7F7),
                          child: ListView(
                            children: _filterOptions.keys.map((k) {
                              final isActive = k == activeCategory;
                              return InkWell(
                                onTap: () => setModalState(() => activeCategory = k),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isActive ? Colors.white : const Color(0xFFF7F7F7),
                                    border: Border(
                                      left: BorderSide(
                                        color: isActive ? const Color(0xFF2A6DE6) : Colors.transparent,
                                        width: 3,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    k,
                                    style: AppTypography.inter(
                                      fontSize: 14,
                                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                                      color: const Color(0xFF2A2A2A),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CheckboxListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    'Select All',
                                    style: AppTypography.inter(fontSize: 13),
                                  ),
                                  value: selected.length == options.length && options.isNotEmpty,
                                  onChanged: (_) {
                                    setModalState(() {
                                      if (selected.length == options.length) {
                                        selected.clear();
                                      } else {
                                        selected
                                          ..clear()
                                          ..addAll(options);
                                      }
                                    });
                                  },
                                  controlAffinity: ListTileControlAffinity.leading,
                                ),
                                Text(
                                  'Select your filters',
                                  style: AppTypography.inter(
                                    fontSize: 15,
                                    color: const Color(0xFF9A9A9A),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: GridView.builder(
                                    itemCount: options.length,
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      childAspectRatio: 0.72,
                                      mainAxisSpacing: 10,
                                      crossAxisSpacing: 10,
                                    ),
                                    itemBuilder: (_, i) {
                                      final option = options[i];
                                      final checked = selected.contains(option);
                                      return GestureDetector(
                                        onTap: () {
                                          setModalState(() {
                                            if (checked) {
                                              selected.remove(option);
                                            } else {
                                              selected.add(option);
                                            }
                                          });
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                              color: checked ? const Color(0xFF2A6DE6) : const Color(0xFFE4E4E4),
                                              width: checked ? 2 : 1,
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              Expanded(
                                                child: Stack(
                                                  children: [
                                                    Container(
                                                      margin: const EdgeInsets.all(5),
                                                      decoration: BoxDecoration(
                                                        borderRadius: BorderRadius.circular(8),
                                                        gradient: const LinearGradient(
                                                          colors: [Color(0xFFECC07A), Color(0xFFB06A20)],
                                                          begin: Alignment.topCenter,
                                                          end: Alignment.bottomCenter,
                                                        ),
                                                      ),
                                                      alignment: Alignment.center,
                                                      child: Text(
                                                        option.substring(0, 1).toUpperCase(),
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontWeight: FontWeight.w800,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ),
                                                    Positioned(
                                                      right: 4,
                                                      top: 4,
                                                      child: Container(
                                                        width: 18,
                                                        height: 18,
                                                        decoration: BoxDecoration(
                                                          color: checked ? const Color(0xFF2A6DE6) : Colors.white,
                                                          borderRadius: BorderRadius.circular(4),
                                                          border: Border.all(color: const Color(0xFFD0D0D0)),
                                                        ),
                                                        child: checked
                                                            ? const Icon(Icons.check, size: 13, color: Colors.white)
                                                            : null,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
                                                child: Text(
                                                  option,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: AppTypography.inter(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Color(0xFFEAEAEA))),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              for (final set in tempFilters.values) {
                                set.clear();
                              }
                              setModalState(() {});
                            },
                            child: const Text('Clear Filter'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                for (final e in tempFilters.entries) {
                                  _appliedFilters[e.key] = {...e.value};
                                }
                              });
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2A6DE6),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Apply Filter'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Supporting widgets & models
// ─────────────────────────────────────────────────────────

class PoojaListItem {
  const PoojaListItem({
    required this.id,
    required this.title,
    required this.deity,
    required this.category,
    required this.description,
    required this.duration,
    required this.imageUrl,
  });

  factory PoojaListItem.fromJson(Map<String, dynamic> e) {
    final raw = e['imageUrl']?.toString().trim() ?? '';
    return PoojaListItem(
      id: (e['_id'] ?? e['id'] ?? '').toString(),
      title: e['title']?.toString() ?? 'Untitled Pooja',
      deity: e['deity']?.toString() ?? '',
      category: e['category']?.toString() ?? '',
      description: e['description']?.toString() ?? '',
      duration: e['duration']?.toString() ?? '',
      imageUrl: raw.isNotEmpty ? raw : null,
    );
  }

  final String id;
  final String title;
  final String deity;
  final String category;
  final String description;
  final String duration;
  final String? imageUrl;

  String get durationLabel {
    if (duration.isEmpty) return '-';
    final n = int.tryParse(duration);
    return n != null ? '$n min' : duration;
  }
}

class _PoojaCard extends StatelessWidget {
  const _PoojaCard({required this.item, required this.onTap});

  final PoojaListItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasImage = item.imageUrl != null && item.imageUrl!.trim().isNotEmpty;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              // ── IMAGE + HEART ─────────────────────
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 90,
                      height: 110,
                      child: hasImage
                          ? Image.network(item.imageUrl!, fit: BoxFit.cover)
                          : _imageFallback(),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 14),

              // ── TEXT CONTENT ─────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF3B1E08),
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Deity
                    Text(
                      item.deity,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.inter(
                        fontSize: 12,
                        color: const Color(0xFF8A6B4A),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Duration
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 13,
                          color: Color(0xFFB07A3A),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.durationLabel,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      color: const Color(0xFFEDE6D7),
      alignment: Alignment.center,
      child: const Icon(Icons.auto_awesome, color: Color(0xFFB07A3A), size: 22),
    );
  }
}

class _QuickFilterChip extends StatelessWidget {
  const _QuickFilterChip({
    required this.label,
    required this.onTap,
    this.icon,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: const Color(0xFF496182)),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: AppTypography.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF496182),
              ),
            ),
            if (icon == null) ...[
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down, size: 17, color: Color(0xFF496182)),
            ],
          ],
        ),
      ),
    );
  }
}

class _AppliedFilterChip extends StatelessWidget {
  const _AppliedFilterChip({
    required this.label,
    required this.onTap,
    required this.onRemove,
  });

  final String label;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F7FF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF5E8ED6)),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: AppTypography.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2F5FA7),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onRemove,
              child: const Icon(
                Icons.close,
                size: 16,
                color: Color(0xFF2F5FA7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedFilterEntry {
  const _SelectedFilterEntry({required this.category, required this.value});

  final String category;
  final String value;
}

class _FixedHeaderDelegate extends SliverPersistentHeaderDelegate {
  _FixedHeaderDelegate({
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
  bool shouldRebuild(covariant _FixedHeaderDelegate oldDelegate) {
    return minExtentHeight != oldDelegate.minExtentHeight ||
        maxExtentHeight != oldDelegate.maxExtentHeight ||
        child != oldDelegate.child;
  }
}
