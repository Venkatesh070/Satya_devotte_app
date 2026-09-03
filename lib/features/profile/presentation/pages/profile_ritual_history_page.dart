import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/features/cms/data/datasources/ritual_remote_datasource.dart';
import 'package:satya_devotte_app/features/cms/models/ritual_model.dart';
import 'package:satya_devotte_app/features/donations/presentation/widgets/donation_ui.dart';
import 'package:satya_devotte_app/features/profile/presentation/controllers/ritual_history_controller.dart';
import 'package:satya_devotte_app/features/pujas/presentation/pages/ritual_step_wizard.dart';
import 'package:satya_devotte_app/features/pujas/presentation/pages/user_ritual_detail_page.dart';
import 'package:satya_devotte_app/features/pujas/presentation/widgets/puja_shared_widgets.dart';
import 'package:satya_devotte_app/shared/widgets/shimmer_skeleton.dart';

class ProfileRitualHistoryPage extends StatefulWidget {
  const ProfileRitualHistoryPage({super.key});

  @override
  State<ProfileRitualHistoryPage> createState() =>
      _ProfileRitualHistoryPageState();
}

class _ProfileRitualHistoryPageState extends State<ProfileRitualHistoryPage> {
  late final RitualHistoryController c;

  @override
  void initState() {
    super.initState();
    c = Get.find<RitualHistoryController>();
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
            'Ritual History',
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
              c.finishedRituals.isEmpty &&
              c.pendingRituals.isEmpty) {
            return const HistoryListSkeleton();
          }

          if (c.error.value != null &&
              c.finishedRituals.isEmpty &&
              c.pendingRituals.isEmpty) {
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
                _RitualHistoryList(
                  items: c.finishedRituals,
                  emptyMessage: 'No finished rituals yet',
                  controller: c,
                ),
                _RitualHistoryList(
                  items: c.pendingRituals,
                  emptyMessage: 'No rituals in progress',
                  controller: c,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _RitualHistoryList extends StatelessWidget {
  const _RitualHistoryList({
    required this.items,
    required this.emptyMessage,
    required this.controller,
  });

  final List<dynamic> items;
  final String emptyMessage;
  final RitualHistoryController controller;

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
        final ritual = session['ritual'] is Map
            ? session['ritual'] as Map
            : <String, dynamic>{};
        final title = ritual['title'] ?? 'Ritual';

        final rawDate = session['finishedAt'] ??
            session['lastActivityAt'] ??
            session['createdAt'];
        String when = '';
        if (rawDate != null) {
          try {
            final date = DateTime.parse(rawDate.toString());
            when = DateFormat('MMMM d, yyyy | h:mm a').format(date.toLocal());
          } catch (_) {}
        }

        final currentDay = _intValue(session['currentDay']) > 0
            ? _intValue(session['currentDay'])
            : 1;
        final currentStep = _intValue(session['currentStep']);
        final totalDaysFromSession = _intValue(session['totalDays']);
        final daysList = ritual['days'] is List ? ritual['days'] as List : [];
        final totalDays = totalDaysFromSession > 0
            ? totalDaysFromSession
            : (daysList.isNotEmpty ? daysList.length : 1);

        final completedDaysList = session['completedDays'] is List
            ? session['completedDays'] as List
            : [];
        final completedCount = completedDaysList.length;

        final inProgress = _isInProgress(session);
        final isFinished = _isFinished(session);
        final statusText = isFinished ? 'Finished' : 'In Progress';

        String progressLabel = '';
        if (isFinished) {
          progressLabel = '$totalDays/$totalDays days completed';
        } else if (inProgress) {
          if (currentStep > 0) {
            progressLabel = 'Day $currentDay · Step $currentStep';
          } else {
            progressLabel = totalDays > 1
                ? 'Day $currentDay of $totalDays'
                : 'Day $currentDay';
          }
        }

        final imageUrl = _extractRitualImage(ritual);
        final description = (ritual['description'] ??
                ritual['purpose'] ??
                ritual['category'] ??
                '')
            .toString();

        return Material(
          color: const Color(0xFFFCF7EF),
          borderRadius: BorderRadius.circular(16),
          elevation: 0,
          child: InkWell(
            onTap: () async {
              final ritualData = session['ritual'];
              if (ritualData is! Map) return;
              final ritualMap = Map<String, dynamic>.from(ritualData);
              final sessionId = (session['_id'] ?? session['id'])?.toString();
              final ritualId =
                  (ritualMap['_id'] ?? ritualMap['id'] ?? '').toString();

              if (_isInProgress(session)) {
                RitualModel? ritualModel;
                if (ritualMap['days'] is List &&
                    (ritualMap['days'] as List).isNotEmpty) {
                  ritualModel = RitualModel.fromJson(ritualMap);
                } else if (Get.isRegistered<RitualRemoteDataSource>()) {
                  try {
                    ritualModel = await Get.find<RitualRemoteDataSource>()
                        .getRitualById(ritualId);
                  } catch (e) {
                    debugPrint('Error fetching ritual detail: $e');
                  }
                }

                if (ritualModel == null) {
                  await Get.to(
                    () => UserRitualDetailPage(ritualId: ritualId),
                  );
                  controller.fetchHistory(skipLoader: true);
                  return;
                }

                // Calculate target step page in wizard
                final dayDef = ritualModel.dayByNumber(currentDay);
                final hasRequiredItems =
                    dayDef != null && dayDef.requiredItems.isNotEmpty;
                final stepOffset = hasRequiredItems ? 2 : 1;

                int targetStep = 0;
                if (currentStep >= 1) {
                  targetStep = (currentStep - 1) + stepOffset;
                }

                await Get.to(
                  () => RitualStepWizard(
                    ritual: ritualModel!,
                    sessionId: sessionId,
                    initialDay: currentDay,
                    initialStep: targetStep,
                  ),
                );
                controller.fetchHistory(skipLoader: true);
              } else {
                await Get.to(
                  () => UserRitualDetailPage(ritualId: ritualId),
                );
                controller.fetchHistory(skipLoader: true);
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
                  // Ritual Image
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
                            if (when.isNotEmpty) ...[
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
                            ] else
                              const Spacer(),
                            if (progressLabel.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Text(
                                progressLabel,
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

  String? _extractRitualImage(Map ritual) {
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
      'ritualImage',
      'ritual_image',
    ]) {
      final val = extract(ritual[key]);
      if (val.isNotEmpty && val.startsWith('http')) return val;
    }

    final images = ritual['images'];
    if (images is List && images.isNotEmpty) {
      final val = extract(images.first);
      if (val.isNotEmpty && val.startsWith('http')) return val;
    }

    final media = ritual['media'];
    if (media is Map) {
      for (final key in ['images', 'heroImage', 'bannerImage', 'image']) {
        final val = extract(media[key]);
        if (val.isNotEmpty && val.startsWith('http')) return val;
      }
    }

    final deity = ritual['deity'];
    if (deity is List && deity.isNotEmpty) {
      for (final d in deity) {
        if (d is Map) {
          final dMedia = d['media'];
          if (dMedia is Map) {
            final val = extract(dMedia['images']);
            if (val.isNotEmpty && val.startsWith('http')) return val;
          }
        }
      }
    }

    for (final key in [
      'imageUrl',
      'image',
      'heroImage',
    ]) {
      final val = extract(ritual[key]);
      if (val.isNotEmpty) return val;
    }

    return null;
  }
}
