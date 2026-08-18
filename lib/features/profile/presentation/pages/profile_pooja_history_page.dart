import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/features/donations/presentation/widgets/donation_ui.dart';
import 'package:satya_devotte_app/features/profile/presentation/controllers/pooja_history_controller.dart';
import 'package:satya_devotte_app/features/pujas/presentation/models/pooja_view_model.dart';
import 'package:satya_devotte_app/features/pujas/presentation/pages/pooja_step_wizard.dart';
import 'package:satya_devotte_app/features/pujas/presentation/widgets/puja_shared_widgets.dart';

class ProfilePoojaHistoryPage extends StatefulWidget {
  const ProfilePoojaHistoryPage({super.key});

  @override
  State<ProfilePoojaHistoryPage> createState() =>
      _ProfilePoojaHistoryPageState();
}

class _ProfilePoojaHistoryPageState extends State<ProfilePoojaHistoryPage> {
  late final PoojaHistoryController c;

  @override
  void initState() {
    super.initState();
    c = Get.find<PoojaHistoryController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      c.fetchHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: DonationUi.background,
        appBar: AppBar(
          title: Text(
            'Puja History',
            style: AppTypography.lora(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: DonationUi.textPrimary,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: DonationUi.textPrimary,
              size: 20,
            ),
            onPressed: () => Get.back(),
          ),
          bottom: TabBar(
            labelColor: DonationUi.textPrimary,
            unselectedLabelColor: DonationUi.textMuted,
            indicatorColor: DonationUi.textPrimary,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: 'Finished'),
              Tab(text: 'In Progress'),
            ],
          ),
        ),
        body: Obx(() {
          if (c.isLoading.value &&
              c.finishedPoojas.isEmpty &&
              c.pendingPoojas.isEmpty) {
            return const SizedBox.shrink();
          }

          if (c.error.value != null &&
              c.finishedPoojas.isEmpty &&
              c.pendingPoojas.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    c.error.value!,
                    style: AppTypography.inter(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: c.fetchHistory,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: c.fetchHistory,
            child: TabBarView(
              children: [
                _HistoryList(
                  items: c.finishedPoojas,
                  emptyMessage: 'No finished pujas yet',
                ),
                _HistoryList(
                  items: c.pendingPoojas,
                  emptyMessage: 'No pujas in progress',
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.items, required this.emptyMessage});
  final List<dynamic> items;
  final String emptyMessage;

  bool _hasData(dynamic data) {
    if (data == null) return false;
    if (data is Iterable) return data.isNotEmpty;
    if (data is Map) return data.isNotEmpty;
    if (data is String) return data.isNotEmpty;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: AppTypography.inter(color: DonationUi.textMuted),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final session = items[i];
        final pooja = session['pooja'] ?? {};
        final title = pooja['title'] ?? 'Puja';

        final rawDate = session['finishedAt'] ?? session['createdAt'];
        String when = '';
        if (rawDate != null) {
          try {
            final date = DateTime.parse(rawDate.toString());
            when = DateFormat('MMMM d, yyyy | h:mm a').format(date.toLocal());
          } catch (_) {}
        }

        final currentStepIndex = _intValue(session['currentStep']);
        final poojaSteps = pooja['steps'] is List ? pooja['steps'] as List : [];
        final totalStepsFromPooja = poojaSteps.length;
        final totalStepsFromSession =
            session['totalSteps'] ?? totalStepsFromPooja;

        // Calculate the offset to find the actual ritual step number
        // Offset = 1 (Intro) + 1 (Before begin) + prepCount + 1 (Let's begin)
        int offset = 3; // Intro, Before begin, Let's begin
        final prep = pooja['preparation'];
        if (prep is Map) {
          if (_hasData(prep['personal'])) offset++;
          if (_hasData(prep['space'])) offset++;
          if (_hasData(prep['items'])) offset++;
        }

        String stepLabel = '';
        if (_isInProgress(session)) {
          if (currentStepIndex < offset) {
            stepLabel = 'Preparation';
          } else {
            final ritualStepIdx = currentStepIndex - offset;
            if (ritualStepIdx < totalStepsFromSession) {
              final stepNum = (ritualStepIdx + 1);
              stepLabel = 'Step $stepNum/$totalStepsFromSession';
            } else {
              stepLabel = 'Completion';
            }
          }
        }

        final isFinished = _isFinished(session);
        final statusText = isFinished ? 'Finished' : 'In Progress';

        // Extract Puja Image URL first (with fallback to Deity image)
        final imageUrl = _extractPujaImage(pooja);
        final description = (pooja['description'] ?? pooja['purpose'] ?? '').toString();

        return Material(
          color: const Color(0xFFFCF7EF),
          borderRadius: BorderRadius.circular(16),
          elevation: 0,
          child: InkWell(
            onTap: () {
              final poojaData = session['pooja'];
              if (poojaData is! Map) return;
              final poojaMap = Map<String, dynamic>.from(poojaData);
              final sessionId = (session['_id'] ?? session['id'])?.toString();
              final poojaId = (poojaMap['_id'] ?? poojaMap['id'] ?? '').toString();

              if (_isInProgress(session)) {
                Get.to(
                  () => PoojaStepWizard(
                    pooja: PoojaView(poojaMap),
                    initialStep: currentStepIndex,
                    sessionId: sessionId,
                  ),
                );
              } else {
                openPujaPreview(context, id: poojaId, initialData: poojaMap);
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: DonationUi.cardBorder),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Puja Image
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAECD2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFFAECD2),
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: imageUrl != null && imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Image.asset(
                                'assets/images/default_img.png',
                                fit: BoxFit.cover,
                              ),
                              placeholder: (_, __) => Image.asset(
                                'assets/images/default_img.png',
                                fit: BoxFit.cover,
                              ),
                            )
                          : Image.asset(
                              'assets/images/default_img.png',
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Text Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1C1917),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            PujaSessionStatusBadge(label: statusText),
                          ],
                        ),
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.inter(
                              fontSize: 12,
                              color: const Color(0xFF78716C),
                              height: 1.35,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 12,
                              color: Color(0xFFA8A29E),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                when,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.inter(
                                  fontSize: 11,
                                  color: const Color(0xFFA8A29E),
                                ),
                              ),
                            ),
                            if (stepLabel.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Text(
                                stepLabel,
                                style: AppTypography.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFE35600),
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
            ),
          ),
        );
      },
    );
  }

  bool _isInProgress(Map session) {
    final status = session['status']?.toString().toUpperCase().trim();
    return status == 'PENDING' ||
        status == 'IN_PROGRESS' ||
        status == 'INPROGRESS' ||
        status == 'STARTED';
  }

  bool _isFinished(Map session) {
    final status = session['status']?.toString().toUpperCase().trim();
    return status == 'FINISHED' || status == 'COMPLETED' || status == 'DONE';
  }

  int _intValue(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String? _extractPujaImage(Map pooja) {
    String extract(dynamic v) {
      if (v == null) return '';
      if (v is String) return v.trim();
      if (v is List && v.isNotEmpty) return extract(v.first);
      if (v is Map) {
        return extract(
          v['url'] ?? v['imageUrl'] ?? v['image'] ?? v['src'] ?? v['path'],
        );
      }
      return v.toString().trim();
    }

    for (final key in [
      'imageUrl',
      'image',
      'heroImage',
      'bannerImage',
      'thumbnailUrl',
      'thumbnail',
      'poojaImage',
      'pooja_image'
    ]) {
      final val = extract(pooja[key]);
      if (val.isNotEmpty && val.startsWith('http')) return val;
    }

    final media = pooja['media'];
    if (media is Map) {
      for (final key in ['images', 'heroImage', 'bannerImage', 'image']) {
        final val = extract(media[key]);
        if (val.isNotEmpty && val.startsWith('http')) return val;
      }
    } else if (media is List && media.isNotEmpty) {
      final val = extract(media.first);
      if (val.isNotEmpty && val.startsWith('http')) return val;
    }

    final deity = pooja['deity'];
    if (deity is Map) {
      for (final key in ['imageUrl', 'image', 'heroImage']) {
        final val = extract(deity[key]);
        if (val.isNotEmpty && val.startsWith('http')) return val;
      }
      final dMedia = deity['media'];
      if (dMedia is Map) {
        final val = extract(dMedia['images']);
        if (val.isNotEmpty && val.startsWith('http')) return val;
      }
    }

    for (final key in [
      'imageUrl',
      'image',
      'heroImage',
      'poojaImage',
      'pooja_image'
    ]) {
      final val = extract(pooja[key]);
      if (val.isNotEmpty) return val;
    }

    return null;
  }
}
