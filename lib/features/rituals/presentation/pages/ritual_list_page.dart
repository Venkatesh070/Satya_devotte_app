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
  String _selectedCategory = 'All Poojas';
  String _searchQuery = '';

  static const List<String> _categories = <String>[
    'All Poojas',
    'Lakshmi Poojas',
    'Shiva Poojas',
    'Special Occasion Pooja',
    'Festival',
    'Daily Pooja',
  ];

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
      final matchesCategory =
          _selectedCategory == 'All Poojas' ||
          item.category.toLowerCase() == _selectedCategory.toLowerCase() ||
          item.deity.toLowerCase().contains(
            _selectedCategory.toLowerCase().replaceAll(' poojas', ''),
          );
      if (!matchesCategory) return false;
      if (q.isEmpty) return true;
      return item.title.toLowerCase().contains(q) ||
          item.deity.toLowerCase().contains(q) ||
          item.description.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBgColor,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.gradientEnd,
          onRefresh: _loadPoojas,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
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
    return SizedBox(
      width: double.infinity,
      height: 400,

      child: Stack(
        children: [
          const Positioned.fill(
            child: Image(
              image: AssetImage('assets/images/appHeaderImg.png'),
              fit: BoxFit.fill,
              alignment: Alignment.topCenter,
            ),
          ),
          Container(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pooja Rituals',
                      style: AppTypography.lora(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                    ),
                    _CircleIconButton(
                      icon: Icons.verified_user_outlined,
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _buildSearchField(),
                const SizedBox(height: 16),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, i) {
                      final label = _categories[i];
                      final selected = label == _selectedCategory;
                      return _CategoryChip(
                        label: label,
                        selected: selected,
                        onTap: () => setState(() => _selectedCategory = label),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.white70, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              cursorColor: Colors.white,
              style: AppTypography.inter(fontSize: 14, color: Colors.white),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'Search rituals...',
                hintStyle: AppTypography.inter(
                  fontSize: 14,
                  color: Colors.white70,
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
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

                  // ❤️ Heart icon
                  Positioned(
                    bottom: -2,
                    right: -10,
                    child: GestureDetector(
                      onTap: () {
                        // TODO: toggle favorite
                      },
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite_border_rounded,
                          size: 16,
                        ),
                      ),
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

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            if (selected)
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Text(
          label,
          style: AppTypography.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? const Color(0xFF4A1C00) : const Color(0xFF7A7A7A),
          ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.18),
      shape: const CircleBorder(side: BorderSide(color: Color(0x66FFFFFF))),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            Icons.verified_user_outlined,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}
