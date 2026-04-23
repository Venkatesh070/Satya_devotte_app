import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:satya_devotte_app/core/network/api_client.dart';
import 'package:satya_devotte_app/core/network/api_endpoints.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/shared/widgets/custom_button.dart';

/// Ritual / Pooja detail page — redesigned to match the
/// Figma reference. Loads data from `GET /api/v1/poojas/:id`.
/// Accepts either a pooja id (String) or the full map via
/// `Get.arguments`.
class RitualDetailPage extends StatefulWidget {
  const RitualDetailPage({super.key});

  @override
  State<RitualDetailPage> createState() => _RitualDetailPageState();
}

class _RitualDetailPageState extends State<RitualDetailPage> {
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _pooja;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is Map<String, dynamic>) {
      _pooja = args;
      final id = args['_id']?.toString() ?? args['id']?.toString();
      if (id != null && id.isNotEmpty) {
        _loadDetail(id);
      }
    } else if (args is String && args.isNotEmpty) {
      _loadDetail(args);
    } else {
      _error = 'No pooja selected.';
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
      final data = payload is Map<String, dynamic> ? payload['data'] : null;
      Map<String, dynamic>? pooja;
      if (data is Map<String, dynamic>) {
        final inner = data['pooja'];
        pooja = inner is Map<String, dynamic> ? inner : data;
      } else if (payload is Map<String, dynamic>) {
        pooja = payload;
      }
      if (!mounted) return;
      setState(() => _pooja = pooja ?? _pooja);
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message ?? 'Failed to load pooja.');
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Failed to load pooja.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

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

    final pooja = _pooja!;
    final title = pooja['title']?.toString() ?? 'Pooja';
    final deity = pooja['deity']?.toString() ?? '';
    final description = pooja['description']?.toString() ?? '';
    final duration = _durationLabel(pooja['duration']?.toString());
    final imageUrl = pooja['imageUrl']?.toString();
    final steps =
        (pooja['steps'] as List?)
            ?.map((e) => e.toString())
            .where((e) => e.trim().isNotEmpty)
            .toList() ??
        const <String>[];
    final requiredItems =
        (pooja['requiredItems'] as List?)
            ?.map((e) => e.toString())
            .where((e) => e.trim().isNotEmpty)
            .toList() ??
        const <String>[];

    return Scaffold(
      backgroundColor: AppColors.appBgColor,
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.zero,
            children: [
              _HeroSection(
                title: title,
                deity: deity,
                duration: duration,
                imageUrl: imageUrl,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MantraCard(
                      mantra: _mantraFor(deity),
                      subtitle: 'Sacred Mantra',
                      onPlay: () {},
                    ),
                    const SizedBox(height: 24),
                    if (description.isNotEmpty) ...[
                      Text(
                        description,
                        textAlign: TextAlign.center,
                        style: AppTypography.inter(
                          fontSize: 13.5,
                          height: 1.55,
                          color: const Color(0xFF4A1C00),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const _DiamondDivider(),
                      const SizedBox(height: 20),
                    ],
                    if (steps.isNotEmpty) ...[
                      Text(
                        'Key Rituals and Steps of $title:',
                        style: AppTypography.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF3B1E08),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...steps.map(_buildBullet),
                    ],
                    if (requiredItems.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      Text(
                        'Required Items:',
                        style: AppTypography.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF3B1E08),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...requiredItems.map(_buildBullet),
                    ],
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            child: Material(
              color: Colors.black.withValues(alpha: 0.35),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: Get.back,
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          // Bottom \"Start Ritual\" CTA
          Positioned(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).padding.bottom + 16,
            child: CustomButton(
              label: 'Start Ritual',
              borderRadius: 14,
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
  }

  Widget _buildBullet(String text) {
    // Allow an optional bold lead-in separated by a colon, e.g.
    // \"Preparation: Homes are cleaned and decorated ...\"
    final colonIdx = text.indexOf(':');
    final hasLead = colonIdx > 0 && colonIdx < 40;
    final lead = hasLead ? text.substring(0, colonIdx + 1) : '';
    final rest = hasLead ? text.substring(colonIdx + 1).trimLeft() : text;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
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
            child: RichText(
              text: TextSpan(
                style: AppTypography.inter(
                  fontSize: 13.5,
                  height: 1.55,
                  color: const Color(0xFF4A1C00),
                ),
                children: [
                  if (hasLead)
                    TextSpan(
                      text: '$lead ',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  TextSpan(text: rest),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _durationLabel(String? raw) {
    final v = (raw ?? '').trim();
    if (v.isEmpty) return '-';
    final n = int.tryParse(v);
    return n != null ? '$n min' : v;
  }

  String _mantraFor(String deity) {
    final d = deity.toLowerCase();
    if (d.contains('ganesh')) return 'Om Gam Ganapataye Namah';
    if (d.contains('lakshmi') || d.contains('laxmi')) {
      return 'Om Shreem Mahalakshmiyei Namah';
    }
    if (d.contains('shiva')) return 'Om Namah Shivaya';
    if (d.contains('durga')) return 'Om Dum Durgayei Namah';
    if (d.contains('krishna')) return 'Om Kleem Krishnaya Namah';
    if (d.contains('ram')) return 'Om Shri Ramaya Namah';
    if (d.contains('hanuman')) return 'Om Hum Hanumate Namah';
    if (d.contains('surya')) return 'Om Suryaya Namah';
    return 'Om Namah Bhagavate';
  }
}

// ─────────────────────────────────────────────────────────
// Hero, Mantra card & Divider widgets
// ─────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.title,
    required this.deity,
    required this.duration,
    required this.imageUrl,
  });

  final String title;
  final String deity;
  final String duration;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 360,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl != null && imageUrl!.isNotEmpty)
            Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _fallback(),
            )
          else
            _fallback(),
          // Fade to cream at the bottom for seamless blend.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.transparent,
                  Color(0x66000000),
                  AppColors.appBgColor,
                ],
                stops: [0.0, 0.4, 0.75, 1.0],
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 28,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.play_arrow,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Online Rituals',
                        style: AppTypography.inter(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.lora(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (deity.isNotEmpty)
                      Text(
                        deity,
                        style: AppTypography.inter(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    if (deity.isNotEmpty && duration != '-')
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(
                          Icons.circle,
                          size: 4,
                          color: Colors.white70,
                        ),
                      ),
                    if (duration != '-') ...[
                      const Icon(
                        Icons.access_time,
                        size: 13,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        duration,
                        style: AppTypography.inter(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF6B2A8F), Color(0xFFD14A2A)],
        ),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.temple_hindu, size: 80, color: Colors.white70),
    );
  }
}

class _MantraCard extends StatelessWidget {
  const _MantraCard({
    required this.mantra,
    required this.subtitle,
    required this.onPlay,
  });

  final String mantra;
  final String subtitle;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mantra,
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
                      Icons.music_note,
                      size: 12,
                      color: Color(0xFFB07A3A),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      subtitle,
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
          Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onPlay,
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.gradientStart, AppColors.gradientEnd],
                  ),
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiamondDivider extends StatelessWidget {
  const _DiamondDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0x33B07A3A), thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Transform.rotate(
            angle: 0.785398, // 45 deg
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(color: Color(0xFFB07A3A)),
            ),
          ),
        ),
        const Expanded(child: Divider(color: Color(0x33B07A3A), thickness: 1)),
      ],
    );
  }
}
