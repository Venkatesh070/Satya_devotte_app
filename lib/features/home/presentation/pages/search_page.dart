import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/core/network/api_client.dart';
import 'package:satya_devotte_app/core/network/api_endpoints.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/core/models/festival_model.dart';
import 'package:satya_devotte_app/features/calendar/presentation/controllers/calendar_controller.dart';
import 'package:satya_devotte_app/features/calendar/presentation/pages/calendar_event_detail_page.dart';
import 'package:satya_devotte_app/features/donations/data/models/donation.dart';
import 'package:satya_devotte_app/shared/pages/chakra_loader_page.dart';
import 'package:satya_devotte_app/shared/widgets/app_background.dart';
import 'package:satya_devotte_app/shared/widgets/rich_text_display.dart';

class GlobalSearchResult {
  const GlobalSearchResult({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.raw,
  });

  factory GlobalSearchResult.fromJson(Map<String, dynamic> json) {
    String _extractString(dynamic v) {
      if (v == null) return '';
      if (v is String) return v.trim();
      if (v is List) {
        return v
            .map((e) => _extractString(e))
            .where((s) => s.isNotEmpty)
            .join(', ');
      }
      if (v is Map) {
        final name = v['name'] ?? v['title'] ?? '';
        return _extractString(name);
      }
      return v.toString().trim();
    }

    String valueOf(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        final text = _extractString(value);
        if (text.isNotEmpty) return text;
      }
      return '';
    }

