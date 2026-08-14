import 'package:satya_devotte_app/core/services/media_upload_service.dart';
// lib/features/cms/presentation/controllers/festival_controller.dart
import 'package:get/get.dart';
import 'package:satya_devotte_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:satya_devotte_app/features/cms/data/datasources/festival_remote_datasource.dart';
import 'package:satya_devotte_app/core/models/festival_model.dart';
import 'package:satya_devotte_app/features/cms/presentation/widgets/cms_shared_widgets.dart';

class FestivalController extends GetxController {
  FestivalController(this._dataSource);
  final FestivalRemoteDataSource _dataSource;

  final _festivals = <FestivalModel>[].obs;
  final _isLoading = false.obs;
  final _isSubmitting = false.obs;
  final _error = RxnString();
  final _filter = 'All'.obs;
  final _page = 1.obs;
  final _limit = 10.obs;
  final _total = 0.obs;
  final _totalPages = 1.obs;
  final _search = ''.obs;

  List<FestivalModel> get festivals => _festivals;
  bool get isLoading => _isLoading.value;
  bool get isSubmitting => _isSubmitting.value;
  String? get error => _error.value;
  String get filter => _filter.value;
  int? get selectedMonth => null;
  int get page => _page.value;
  int get limit => _limit.value;
  int get total => _total.value;
  int get totalPages => _totalPages.value;
  String get search => _search.value;

  List<FestivalModel> get filteredFestivals => _festivals.toList();

  List<FestivalModel> get festivalsByMonth => filteredFestivals;

  int get pendingCount => _festivals.where((f) => f.status == 'Pending').length;
  int get queuedCount => _festivals.where((f) => f.status == 'Queued').length;

  @override
  void onInit() {
    super.onInit();
    Future.microtask(() => loadFestivals(showErrorSnackbar: false));
  }

  void setFilter(String f) {
    if (_filter.value == f) return;
    _filter.value = f;
    loadFestivals(page: 1);
  }

  void setMonth(int? m) {}

  Future<void> goToPage(int target) async {
    final p = target.clamp(1, _totalPages.value);
    if (p == _page.value && _festivals.isNotEmpty) return;
    await loadFestivals(page: p);
  }

  Future<void> setPageSize(int size) async {
    if (size <= 0 || size == _limit.value) return;
    _limit.value = size;
    await loadFestivals(page: 1);
  }

  void setSearch(String value) {
    final q = value.trim();
    if (_search.value == q) return;
    _search.value = q;
    loadFestivals(page: 1);
  }

  // ── LOAD ──────────────────────────────────────────────────────
  Future<void> loadFestivals({bool showErrorSnackbar = true, int? page, int? limit}) async {
    _isLoading.value = true;
    _error.value = null;
    try {
      final auth = Get.find<AuthController>();
      final status =
          _filter.value == 'All' ? null : _filter.value.toUpperCase();
      final result = await _dataSource.getFestivalsPage(
        superAdmin: auth.isSuperAdmin,
        page: page ?? _page.value,
        limit: limit ?? _limit.value,
        status: status,
        search: _search.value.trim().isEmpty ? null : _search.value.trim(),
      );
      _festivals.assignAll(result.items);
      _page.value = result.page;
      _limit.value = result.limit;
      _total.value = result.total;
      _totalPages.value = result.totalPages;
    } catch (e) {
      _error.value = _parseError(e);
      if (showErrorSnackbar) {
        showCmsSnackbar(
          title: 'Error',
          message: 'Failed to load festivals: ${_error.value}',
          isError: true,
        );
      }
    } finally {
      _isLoading.value = false;
    }
  }

  // ── CREATE ────────────────────────────────────────────────────
  Future<bool> createFestival(
    Map<String, dynamic> body, {
    PickedFile? image,
  }) async {
    _isSubmitting.value = true;
    _error.value = null;
    try {
      await _dataSource.createFestival(body, image: image);
      await loadFestivals();
      _ok('Festival submitted for review');
      return true;
    } catch (e) {
      _error.value = _parseError(e);
      _err(_error.value!);
      return false;
    } finally {
      _isSubmitting.value = false;
    }
  }

  // ── UPDATE ────────────────────────────────────────────────────
  Future<bool> updateFestival(
    String id,
    Map<String, dynamic> body, {
    PickedFile? image,
  }) async {
    _isSubmitting.value = true;
    _error.value = null;
    try {
      await _dataSource.updateFestival(id, body);
      await loadFestivals();
      _ok('Festival updated');
      return true;
    } catch (e) {
      _error.value = _parseError(e);
      _err(_error.value!);
      return false;
    } finally {
      _isSubmitting.value = false;
    }
  }

  // ── DELETE ────────────────────────────────────────────────────
  Future<bool> deleteFestival(String id) async {
    try {
      await _dataSource.deleteFestival(id);
      _festivals.removeWhere((f) => f.id == id);
      _ok('Festival deleted');
      return true;
    } catch (e) {
      _error.value = _parseError(e);
      _err(_error.value!);
      return false;
    }
  }

  // ── APPROVE ───────────────────────────────────────────────────
  Future<bool> approveFestival(String id) async {
    try {
      final result = await _dataSource.reviewFestival(id, 'APPROVED');
      final idx = _festivals.indexWhere((f) => f.id == id);
      if (idx != -1) _festivals[idx] = result;
      _ok('Festival approved and published');
      return true;
    } catch (e) {
      _error.value = _parseError(e);
      _err(_error.value!);
      return false;
    }
  }

  Future<bool> queueFestival(String id) async {
    try {
      final result = await _dataSource.reviewFestival(id, 'QUEUED');
      final idx = _festivals.indexWhere((f) => f.id == id);
      if (idx != -1) _festivals[idx] = result;
      _ok('Festival moved to queue');
      return true;
    } catch (e) {
      _error.value = _parseError(e);
      _err(_error.value!);
      return false;
    }
  }

  // ── REJECT ────────────────────────────────────────────────────
  Future<bool> rejectFestival(String id, String reason) async {
    try {
      await _dataSource.reviewFestival(id, 'REJECTED', reason: reason);
      _festivals.removeWhere((f) => f.id == id);
      _ok('Festival rejected');
      return true;
    } catch (e) {
      _error.value = _parseError(e);
      _err(_error.value!);
      return false;
    }
  }

  void _ok(String msg) => showCmsSnackbar(title: 'Success', message: msg);

  void _err(String msg) =>
      showCmsSnackbar(title: 'Error', message: msg, isError: true);

  String _parseError(Object e) {
    final m = e.toString();
    if (m.contains('404')) return 'Festival not found.';
    if (m.contains('401') || m.contains('403')) return 'Not authorised.';
    if (m.contains('500')) return 'Server error. Try again.';
    if (m.contains('SocketException') || m.contains('connection')) {
      return 'No internet connection.';
    }
    return 'Something went wrong. Please try again.';
  }
}
