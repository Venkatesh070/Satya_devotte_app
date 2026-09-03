import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/features/cms/data/datasources/pooja_remote_datasource.dart';
import 'package:satya_devotte_app/features/cms/data/datasources/ritual_remote_datasource.dart';
import 'package:satya_devotte_app/core/services/offline_service.dart';
import 'package:satya_devotte_app/features/profile/presentation/controllers/pooja_history_controller.dart';
import 'package:satya_devotte_app/features/profile/presentation/controllers/ritual_history_controller.dart';
import 'package:satya_devotte_app/features/pujas/presentation/pages/user_ritual_detail_page.dart';
import 'package:satya_devotte_app/features/pujas/presentation/widgets/puja_shared_widgets.dart';
import 'package:satya_devotte_app/shared/widgets/rich_text_display.dart';
import 'package:satya_devotte_app/shared/widgets/shimmer_skeleton.dart';

enum UserCatalogKind { pujas, rituals }

class UserPujasTabPage extends StatelessWidget {
  const UserPujasTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const UserCatalogTabPage(kind: UserCatalogKind.pujas);
  }
}

class UserRitualsTabPage extends StatelessWidget {
  const UserRitualsTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const UserCatalogTabPage(kind: UserCatalogKind.rituals);
  }
}

class UserCatalogTabPage extends StatefulWidget {
  const UserCatalogTabPage({super.key, required this.kind});

  final UserCatalogKind kind;

  @override
  State<UserCatalogTabPage> createState() => _UserCatalogTabPageState();
}

class _CatalogRow {
  const _CatalogRow({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.meta,
    this.category = '',
    this.totalDays = 0,
    this.imageUrl,
    this.rawPooja,
    this.rawRitual,
  });

  final String id;
  final String title;
  final String subtitle;
  final String meta;
  final String category;
  final int totalDays;
  final String? imageUrl;
  final Map<String, dynamic>? rawPooja;
  final Map<String, dynamic>? rawRitual;

  String? get statusLabel {
    if (rawRitual != null) {
      return statusForRitual(rawRitual!);
    }
    final map =
        rawPooja ?? <String, dynamic>{'_id': id, 'id': id, 'title': title};
    return statusForPooja(map);
  }
}

class _UserCatalogTabPageState extends State<UserCatalogTabPage> {
  static const _pageSize = 10;

  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _searchDebounce;
  Worker? _onlineWorker;

  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  String _searchQuery = '';
  int _page = 1;
  int _totalPages = 1;
  final List<_CatalogRow> _items = [];

  bool get _isPujas => widget.kind == UserCatalogKind.pujas;
  String get _title => _isPujas ? 'Pujas' : 'Rituals';
  String get _searchHint => _isPujas ? 'Search pujas...' : 'Search rituals...';
  String get _emptyLabel =>
      _isPujas ? 'No approved pujas found.' : 'No approved rituals found.';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load(reset: true);
    if (!_isPujas && Get.isRegistered<RitualHistoryController>()) {
      Get.find<RitualHistoryController>().fetchHistory();
    }

