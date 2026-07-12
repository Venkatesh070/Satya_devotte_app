import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/core/utils/toast_util.dart';
import 'package:satya_devotte_app/config/routes/app_routes.dart';

import 'package:satya_devotte_app/features/notifications/data/notifications_exception.dart';
import 'package:satya_devotte_app/features/notifications/data/user_notifications_repository.dart';
import 'package:satya_devotte_app/features/notifications/presentation/controllers/user_notifications_badge_controller.dart';
import 'package:satya_devotte_app/features/poojakit/data/repositories/poojakit_repository.dart';
import 'package:satya_devotte_app/shared/widgets/chakra_loading_indicator.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  static const int _limit = 20;

  final _scrollController = ScrollController();
  late final UserNotificationsRepository _repo;
  late final PoojaKitRepository _poojaKitRepo;

  final List<UserNotificationItem> _items = <UserNotificationItem>[];
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;
  int _page = 1;
  int _totalPages = 1;

  bool get _hasMore => _page < _totalPages;

  @override
  void initState() {
    super.initState();
    _repo = Get.find<UserNotificationsRepository>();
    _poojaKitRepo = Get.find<PoojaKitRepository>();
    if (Get.isRegistered<UserNotificationsBadgeController>()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Get.find<UserNotificationsBadgeController>().clearBadge();
      });
    }
    _scrollController.addListener(_onScroll);
    _loadFirstPage();
  }

  Future<void> _onNotificationTap(UserNotificationItem item) async {
    final orderId = item.orderId;
    if (orderId == null || !item.isDeliveredOrderNotification) {
      return;
    }
    try {
      final order = await _poojaKitRepo.getOrderDetail(orderId);
      if (!mounted) return;
      await Get.toNamed(AppRoutes.userOrderDetail, arguments: order);
    } catch (_) {
      if (!mounted) return;
      ToastUtil.showInfo('Could not open order details.');
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients ||
        _loading ||
        _loadingMore ||
        !_hasMore) {
      return;
    }
    final max = _scrollController.position.maxScrollExtent;
    if (_scrollController.position.pixels >= max - 180) {
      _loadNextPage();
    }
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _repo.list(page: 1, limit: _limit);
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(res.items);
        _page = res.page;
        _totalPages = res.totalPages;
      });
    } on NotificationsException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Failed to load notifications.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadNextPage() async {
    if (!_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final next = _page + 1;
      final res = await _repo.list(page: next, limit: _limit);
      if (!mounted) return;
      setState(() {
        _items.addAll(res.items);
        _page = res.page;
        _totalPages = res.totalPages;
      });
    } on NotificationsException catch (e) {
      if (!mounted) return;
      ToastUtil.showInfo(e.message);
    } catch (_) {
      if (!mounted) return;
      ToastUtil.showInfo('Failed to load more notifications.');
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2EBDC),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _TopBar(),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
              child: Text(
                'Notifications',
                style: AppTypography.lora(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF4A1C00),
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadFirstPage,
                child: _loading
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [SizedBox(height: 400)],
                      )
                    : _error != null
                    ? ListView(
                        children: [
                          const SizedBox(height: 120),
                          Center(
                            child: Column(
                              children: [
                                Text(_error!, textAlign: TextAlign.center),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: _loadFirstPage,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : _items.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 120),
                          Center(child: Text('No notifications yet.')),
                        ],
                      )
                    : ListView.separated(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                        itemCount: _items.length + (_loadingMore ? 1 : 0),
                        separatorBuilder: (_, _) => const Divider(
                          height: 1,
                          thickness: 1,
                          color: Color(0xFFE0D6C2),
                        ),
                        itemBuilder: (context, i) {
                          if (i >= _items.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Center(
                                child: ChakraLoadingIndicator(size: 24),
                              ),
                            );
                          }
                          final item = _items[i];
                          return _NotificationTile(
                            item: item,
                            onTap: () => _onNotificationTap(item),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Material(
          color: Color(0xFFFCF7EF),
          shape: const CircleBorder(),
          elevation: 5,
          shadowColor: const Color(0x22000000),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                Get.offNamed(AppRoutes.home);
              }
            },
            child: const SizedBox(
              width: 40,
              height: 40,
              child: Icon(Icons.arrow_back, size: 19, color: Color(0xFF1C1C1C)),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.onTap});
  final UserNotificationItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('d MMM, h:mm a').format(item.createdAt);
    final leadingAsset = item.isOrderTypeNotification
        ? 'assets/images/home/morePoojas.png'
        : 'assets/images/appLogo.png';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  leadingAsset,
                  width: 42,
                  height: 42,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 42,
                    height: 42,
                    color: const Color(0xFFE6DDCC),
                    child: const Icon(Icons.notifications, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2B1A0C),
                      ),
                    ),
                    if (item.body.trim().isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        item.body,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: Color(0xFF5B4C3C),
                        ),
                      ),
                    ],
                    const SizedBox(height: 7),
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF8B7E70),
                      ),
                    ),
                  ],
                ),
              ),
              if (item.notificationType == 'ORDER_DELIVERED') ...[
                const SizedBox(width: 8),
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: Color(0xFF8B7E70),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