    return GlobalSearchResult(
      id: valueOf(['id', '_id']),
      type: valueOf(['type']).toLowerCase(),
      title: valueOf(['title', 'name']),
      description: valueOf(['description', 'about']),
      imageUrl: valueOf(['imageUrl', 'image']).isEmpty
          ? null
          : valueOf(['imageUrl', 'image']),
      raw: Map<String, dynamic>.from(json),
    );
  }

  final String id;
  final String type;
  final String title;
  final String description;
  final String? imageUrl;
  final Map<String, dynamic> raw;

  String get typeLabel {
    if (type.isEmpty) return 'result';
    if (type == 'pooja') return 'Puja';
    return type[0].toUpperCase() + type.substring(1);
  }

  IconData get icon {
    switch (type) {
      case 'donation':
        return Icons.volunteer_activism_outlined;
      case 'festival':
        return Icons.event_available_outlined;
      case 'ritual':
        return Icons.local_fire_department_outlined;
      case 'deity':
        return Icons.temple_hindu_outlined;
      case 'pooja':
      default:
        return Icons.spa_outlined;
    }
  }

  Map<String, dynamic> toDetailArgs() => {
    ...raw,
    '_id': id,
    'id': id,
    'title': title,
    'description': description,
    if (imageUrl != null) 'imageUrl': imageUrl,
  };

  Map<String, dynamic> toDeityArgs() => {
    'type': 'deity',
    ...toDetailArgs(),
    'name': title,
    if (imageUrl != null)
      'media': {
        'images': [imageUrl],
      },
  };
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  bool _isSearching = false;
  String? _searchError;
  List<GlobalSearchResult> _searchResults = const [];

  @override
  void initState() {
    super.initState();
    _searchFocus.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    final q = value.trim();
    if (q.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchError = null;
        _searchResults = const [];
      });
    } else {
      setState(() {});
    }
  }

  Future<void> _search(String q) async {
    setState(() {
      _isSearching = true;
      _searchError = null;
      _searchResults = const [];
    });
    try {
      final response = await Get.find<ApiClient>().dio.get<dynamic>(
        ApiEndpoints.search,
        queryParameters: {'q': q, 'limit': 8, 'maxTotal': 20},
      );
      if (!mounted || _searchController.text.trim() != q) return;
      setState(() {
        _searchResults = _extractResults(response.data);
      });
    } on DioException catch (error) {
      if (!mounted || _searchController.text.trim() != q) return;
      setState(() {
        _searchResults = const [];
        _searchError = _messageForSearchError(error);
      });
    } catch (_) {
      if (!mounted || _searchController.text.trim() != q) return;
      setState(() {
        _searchResults = const [];
        _searchError = 'Search failed.';
      });
    } finally {
      if (mounted && _searchController.text.trim() == q) {
        setState(() => _isSearching = false);
      }
    }
  }

  List<GlobalSearchResult> _extractResults(dynamic payload) {
    dynamic data = payload;
    if (payload is Map) {
      data = payload['data'] ?? payload;
      if (data is Map) {
        data =
            data['results'] ??
            data['items'] ??
            data['docs'] ??
            data['data'] ??
            data;
      }
    }
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((raw) => GlobalSearchResult.fromJson(raw.cast<String, dynamic>()))
        .where((result) => result.title.isNotEmpty)
        .toList(growable: false);
  }

  String _messageForSearchError(DioException error) {
    final code = error.response?.statusCode;
    if (code == 404) {
      return 'Search is not available. Check that the app uses the latest API.';
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError) {
      return 'No connection. Check your network and try again.';
    }
    final data = error.response?.data;
    if (data is Map) {
      final msg = data['message'] ?? data['error'];
      if (msg != null && msg.toString().trim().isNotEmpty) {
        return msg.toString();
      }
    }
    return 'Search failed. Please try again.';
  }

  void _clearSearch() {
    _searchController.clear();
    _searchFocus.requestFocus();
    setState(() {
      _isSearching = false;
      _searchError = null;
      _searchResults = const [];
    });
  }

  Future<void> _openSearchResult(GlobalSearchResult result) async {
    FocusScope.of(context).unfocus();
    switch (result.type) {
      case 'pooja':
        if (result.id.isEmpty) return;
        await Get.toNamed<dynamic>(
          AppRoutes.ritualDetail,
          arguments: result.toDetailArgs(),
        );
        return;
      case 'deity':
        if (result.id.isEmpty) return;
        await Get.toNamed<dynamic>(
          AppRoutes.ritualDetail,
          arguments: result.toDeityArgs(),
        );
        return;
      case 'donation':
        if (result.id.isEmpty) return;
        await Get.toNamed<dynamic>(
          AppRoutes.userDonationDetails,
          arguments: Donation(
            id: result.id,
            title: result.title,
            description: result.description,
            imageUrl: result.imageUrl,
          ),
        );
        return;
      case 'festival':
        final controller = Get.isRegistered<CalendarController>()
            ? Get.find<CalendarController>()
            : Get.put(CalendarController());

        if (controller.festivals.isEmpty && !controller.isLoading.value) {
          await controller.fetchData();
        }

        final match = controller.festivals.firstWhereOrNull(
          (f) =>
              (f.id.isNotEmpty && f.id == result.id) ||
              (f.title.toLowerCase().trim() ==
                  result.title.toLowerCase().trim()),
        );

        FestivalModel festival;
        if (match != null) {
          festival = match;
        } else {
          var dateStr = result.raw['date']?.toString() ??
              result.raw['startDate']?.toString() ??
              result.raw['festivalDate']?.toString() ??
              result.raw['scheduledDate']?.toString() ??
              '';
          if (dateStr.isEmpty) {
            final now = DateTime.now();
            dateStr =
                '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
          }
          final fullDesc = (result.raw['description'] ??
                  result.raw['about'] ??
                  result.raw['summary'] ??
                  result.description)
              ?.toString()
              .trim() ??
              '';
          festival = FestivalModel(
            id: result.id.isNotEmpty ? result.id : result.title,
            title: result.title,
            description: fullDesc.isNotEmpty ? fullDesc : result.description,
            date: dateStr,
            status: 'Approved',
            imageUrl: result.imageUrl ??
                result.raw['imageUrl']?.toString() ??
                result.raw['image']?.toString(),
          );
        }

        if (mounted) {
          await CalendarEventDetailPage.show(context, event: festival);
        }
        return;
      default:
        Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      showPattern: true,
      rotateFooter: true,
      animatePatterns: true,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              _SearchHeader(
                controller: _searchController,
                focusNode: _searchFocus,
                onChanged: _onSearchChanged,
                onSubmitted: (value) {
                  final q = value.trim();
                  if (q.length >= 2) _search(q);
                },
                onClear: _clearSearch,
                onBack: () => Get.back(),
              ),
              Expanded(
                child: _SearchResultsSection(
                  isSearching: _isSearching,
                  error: _searchError,
                  results: _searchResults,
                  onResultTap: _openSearchResult,
                  hasQuery: _searchController.text.trim().length >= 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchHeader extends StatelessWidget {
  const _SearchHeader({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
    required this.onBack,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final hasQuery = controller.text.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            color: const Color(0xFFFCF7EF),
            iconSize: 24,
          ),
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Color(0xFFFCF7EF),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE5D5C5), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF183EA4), Color(0xFFE35600)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
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
                      controller: controller,
                      focusNode: focusNode,
                      onChanged: onChanged,
                      onSubmitted: onSubmitted,
                      textInputAction: TextInputAction.search,
                      cursorColor: const Color(0xFFE35600),
                      style: AppTypography.inter(
                        fontSize: 14,
                        color: const Color(0xFF4A1C00),
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        isCollapsed: true,
                        hintText: 'Search pujas, deities, festivals...',
                        hintStyle: AppTypography.inter(
                          fontSize: 13,
                          color: const Color(0xFF9B8B7B),
                          fontWeight: FontWeight.w400,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                      ),
                    ),
                  ),
                  if (hasQuery)
                    GestureDetector(
                      onTap: onClear,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey.withValues(alpha: 0.15),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: Color(0xFF4A1C00),
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchResultsSection extends StatelessWidget {
  const _SearchResultsSection({
    required this.isSearching,
    required this.error,
    required this.results,
    required this.onResultTap,
    required this.hasQuery,
  });

  final bool isSearching;
  final String? error;
  final List<GlobalSearchResult> results;
  final Future<void> Function(GlobalSearchResult result) onResultTap;
  final bool hasQuery;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    // 1. Initial State (no query, not searching, no error, no results)
    if (!hasQuery && results.isEmpty && !isSearching && error == null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset + 80),
          child: Text(
            'Search pujas, deities, festivals...',
            style: AppTypography.inter(
              fontSize: 14,
              color: const Color(0xFFFCF7EF).withValues(alpha: 0.7),
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      );
    }

    // 2. Loading State (isSearching is true, and we have no results yet)
    if (isSearching && results.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset + 80),
          child: ChakraLoaderPage(),
        ),
      );
    }

    // 3. Error State
    if (error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset + 80),
          child: _SearchMessage(text: error!),
        ),
      );
    }

    // 4. No Data Found State (has query, not searching, no results)
    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset + 80),
          child: const _SearchMessage(text: 'No data added'),
        ),
      );
    }

    // 5. Search Results State
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomInset + 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Search Results',
              style: AppTypography.lora(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFFFCF7EF),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: results.length,
              separatorBuilder: (context, index) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final result = results[index];
                return _SearchResultTile(
                  result: result,
                  onTap: () => onResultTap(result),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchMessage extends StatelessWidget {
  const _SearchMessage({required this.text, this.height});
  final String text;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final textWidget = Text(
      text,
      textAlign: TextAlign.center,
      style: AppTypography.inter(
        color: const Color(0xFFFCF7EF),
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );

    if (height != null) {
      return SizedBox(
        height: height,
        child: Center(child: textWidget),
      );
    }

    return textWidget;
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({required this.result, required this.onTap});
  final GlobalSearchResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Color(0xFFFCF7EF),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SearchResultImage(result: result),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.lora(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF1C1917),
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(children: [_SearchTypePill(type: result.typeLabel)]),
                    if (result.description.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      RichTextDisplay(
                        result.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.inter(
                          fontSize: 11,
                          color: const Color(0xFF78716C),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchResultImage extends StatelessWidget {
  const _SearchResultImage({required this.result});
  final GlobalSearchResult result;

  @override
  Widget build(BuildContext context) {
    final imageUrl = result.imageUrl?.trim() ?? '';
    final hasImage = imageUrl.isNotEmpty;

    final placeholder = Container(
      color: const Color(0xFFF3E2C3),
      child: Center(
        child: Icon(result.icon, size: 22, color: const Color(0xFF8E5C25)),
      ),
    );

    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: const Color(0xFFFAECD2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFAECD2), width: 3),
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: hasImage
              ? CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => placeholder,
                  placeholder: (_, __) => placeholder,
                )
              : placeholder,
        ),
      ),
    );
  }
}

class _SearchTypePill extends StatelessWidget {
  const _SearchTypePill({required this.type});
  final String type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF4E6CC),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        type,
        style: AppTypography.inter(
          fontSize: 10,
          color: const Color(0xFF8E5C25),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
