import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/features/donations/presentation/widgets/donation_ui.dart';
import 'package:satya_devotte_app/features/profile/presentation/controllers/pooja_history_controller.dart';
import 'package:satya_devotte_app/features/pujas/presentation/models/pooja_view_model.dart';
import 'package:satya_devotte_app/features/pujas/presentation/pages/pooja_step_wizard.dart';
import 'package:satya_devotte_app/features/pujas/presentation/pages/puja_detail_page.dart';

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
      itemBuilder: (_, i) {
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
        final statusColor = isFinished
            ? const Color(0xFF10B981)
            : const Color(0xFFF59E0B);

        final deity = pooja['deity'] is Map ? pooja['deity'] as Map : {};

        // Extract Image URL from the nested media structure in your JSON
        String? imageUrl;
        final deityMedia = deity['media'];
        if (deityMedia is Map &&
            deityMedia['images'] is List &&
            (deityMedia['images'] as List).isNotEmpty) {
          imageUrl = deityMedia['images'][0].toString();
        }

        // Fallback to pooja hero image if deity image is missing
        imageUrl ??= pooja['heroImage'];

        final description = pooja['description'] ?? pooja['purpose'] ?? '';

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              color: Color(0XFFFCF7EF),
              borderRadius: BorderRadius.circular(16),
              elevation: 0,
              child: InkWell(
                onTap: () {
                  final poojaData = session['pooja'];
                  if (poojaData is! Map) return;
                  final poojaMap = Map<String, dynamic>.from(poojaData);
                  final sessionId = (session['_id'] ?? session['id'])
                      ?.toString();

                  if (_isInProgress(session)) {
                    Get.to(
                      () => PoojaStepWizard(
                        pooja: PoojaView(poojaMap),
                        initialStep: currentStepIndex,
                        sessionId: sessionId,
                      ),
                    );
                  } else {
                    Get.to(() => const RitualDetailPage(), arguments: poojaMap);
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: DonationUi.cardBorder),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Deity Image (Circular like Figma)
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFF5F5F5),
                          border: Border.all(
                            color: const Color(0xFFE5E5E5),
                            width: 1,
                          ),
                        ),
                        child: ClipOval(
                          child:
                              imageUrl != null && imageUrl.toString().isNotEmpty
                              ? Image.network(
                                  imageUrl.toString(),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.temple_hindu,
                                    color: Color(0xFFD1D5DB),
                                  ),
                                )
                              : const Icon(
                                  Icons.temple_hindu,
                                  color: Color(0xFFD1D5DB),
                                ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Text Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 2),
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1C1917),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.inter(
                                fontSize: 12,
                                color: const Color(0xFF78716C),
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  size: 12,
                                  color: Color(0xFFA8A29E),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  when,
                                  style: AppTypography.inter(
                                    fontSize: 11,
                                    color: const Color(0xFFA8A29E),
                                  ),
                                ),
                                const Spacer(),
                                if (stepLabel.isNotEmpty)
                                  Text(
                                    stepLabel,
                                    style: AppTypography.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFF59E0B),
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
            ),
            // Status Badge at top right
            Positioned(
              top: -6,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  session['status'].toString(),
                  style: AppTypography.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFFCF7EF),
                  ),
                ),
              ),
            ),
          ],
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
}
