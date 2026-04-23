import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';
import 'package:satya_devotte_app/core/network/api_client.dart';
import 'package:satya_devotte_app/core/network/api_endpoints.dart';
import 'package:satya_devotte_app/shared/widgets/custom_button.dart';

class RitualListPage extends StatefulWidget {
  const RitualListPage({super.key});

  @override
  State<RitualListPage> createState() => _RitualListPageState();
}

class _RitualListPageState extends State<RitualListPage> {
  bool _isLoading = false;
  String? _error;
  List<_PoojaListItem> _items = const [];

  @override
  void initState() {
    super.initState();
    _loadPoojas();
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
          .map(
            (e) => _PoojaListItem(
              title: e['title']?.toString() ?? 'Untitled Pooja',
              description: e['description']?.toString() ?? '',
              duration: e['duration']?.toString() ?? '-',
              deity: e['deity']?.toString() ?? '-',
              imageUrl: (e['imageUrl']?.toString().trim().isNotEmpty ?? false)
                  ? e['imageUrl']?.toString().trim()
                  : null,
            ),
          )
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Poojas'),
        actions: [
          IconButton(
            onPressed: _loadPoojas,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _loadPoojas,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPoojas,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                height: 150,
                                width: double.infinity,
                                child:
                                    (item.imageUrl != null &&
                                            item.imageUrl!.isNotEmpty)
                                        ? Image.network(
                                            item.imageUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                const ColoredBox(
                                              color: Color(0xFFEDE6D7),
                                            ),
                                          )
                                        : const ColoredBox(
                                            color: Color(0xFFEDE6D7),
                                          ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2E2E2E),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item.description,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF555555),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Duration: ${item.duration}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF333333),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Deity: ${item.deity}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF333333),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: CustomButton(
                                label: 'Participate',
                                borderRadius: 10,
                                onTap: () {},
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
                    },
                  ),
                ),
    );
  }
}

class _PoojaListItem {
  const _PoojaListItem({
    required this.title,
    required this.description,
    required this.duration,
    required this.deity,
    required this.imageUrl,
  });

  final String title;
  final String description;
  final String duration;
  final String deity;
  final String? imageUrl;
}
