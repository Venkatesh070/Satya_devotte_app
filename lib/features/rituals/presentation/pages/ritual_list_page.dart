import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/core/network/api_client.dart';
import 'package:satya_devotte_app/core/network/api_endpoints.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RitualListPage extends StatefulWidget {
  const RitualListPage({super.key});

  @override
  State<RitualListPage> createState() => _RitualListPageState();
}

class _RitualListPageState extends State<RitualListPage> {
  static const _favoritesPrefsKey = 'favorite_pooja_ids';

  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = false;
  String? _error;
  List<PoojaListItem> _items = const [];
  String _searchQuery = '';
  String _selectedCategory = 'All Poojas';
  Set<String> _favoriteIds = <String>{};

  @override
  void initState() {
    super.initState();
    _loadFavorites();
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

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _favoriteIds =
          (prefs.getStringList(_favoritesPrefsKey) ?? const <String>[]).toSet();
    });
  }

  Future<void> _toggleFavorite(PoojaListItem item) async {
    final next = {..._favoriteIds};
    final added = next.add(item.id);
    if (!added) next.remove(item.id);

    setState(() => _favoriteIds = next);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favoritesPrefsKey, next.toList());

    if (!mounted) return;
    Get.snackbar(
      added ? 'Added to favorites' : 'Removed from favorites',
      item.title,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      duration: const Duration(milliseconds: 1200),
    );
  }

  void _openFavorites() {
    final favoriteItems = _items
        .where((item) => _favoriteIds.contains(item.id))
        .toList();
    Get.to(
      () => _FavoritePoojasPage(
        items: favoriteItems,
        favoriteIds: _favoriteIds,
        onToggleFavorite: _toggleFavorite,
      ),
    );
  }

  List<PoojaListItem> get _filteredItems {
    final q = _searchQuery.trim().toLowerCase();
    return _items.where((item) {
      final selectedCategory = _selectedCategory.trim().toLowerCase();
      if (selectedCategory != 'all poojas') {
        final itemTitle = item.title.toLowerCase();
        final itemDeity = item.deity.toLowerCase();
        final itemCategory = item.category.toLowerCase();
        if (!itemTitle.contains(selectedCategory) &&
            !itemDeity.contains(selectedCategory) &&
            !itemCategory.contains(selectedCategory)) {
          return false;
        }
      }

      if (q.isNotEmpty) {
        final textMatch =
            item.title.toLowerCase().contains(q) ||
            item.deity.toLowerCase().contains(q) ||
            item.description.toLowerCase().contains(q);
        if (!textMatch) return false;
      }

      return true;
    }).toList();
  }

  List<String> get _categoryTabs {
    final tabs = <String>['All Poojas'];
    final seen = <String>{};
    for (final item in _items) {
      final label = item.deity.trim().isNotEmpty
          ? "${item.deity.trim()} Pooja's"
          : item.title.trim();
      if (label.isEmpty) continue;
      if (seen.add(label.toLowerCase())) tabs.add(label);
      if (tabs.length >= 8) break;
    }
    return tabs;
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
                  minExtentHeight: MediaQuery.paddingOf(context).top + 280,
                  maxExtentHeight: MediaQuery.paddingOf(context).top + 280,
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
      height: topInset + 362,
      child: Stack(
        children: [
          Positioned.fill(
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: MediaQuery.sizeOf(context).width,
                height: 372,
                child: Image.asset(
                  'assets/images/pooja/pujaHeaderImg.png',
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, topInset + 16, 20, 8),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Puja Rituals',
                        style: AppTypography.lora(
                          fontSize: 28,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    _HeaderFavoriteButton(
                      count: _favoriteIds.length,
                      onTap: _openFavorites,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildSearchField(),
                const SizedBox(height: 12),
                SizedBox(
                  height: 92,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categoryTabs.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final tab = _categoryTabs[index];
                      final isSelected = tab == _selectedCategory;
                      return _CategoryTabChip(
                        label: tab,
                        selected: isSelected,
                        onTap: () => setState(() => _selectedCategory = tab),
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
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0x22FFFFFF),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              cursorColor: Colors.black,
              style: AppTypography.inter(
                fontSize: 14,
                color: const Color(0xFF232323),
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'Search rituals...',
                hintStyle: AppTypography.inter(
                  fontSize: 14,
                  color: const Color(0xFFFAD9C0),
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
      padding: EdgeInsets.fromLTRB(18, 0, 18, listBottomPadding),
      sliver: SliverList.separated(
        itemCount: items.length + 1,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, thickness: 1, color: Color(0x14000000)),
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
            isFavorite: _favoriteIds.contains(item.id),
            onFavoriteTap: () => _toggleFavorite(item),
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
    String? resolveImageUrl() {
      final media = e['media'];
      if (media is Map) {
        final images = media['images'];
        if (images is List && images.isNotEmpty) {
          final first = images.first?.toString().trim() ?? '';
          if (first.isNotEmpty) return first;
        }
      }

      final direct = (e['imageUrl'] ?? e['image'])?.toString().trim() ?? '';
      return direct.isNotEmpty ? direct : null;
    }

    String resolveDeity() {
      final raw = e['deity'];
      if (raw is Map) {
        return (raw['name'] ?? raw['title'] ?? '').toString();
      }
      final value = raw?.toString() ?? '';
      final isObjectId =
          value.length == 24 && RegExp(r'^[0-9a-fA-F]+$').hasMatch(value);
      return isObjectId ? '' : value;
    }

    return PoojaListItem(
      id: (e['_id'] ?? e['id'] ?? '').toString(),
      title: e['title']?.toString() ?? 'Untitled Pooja',
      deity: resolveDeity(),
      category: e['category']?.toString() ?? '',
      description: e['description']?.toString() ?? '',
      duration: e['duration']?.toString() ?? '',
      imageUrl: resolveImageUrl(),
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
  const _PoojaCard({
    required this.item,
    required this.onTap,
    required this.isFavorite,
    required this.onFavoriteTap,
  });

  final PoojaListItem item;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    final hasImage = item.imageUrl != null && item.imageUrl!.trim().isNotEmpty;
    debugPrint('hasAImge-->,${hasImage}');
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAECD2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFD8CBB6),
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: hasImage
                              ? Image.network(
                                  item.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _imageFallback(),
                                )
                              : _imageFallback(),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -8,
                    bottom: -6,
                    child: _FavoriteBadge(
                      isFavorite: isFavorite,
                      onTap: onFavoriteTap,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.lora(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF3B1E08),
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  if (item.deity.isNotEmpty)
                    Text(
                      item.deity,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF8C775F),
                      ),
                    ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: Color(0xFF3B1E08),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        item.durationLabel,
                        style: AppTypography.inter(
                          fontSize: 12.5,
                          color: const Color(0xFF3B1E08),
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

class _FavoriteBadge extends StatelessWidget {
  const _FavoriteBadge({required this.isFavorite, required this.onTap});
  final bool isFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFEAD9BC), width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          size: 19,
          color: isFavorite ? const Color(0xFFE25B4B) : const Color(0xFFCF9B3A),
        ),
      ),
    );
  }
}

class _FavoritePoojasPage extends StatefulWidget {
  const _FavoritePoojasPage({
    required this.items,
    required this.favoriteIds,
    required this.onToggleFavorite,
  });

  final List<PoojaListItem> items;
  final Set<String> favoriteIds;
  final Future<void> Function(PoojaListItem item) onToggleFavorite;

  @override
  State<_FavoritePoojasPage> createState() => _FavoritePoojasPageState();
}

class _FavoritePoojasPageState extends State<_FavoritePoojasPage> {
  late List<PoojaListItem> _items;
  late Set<String> _favoriteIds;

  @override
  void initState() {
    super.initState();
    _items = [...widget.items];
    _favoriteIds = {...widget.favoriteIds};
  }

  Future<void> _toggleFavorite(PoojaListItem item) async {
    await widget.onToggleFavorite(item);
    if (!mounted) return;
    setState(() {
      if (_favoriteIds.contains(item.id)) {
        _favoriteIds.remove(item.id);
        _items.removeWhere((e) => e.id == item.id);
      } else {
        _favoriteIds.add(item.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBgColor,
      appBar: AppBar(
        backgroundColor: AppColors.appBgColor,
        elevation: 0,
        foregroundColor: const Color(0xFF3B1E08),
        title: Text(
          'Favorites',
          style: AppTypography.lora(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF3B1E08),
          ),
        ),
      ),
      body: _items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.favorite_border,
                      size: 46,
                      color: Color(0xFFB07A3A),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No favorite poojas yet.',
                      textAlign: TextAlign.center,
                      style: AppTypography.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF7A5A3D),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: EdgeInsets.fromLTRB(
                16,
                10,
                16,
                MediaQuery.paddingOf(context).bottom + 24,
              ),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                thickness: 1,
                color: Color(0x14000000),
              ),
              itemBuilder: (context, index) {
                final item = _items[index];
                return _PoojaCard(
                  item: item,
                  isFavorite: _favoriteIds.contains(item.id),
                  onFavoriteTap: () => _toggleFavorite(item),
                  onTap: () => Get.toNamed<dynamic>(
                    AppRoutes.ritualDetail,
                    arguments: item.id,
                  ),
                );
              },
            ),
    );
  }
}

class _HeaderFavoriteButton extends StatelessWidget {
  const _HeaderFavoriteButton({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x26000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.favorite_border,
              size: 23,
              color: Color(0xFFCF6F2B),
            ),
          ),
          if (count > 0)
            Positioned(
              top: -3,
              right: -3,
              child: Container(
                constraints: const BoxConstraints(minWidth: 18),
                height: 18,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: const BoxDecoration(
                  color: Color(0xFFE25B4B),
                  borderRadius: BorderRadius.all(Radius.circular(9)),
                ),
                alignment: Alignment.center,
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: AppTypography.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
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

class _CategoryTabChip extends StatelessWidget {
  const _CategoryTabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const chipRadius = BorderRadius.only(
      topLeft: Radius.circular(16),
      topRight: Radius.circular(16),
      bottomLeft: Radius.circular(0),
      bottomRight: Radius.circular(0),
    );

    final chipBody = Container(
      width: 98,
      height: 88,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: chipRadius,
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x40FFFFFF),
            Color(0x24FFB677),
            Color(0x18B64A00),
          ],
          stops: [0.0, 0.52, 1.0],
        ),
      ),
      child: Center(
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.inter(
            fontSize: 32 / 3,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1.15,
          ),
        ),
      ),
    );

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 98,
        height: 88,
        child: Stack(
          children: [
            Positioned.fill(child: chipBody),
            if (selected)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _TopRightChipBorderPainter(
                      radius: 16,
                      strokeWidth: 1.2,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TopRightChipBorderPainter extends CustomPainter {
  const _TopRightChipBorderPainter({
    required this.radius,
    required this.strokeWidth,
  });

  final double radius;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final topY = strokeWidth / 2;
    final rightX = size.width - strokeWidth / 2;

    // Top border fades from left -> bright near top-right.
    final topPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: const [
          Color(0x00FFEF11),
          Color(0x55FFEF11),
          Color(0xFFFFEF11),
        ],
        stops: const [0.0, 0.72, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, strokeWidth));

    final topPath = Path()
      ..moveTo(radius, topY)
      ..lineTo(size.width - radius, topY)
      ..arcToPoint(
        Offset(rightX, radius),
        radius: Radius.circular(radius),
        clockwise: true,
      );
    canvas.drawPath(topPath, topPaint);

    // Right border is brightest near top-right and fades downward.
    final rightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [
          Color(0xFFFFEF11),
          Color(0x66FFEF11),
          Color(0x00FFEF11),
        ],
        stops: const [0.0, 0.35, 1.0],
      ).createShader(Rect.fromLTWH(size.width - strokeWidth, 0, strokeWidth, size.height));

    canvas.drawLine(
      Offset(rightX, radius),
      Offset(rightX, size.height - 2),
      rightPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TopRightChipBorderPainter oldDelegate) {
    return oldDelegate.radius != radius ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