    if (Get.isRegistered<OfflineService>()) {
      _onlineWorker = ever(Get.find<OfflineService>().isOnline, (isOnline) {
        if (isOnline == true && mounted) {
          _load(reset: true);
        }
      });
    }
  }

  @override
  void dispose() {
    _onlineWorker?.dispose();
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoadingMore || _isLoading) return;
    if (_page >= _totalPages) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 240) {
      _load();
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      final next = value.trim();
      if (next == _searchQuery) return;
      setState(() => _searchQuery = next);
      _load(reset: true);
    });
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      _page = 1;
      _totalPages = 1;
    } else if (_page >= _totalPages) {
      return;
    }

    if (_isLoading || _isLoadingMore) return;
    setState(() {
      if (reset) {
        _isLoading = true;
        _error = null;
      } else {
        _isLoadingMore = true;
      }
    });

    // Skip global Chakra overlay loader during pagination or pull-to-refresh (when items exist)
    final skipLoader = !reset || _items.isNotEmpty;

    try {
      final page = reset ? 1 : _page + 1;
      final rows = <_CatalogRow>[];
      var totalPages = 1;

      if (_isPujas) {
        final result = await Get.find<PoojaRemoteDataSource>()
            .getApprovedPoojasPage(
              page: page,
              limit: _pageSize,
              search: _searchQuery.isEmpty ? null : _searchQuery,
              skipLoader: skipLoader,
            );
        totalPages = result.totalPages < 1 ? 1 : result.totalPages;
        for (final item in result.items) {
          if (item.id.trim().isEmpty) continue;
          rows.add(
            _CatalogRow(
              id: item.id,
              title: item.title.trim().isEmpty ? 'Puja' : item.title.trim(),
              subtitle: item.description.trim(),
              meta: [
                if (item.category.trim().isNotEmpty) item.category.trim(),
                if (item.duration.trim().isNotEmpty) item.duration.trim(),
              ].join(' · '),
              imageUrl: item.imageUrl,
              rawPooja: item.toJson(),
            ),
          );
        }
      } else {
        final result = await Get.find<RitualRemoteDataSource>()
            .getApprovedRitualsPage(
              page: page,
              limit: _pageSize,
              search: _searchQuery.isEmpty ? null : _searchQuery,
              skipLoader: skipLoader,
            );
        totalPages = result.totalPages < 1 ? 1 : result.totalPages;
        for (final item in result.items) {
          if (item.id.trim().isEmpty) continue;
          final days = item.ritualDay ?? item.days.length;
          final cat = (item.category ?? '').trim();
          final metaParts = <String>[];
          if (cat.isNotEmpty) {
            metaParts.add(cat);
          }
          if (days > 0) {
            metaParts.add('$days day${days == 1 ? '' : 's'}');
          } else if ((item.recommendedDuration ?? '').trim().isNotEmpty) {
            metaParts.add(item.recommendedDuration!.trim());
          }
          rows.add(
            _CatalogRow(
              id: item.id,
              title: item.title.trim().isEmpty ? 'Ritual' : item.title.trim(),
              subtitle: (item.description ?? item.purpose ?? '').trim(),
              meta: metaParts.join(' · '),
              category: cat,
              totalDays: days,
              imageUrl: item.imageUrl,
              rawRitual: {'_id': item.id, 'id': item.id, 'title': item.title},
            ),
          );
        }
      }

      if (!mounted) return;
      setState(() {
        _page = page;
        _totalPages = totalPages;
        if (reset) {
          _items
            ..clear()
            ..addAll(rows);
        } else {
          _items.addAll(rows);
        }
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = reset && _items.isEmpty
            ? 'Failed to load ${_title.toLowerCase()}.'
            : _error;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _openItem(_CatalogRow item) async {
    if (_isPujas) {
      await openPujaPreview(context, id: item.id, initialData: item.rawPooja);
      return;
    }
    await Get.to<void>(() => UserRitualDetailPage(ritualId: item.id));
    if (Get.isRegistered<RitualHistoryController>()) {
      Get.find<RitualHistoryController>().fetchHistory(skipLoader: true);
    }
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
          onRefresh: () => _load(reset: true),
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              if (_isLoading && _items.isEmpty)
                const SliverCatalogListSkeleton()
              else if (_error != null && _items.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildErrorState(),
                )
              else if (_items.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      _emptyLabel,
                      style: AppTypography.inter(
                        fontSize: 14,
                        color: const Color(0xFF7A5A3D),
                      ),
                    ),
                  ),
                )
              else
                _buildList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final topInset = MediaQuery.paddingOf(context).top;
    return SizedBox(
      height: topInset + 168,
      child: Stack(
        children: [
          Positioned.fill(
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: MediaQuery.sizeOf(context).width,
                height: topInset + 180,
                child: Image.asset(
                  'assets/images/pooja/pujaHeaderImg.png',
                  fit: BoxFit.fill,
                  color: const Color(0xFFCC5307),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, topInset + 16, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title,
                  style: AppTypography.lora(
                    fontSize: 28,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFFFCF7EF),
                  ),
                ),
                const SizedBox(height: 16),
                _buildSearchField(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    final hasQuery = _searchController.text.isNotEmpty;
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFFCF7EF).withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFFCF7EF).withValues(alpha: 0.3),
          width: 1.2,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFCF7EF).withValues(alpha: 0.18),
            ),
            child: const Icon(
              Icons.search_rounded,
              color: Color(0xFFFCF7EF),
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              cursorColor: const Color(0xFFFCF7EF),
              style: AppTypography.inter(
                fontSize: 14,
                color: const Color(0xFFFCF7EF),
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                hintText: _searchHint,
                hintStyle: AppTypography.inter(
                  fontSize: 14,
                  color: const Color(0xFFFCF7EF).withValues(alpha: 0.65),
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          if (hasQuery)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                _onSearchChanged('');
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFCF7EF).withValues(alpha: 0.2),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: Color(0xFFFCF7EF),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 110),
      sliver: SliverList.separated(
        itemCount: _items.length + 1,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, thickness: 1, color: Color(0x14000000)),
        itemBuilder: (context, index) {
          if (index == _items.length) {
            if (_isLoadingMore) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.gradientEnd,
                    ),
                  ),
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 24),
              child: Center(
                child: Text(
                  _page >= _totalPages
                      ? 'You have reached the end of the list.'
                      : '',
                  style: AppTypography.inter(
                    fontSize: 12,
                    color: const Color(0xFF8A6B4A),
                  ),
                ),
              ),
            );
          }
          final item = _items[index];
          return _CatalogCard(item: item, onTap: () => _openItem(item));
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
            onPressed: () => _load(reset: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gradientEnd,
              foregroundColor: const Color(0xFFFCF7EF),
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

class _CatalogCard extends StatelessWidget {
  const _CatalogCard({required this.item, required this.onTap});

  final _CatalogRow item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl = item.imageUrl?.trim() ?? '';
    final hasImage = imageUrl.isNotEmpty;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFFFAECD2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFAECD2), width: 3),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: hasImage
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _fallback(),
                        placeholder: (_, __) => _fallback(),
                      )
                    : _fallback(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.lora(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF4A1C00),
                          ),
                        ),
                      ),
                      if (item.rawPooja != null) ...[
                        const SizedBox(width: 8),
                        EyeKnowMoreButton(
                          onTap: () {
                            openKnowMoreForPuja(
                              context,
                              id: item.id,
                              initialData: item.rawPooja,
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                  if (item.rawRitual != null &&
                      Get.isRegistered<RitualHistoryController>())
                    Obx(() {
                      final history = Get.find<RitualHistoryController>();
                      history.pendingRituals.length;
                      history.finishedRituals.length;

                      final pending = history.findPendingSession(item.id);
                      final finished = history.findFinishedSession(item.id);
                      final totalDays = item.totalDays > 0 ? item.totalDays : 1;

                      int completedCount = 0;
                      if (finished != null) {
                        completedCount =
                            (finished['completedDays'] as List?)?.length ??
                            totalDays;
                        if (completedCount == 0) completedCount = totalDays;
                      } else if (pending != null) {
                        completedCount =
                            (pending['completedDays'] as List?)?.length ?? 0;
                      }

                      final daysText =
                          '$totalDays day${totalDays == 1 ? '' : 's'}';
                      final cat = item.category.trim();
                      final metaText = cat.isNotEmpty
                          ? '$cat · $daysText'
                          : daysText;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (finished != null)
                            const Padding(
                              padding: EdgeInsets.only(top: 6),
                              child: PujaSessionStatusBadge(label: 'Finished'),
                            )
                          else if (pending != null)
                            const Padding(
                              padding: EdgeInsets.only(top: 6),
                              child: PujaSessionStatusBadge(
                                label: 'In Progress',
                              ),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            metaText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFE35600),
                            ),
                          ),
                        ],
                      );
                    })
                  else ...[
                    if (Get.isRegistered<PoojaHistoryController>())
                      Obx(() {
                        Get.find<PoojaHistoryController>().pendingPoojas.length;
                        Get.find<PoojaHistoryController>()
                            .finishedPoojas
                            .length;
                        final statusLabel = item.statusLabel;
                        if (statusLabel == null) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: PujaSessionStatusBadge(label: statusLabel),
                        );
                      }),
                    if (item.meta.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFE35600),
                        ),
                      ),
                    ],
                    if (item.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      RichTextDisplay(
                        item.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.inter(
                          fontSize: 13,
                          color: const Color(0xFF6C5B46),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallback() {
    return Image.asset('assets/images/default_img.png', fit: BoxFit.cover);
  }
}
