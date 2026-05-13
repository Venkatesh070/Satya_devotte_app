// CMS admin notifications screen state.
//
// Drives:
//   • POST /api/v1/notifications/send  (the Send Push Notification card)
//   • GET  /api/v1/notifications       (the Recently Sent paginated list)
//   • POST /api/v1/notifications/:id/cancel
import 'dart:async';

import 'package:get/get.dart';

import 'package:satya_devotte_app/features/notifications/data/models/app_notification.dart';
import 'package:satya_devotte_app/features/notifications/data/models/send_notification_request.dart';
import 'package:satya_devotte_app/features/notifications/data/notifications_exception.dart';
import 'package:satya_devotte_app/features/notifications/data/notifications_repository.dart';

class CmsNotificationsController extends GetxController {
  CmsNotificationsController(this._repo);
  final NotificationsRepository _repo;

  /// Filter chip values for the Recently Sent list. Mirrors server `status`.
  static const statusFilters = <String>[
    'ALL',
    'SENT',
    'SCHEDULED',
    'PENDING',
    'SENDING',
    'FAILED',
    'CANCELLED',
  ];

  /// Audience options the dropdown exposes. `USER_IDS` is intentionally
  /// omitted from the v1 UI (per the plan).
  static const audienceOptions = <String>[
    'ALL',
    'USERS',
    'ADMINS',
    'SUPERADMIN',
  ];

  // ── Send-form state ──────────────────────────────────────────────
  final _sending = false.obs;
  final _lastSendError = RxnString();
  final _lastSent = Rxn<AppNotification>();

  bool get isSending => _sending.value;
  String? get lastSendError => _lastSendError.value;
  AppNotification? get lastSent => _lastSent.value;

  // ── List state ───────────────────────────────────────────────────
  final _items = <AppNotification>[].obs;
  final _isLoading = false.obs;
  final _isCancelling = <String>{}.obs;
  final _listError = RxnString();
  final _page = 1.obs;
  final _limit = 10.obs;
  final _total = 0.obs;
  final _totalPages = 1.obs;
  final _statusFilter = 'ALL'.obs;

  List<AppNotification> get items => _items;
  bool get isLoading => _isLoading.value;
  String? get listError => _listError.value;
  int get page => _page.value;
  int get limit => _limit.value;
  int get total => _total.value;
  int get totalPages => _totalPages.value;
  String get statusFilter => _statusFilter.value;
  bool get isEmpty =>
      !_isLoading.value && _listError.value == null && _items.isEmpty;
  bool isCancelling(String id) => _isCancelling.contains(id);

  String? get _statusQuery =>
      _statusFilter.value == 'ALL' ? null : _statusFilter.value;

  @override
  void onInit() {
    super.onInit();
    refreshList();
  }

  // ── Send ─────────────────────────────────────────────────────────
  Future<AppNotification?> send(SendNotificationRequest req) async {
    _sending.value = true;
    _lastSendError.value = null;
    try {
      final created = await _repo.sendNotification(req);
      _lastSent.value = created;
      // Optimistically prepend if we're on page 1 with no filter, or it
      // matches the active filter.
      final filter = _statusQuery;
      if (_page.value == 1 &&
          (filter == null || filter == created.statusLabel)) {
        _items.insert(0, created);
        _total.value = _total.value + 1;
        if (_items.length > _limit.value) {
          _items.removeRange(_limit.value, _items.length);
        }
      } else {
        // Still refresh in the background so totals + ordering stay in sync.
        unawaited(refreshList());
      }
      return created;
    } on NotificationsException catch (e) {
      _lastSendError.value = e.message;
      return null;
    } catch (_) {
      _lastSendError.value = 'Failed to send notification.';
      return null;
    } finally {
      _sending.value = false;
    }
  }

  void clearSendError() => _lastSendError.value = null;

  // ── List + pagination ────────────────────────────────────────────
  Future<void> refreshList() => _load(page: 1);

  Future<void> goToPage(int target) async {
    if (target < 1) target = 1;
    if (target > _totalPages.value) target = _totalPages.value;
    if (target == _page.value && _items.isNotEmpty) return;
    await _load(page: target);
  }

  Future<void> nextPage() => goToPage(_page.value + 1);
  Future<void> prevPage() => goToPage(_page.value - 1);

  void setStatusFilter(String f) {
    final v = f.toUpperCase();
    if (!statusFilters.contains(v) || _statusFilter.value == v) return;
    _statusFilter.value = v;
    refreshList();
  }

  void setLimit(int v) {
    if (v <= 0 || v == _limit.value) return;
    _limit.value = v;
    refreshList();
  }

  Future<void> _load({required int page}) async {
    _isLoading.value = true;
    _listError.value = null;
    try {
      final res = await _repo.listNotifications(
        page: page,
        limit: _limit.value,
        status: _statusQuery,
      );
      _items.assignAll(res.items);
      _page.value = res.page;
      _limit.value = res.limit;
      _total.value = res.total;
      _totalPages.value = res.totalPages;
    } on NotificationsException catch (e) {
      _listError.value = e.message;
    } catch (_) {
      _listError.value = 'Failed to load notifications.';
    } finally {
      _isLoading.value = false;
    }
  }

  // ── Cancel ───────────────────────────────────────────────────────
  Future<String?> cancel(String id) async {
    if (_isCancelling.contains(id)) return null;
    _isCancelling.add(id);
    try {
      final updated = await _repo.cancelNotification(id);
      final idx = _items.indexWhere((n) => n.id == id);
      if (idx >= 0) {
        _items[idx] = updated;
        _items.refresh();
      }
      // If we're filtering by SCHEDULED, the updated row no longer matches.
      if (_statusQuery == 'SCHEDULED') {
        _items.removeWhere((n) => n.id == id);
      }
      return null;
    } on NotificationsException catch (e) {
      return e.message;
    } catch (_) {
      return 'Failed to cancel notification.';
    } finally {
      _isCancelling.remove(id);
    }
  }
}
