import 'package:get/get.dart';
import 'package:satya_devotte_app/core/services/media_upload_service.dart';
import 'package:satya_devotte_app/features/cms/data/datasources/deity_remote_datasource.dart';
import 'package:satya_devotte_app/features/cms/models/deity_model.dart';

import 'package:satya_devotte_app/features/cms/presentation/widgets/cms_shared_widgets.dart';

class DeityController extends GetxController {
  DeityController(this._dataSource);
  final DeityRemoteDataSource _dataSource;

  final _deities = <DeityModel>[].obs;
  final _isLoading = false.obs;
  final _isSubmitting = false.obs;
  final _error = RxnString();
  final _page = 1.obs;
  final _limit = 10.obs;
  final _total = 0.obs;
  final _totalPages = 1.obs;
  final _statusFilter = RxnString();
  final _search = ''.obs;
  final _pendingCount = 0.obs;
  final _queuedCount = 0.obs;

  bool _loadInFlight = false;

  List<DeityModel> get deities => _deities;
  bool get isLoading => _isLoading.value;
  bool get isSubmitting => _isSubmitting.value;
  String? get error => _error.value;
  int get page => _page.value;
  int get limit => _limit.value;
  int get total => _total.value;
  int get totalPages => _totalPages.value;
  String? get statusFilter => _statusFilter.value;
  String get search => _search.value;

  // Filter-chip totals stay independent of the active status filter.
  int get pendingCount => _pendingCount.value;
  int get queuedCount => _queuedCount.value;

  void setSearch(String value) {
    final q = value.trim();
    if (_search.value == q) return;
    _search.value = q;
    loadDeities(page: 1, force: true);
  }

  void clearSearch() {
    _search.value = '';
  }

  Future<void> resetSearchOnTabFocus() async {
    _search.value = '';
    await loadDeities(page: 1, force: true, search: '');
  }

  Future<void> goToPage(int target) async {
    final p = target.clamp(1, _totalPages.value);
    if (p == _page.value && _deities.isNotEmpty) return;
    await loadDeities(page: p, force: true);
  }

  Future<void> setPageSize(int size) async {
    final capped = size.clamp(1, 100);
    if (capped == _limit.value) return;
    _limit.value = capped;
    await loadDeities(page: 1, force: true);
  }

  Future<void> setStatusFilter(String? status) async {
    _search.value = '';
    _statusFilter.value = status;
    await loadDeities(page: 1, force: true, search: '');
  }

  Future<void> loadDeities({
    int? page,
    int? limit,
    String? status,
    String? search,
    bool force = false,
  }) async {
    if (_loadInFlight && !force) return;
    final targetPage = page ?? _page.value;
    final targetLimit = limit ?? _limit.value;
    final targetStatus = status ?? _statusFilter.value;
    final targetSearch = search ?? _search.value;

    _loadInFlight = true;
    _isLoading.value = true;
    _error.value = null;
    try {
      final result = await _dataSource.getDeities(
        page: targetPage,
        limit: targetLimit,
        status: targetStatus,
        search: targetSearch.trim().isEmpty ? null : targetSearch.trim(),
      );
      _deities.assignAll(result.items);
      _page.value = result.page;
      _limit.value = result.limit;
      _total.value = result.total;
      _totalPages.value = result.totalPages;
      _statusFilter.value = targetStatus;
      _search.value = targetSearch.trim();
      if (targetStatus == 'PENDING') {
        _pendingCount.value = result.total;
      } else if (targetStatus == 'QUEUED') {
        _queuedCount.value = result.total;
      }
      await _refreshFilterCounts(currentStatus: targetStatus);
    } catch (_) {
      _error.value = 'Failed to load deities';
      showCmsSnackbar(
        title: 'Error',
        message: 'Failed to load deities',
        isError: true,
      );
    } finally {
      _isLoading.value = false;
      _loadInFlight = false;
    }
  }

  Future<void> _refreshFilterCounts({required String? currentStatus}) async {
    try {
      final futures = <Future<void>>[];
      if (currentStatus != 'PENDING') {
        futures.add(
          _dataSource
              .getDeities(page: 1, limit: 1, status: 'PENDING')
              .then((r) => _pendingCount.value = r.total),
        );
      }
      if (currentStatus != 'QUEUED') {
        futures.add(
          _dataSource
              .getDeities(page: 1, limit: 1, status: 'QUEUED')
              .then((r) => _queuedCount.value = r.total),
        );
      }
      await Future.wait(futures);
    } catch (_) {}
  }

  Future<bool> createDeity(
    Map<String, dynamic> payload, {
    PickedFile? image,
    PickedFile? audio,
    PickedFile? video,
  }) async {
    _isSubmitting.value = true;
    _error.value = null;
    try {
      await _dataSource.createDeity(
        payload,
        image: image,
        audio: audio,
        video: video,
      );
      await loadDeities(force: true);
      _ok('Deity created successfully');
      return true;
    } catch (_) {
      _error.value = 'Failed to create deity';
      _err(_error.value!);
      return false;
    } finally {
      _isSubmitting.value = false;
    }
  }

  Future<bool> updateDeity(
    String id,
    Map<String, dynamic> payload, {
    PickedFile? image,
    PickedFile? audio,
    PickedFile? video,
  }) async {
    _isSubmitting.value = true;
    _error.value = null;
    try {
      await _dataSource.updateDeity(
        id,
        payload,
        image: image,
        audio: audio,
        video: video,
      );
      await loadDeities(force: true);
      _ok('Deity updated successfully');
      return true;
    } catch (_) {
      _error.value = 'Failed to update deity';
      _err(_error.value!);
      return false;
    } finally {
      _isSubmitting.value = false;
    }
  }

  Future<DeityModel?> getDeityById(String id) async {
    try {
      return await _dataSource.getDeityById(id);
    } catch (_) {
      _error.value = 'Failed to load deity details';
      _err(_error.value!);
      return null;
    }
  }

  Future<bool> deleteDeity(String id) async {
    try {
      await _dataSource.deleteDeity(id);
      await loadDeities(force: true);
      _ok('Deity deleted successfully');
      return true;
    } catch (_) {
      _error.value = 'Failed to delete deity';
      _err(_error.value!);
      return false;
    }
  }

  Future<bool> approveDeity(String id) async {
    try {
      await _dataSource.approveDeity(id);
      await loadDeities(force: true);
      _ok('Deity approved and published');
      return true;
    } catch (_) {
      _error.value = 'Failed to approve deity';
      _err(_error.value!);
      return false;
    }
  }

  Future<bool> queueDeity(String id) async {
    try {
      await _dataSource.reviewDeity(id, 'QUEUED');
      await loadDeities(force: true);
      _ok('Deity moved to queue');
      return true;
    } catch (_) {
      _error.value = 'Failed to queue deity';
      _err(_error.value!);
      return false;
    }
  }

  Future<bool> rejectDeity(String id) async {
    try {
      await _dataSource.rejectDeity(id);
      await loadDeities(force: true);
      _ok('Deity has been rejected');
      return true;
    } catch (_) {
      _error.value = 'Failed to reject deity';
      _err(_error.value!);
      return false;
    }
  }

  void _ok(String msg) => showCmsSnackbar(title: 'Success', message: msg);
  void _err(String msg) =>
      showCmsSnackbar(title: 'Error', message: msg, isError: true);
}
