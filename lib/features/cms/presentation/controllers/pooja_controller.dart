import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/features/cms/data/datasources/pooja_remote_datasource.dart';
import 'package:satya_devotte_app/core/services/media_upload_service.dart';
import 'package:satya_devotte_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:satya_devotte_app/features/cms/models/pooja_model.dart';
import 'package:satya_devotte_app/features/cms/presentation/widgets/cms_shared_widgets.dart';

class PoojaController extends GetxController {
  PoojaController(this._dataSource);
  final PoojaRemoteDataSource _dataSource;

  // ── State ────────────────────────────────────────────────────
  final _poojas = <PoojaModel>[].obs;
  final _isLoading = false.obs;
  final _isSubmitting = false.obs;
  final _error = RxnString();
  final _filter = 'All'.obs;
  final _deities = <Map<String, String>>[].obs;
  final _isLoadingDeities = false.obs;
  final _deitiesLoaded = false.obs;
  final _page = 1.obs;
  final _limit = 10.obs;
  final _total = 0.obs;
  final _totalPages = 1.obs;
  final _search = ''.obs;
  final _pendingCount = 0.obs;
  final _queuedCount = 0.obs;

  List<PoojaModel> get poojas => _poojas;
  bool get isLoading => _isLoading.value;
  bool get isSubmitting => _isSubmitting.value;
  String? get error => _error.value;
  String get filter => _filter.value;
  int get page => _page.value;
  int get limit => _limit.value;
  int get total => _total.value;
  int get totalPages => _totalPages.value;
  String get search => _search.value;
  List<Map<String, String>> get deities => _deities;
  bool get isLoadingDeities => _isLoadingDeities.value;
  bool get deitiesLoaded => _deitiesLoaded.value;

  // Client-side filter on the current server page (All hides Rejected unless searching).
  List<PoojaModel> get filteredPoojas {
    if (_search.value.isNotEmpty) return _poojas.toList();
    if (_filter.value == 'All') {
      return _poojas.where((p) => p.status != 'Rejected').toList();
    }
    return _poojas.toList();
  }

  // Filter-chip totals stay independent of the active status filter.
  int get pendingCount => _pendingCount.value;
  int get queuedCount => _queuedCount.value;
  int get rejectedCount => _poojas.where((p) => p.status == 'Rejected').length;

  @override
  void onInit() {
    super.onInit();
    Future.microtask(() async {
      await loadPoojas(showErrorSnackbar: false);
      await loadDeities();
    });
  }

  // ── Set filter — reloads from server page 1 ───────────────────
  void setFilter(String f) {
    final same = _filter.value == f;
    final hadSearch = _search.value.isNotEmpty;
    if (same && !hadSearch) return;
    _filter.value = f;
    _search.value = '';
    loadPoojas(page: 1);
  }

  Future<void> goToPage(int target) async {
    final p = target.clamp(1, _totalPages.value);
    if (p == _page.value && _poojas.isNotEmpty) return;
    await loadPoojas(page: p);
  }

  Future<void> setPageSize(int size) async {
    final capped = size.clamp(1, 100);
    if (capped == _limit.value) return;
    _limit.value = capped;
    await loadPoojas(page: 1);
  }

  /// Called when entering Manage Poojas tab — resets to All and reloads.
  /// Use this instead of setFilter('All') when navigating back from Approvals
  /// so stale loadAllPoojas data is replaced with properly filtered data.
  void resetAndLoad() {
    _filter.value = 'All';
    _search.value = '';
    loadPoojas(page: 1, showErrorSnackbar: false);
  }

  void clearSearch() {
    _search.value = '';
  }

  Future<void> resetSearchOnTabFocus() async {
    _search.value = '';
    await loadPoojas(page: 1, showErrorSnackbar: false);
  }

  void setSearch(String value) {
    final q = value.trim();
    if (_search.value == q) return;
    _search.value = q;
    loadPoojas(page: 1);
  }

  Future<void> loadPoojas({bool showErrorSnackbar = true, int? page}) async {
    _isLoading.value = true;
    _error.value = null;
    try {
      final auth = Get.find<AuthController>();
      final status =
          _filter.value == 'All' ? null : _filter.value.toUpperCase();
      final result = await _dataSource.getPoojasPage(
        superAdmin: auth.isSuperAdmin,
        page: page ?? _page.value,
        limit: _limit.value,
        status: status,
        search: _search.value.trim().isEmpty ? null : _search.value.trim(),
      );
      _poojas.assignAll(result.items);
      _page.value = result.page;
      _limit.value = result.limit;
      _total.value = result.total;
      _totalPages.value = result.totalPages;
      if (_filter.value == 'Pending') {
        _pendingCount.value = result.total;
      } else if (_filter.value == 'Queued') {
        _queuedCount.value = result.total;
      }
      await _refreshFilterCounts(superAdmin: auth.isSuperAdmin);
    } catch (e) {
      _error.value = _parseError(e);
      if (showErrorSnackbar) {
        showCmsSnackbar(
          title: 'Error',
          message: 'Failed to load pujas: ${_error.value}',
          isError: true,
        );
      }
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _refreshFilterCounts({required bool superAdmin}) async {
    try {
      final futures = <Future<void>>[];
      if (_filter.value != 'Pending') {
        futures.add(
          _dataSource
              .getPoojasPage(
                superAdmin: superAdmin,
                page: 1,
                limit: 1,
                status: 'PENDING',
              )
              .then((r) => _pendingCount.value = r.total),
        );
      }
      if (_filter.value != 'Queued') {
        futures.add(
          _dataSource
              .getPoojasPage(
                superAdmin: superAdmin,
                page: 1,
                limit: 1,
                status: 'QUEUED',
              )
              .then((r) => _queuedCount.value = r.total),
        );
      }
      await Future.wait(futures);
    } catch (_) {}
  }

  /// Fetch all created poojas across all pages for dropdowns/selectors
  Future<List<PoojaModel>> fetchAllPoojasForSelector() async {
    try {
      final auth = Get.find<AuthController>();
      return await _dataSource.getAllPoojasForSelector(
        superAdmin: auth.isSuperAdmin,
      );
    } catch (_) {
      return _poojas.toList();
    }
  }

  /// Approved pujas only — used when associating pujas on a deity.
  Future<List<PoojaModel>> fetchApprovedPoojasForSelector() async {
    try {
      final auth = Get.find<AuthController>();
      return await _dataSource.getAllPoojasForSelector(
        superAdmin: auth.isSuperAdmin,
        status: 'APPROVED',
      );
    } catch (_) {
      return _poojas
          .where((p) => p.status.toUpperCase() == 'APPROVED' || p.status == 'Approved')
          .toList();
    }
  }

  /// Load ALL poojas across all statuses — used by super admin Approvals tab.
  /// Uses GET /poojas/all which requires super admin role.
  Future<void> loadAllPoojas() async {
    _isLoading.value = true;
    _error.value = null;
    try {
      final result = await _dataSource.getAllPoojasSuperAdmin();
      _poojas.assignAll(result);
    } catch (e) {
      _error.value = _parseError(e);
      showCmsSnackbar(
        title: 'Error',
        message: 'Failed to load pujas: ${_error.value}',
        isError: true,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> loadDeities() async {
    if (_isLoadingDeities.value) return;
    _isLoadingDeities.value = true;
    try {
      final result = await _dataSource.getDeities(status: 'APPROVED');
      _deities.assignAll(result);
    } catch (_) {
      _deities.clear();
    } finally {
      _isLoadingDeities.value = false;
      _deitiesLoaded.value = true;
    }
  }

  // ── Create pooja ─────────────────────────────────────────────
  Future<bool> createPooja({
    required String title,
    PickedFile? pickedImage,
    PickedFile? pickedAudio,
    PickedFile? pickedVideo,
    required List<String> deities,
    required String category,
    required String difficulty,
    required String duration,
    required String description,
    required List<String> steps,
    required List<String> requiredItems,
    String? purposeWhy,
    List<String> purposeBenefits = const [],
    String? deitySummaryAbout,
    List<String> deitySummaryBlessings = const [],
    List<String> preparationPersonal = const [],
    List<String> preparationSpace = const [],
    List<String> preparationItems = const [],
    String? mantraPrimary,
    String? mantraRepetitions,
    List<String> mantraAdditional = const [],
    String? mantraMeaning,
    List<Map<String, String>> spiritualOfferingsMeaning = const [],
    List<Map<String, String>> spiritualActionsMeaning = const [],
    List<Map<String, String>> spiritualOtherSymbolism = const [],
    List<String> guidanceMindset = const [],
    List<String> guidanceAvoid = const [],
    List<String> completionClosure = const [],
    List<String> completionIntegration = const [],
    List<String> completionBenefits = const [],
    List<String> blessings = const [],
    List<String> festivalIds = const [],
    String? poojaDate,
    String? imageUrl,
    String? audioUrl,
    String? videoUrl,
    String? date,
    List<String> idealTime = const [],
    List<Map<String, String>> schedules = const [],
    bool daily = false,
    String status = 'Pending',
    List<List<PickedFile>> stepImagesByStep = const [],
  }) async {
    _isSubmitting.value = true;
    _error.value = null;
    try {
      final pooja = PoojaModel(
        id: '',
        title: title,
        deities: deities,
        category: category,
        difficulty: difficulty,
        duration: duration,
        description: description,
        status: status,
        date: date,
        schedules: schedules,
        daily: daily,
        idealTime: idealTime,
        imageUrl: imageUrl,
        audioUrl: audioUrl,
        videoUrl: videoUrl,
        steps: steps,
        requiredItems: requiredItems,
        purposeWhy: purposeWhy,
        purposeBenefits: purposeBenefits,
        deitySummaryAbout: deitySummaryAbout,
        deitySummaryBlessings: deitySummaryBlessings,
        preparationPersonal: preparationPersonal,
        preparationSpace: preparationSpace,
        preparationItems: preparationItems,
        mantraPrimary: mantraPrimary,
        mantraRepetitions: mantraRepetitions,
        mantraAdditional: mantraAdditional,
        mantraMeaning: mantraMeaning,
        spiritualOfferingsMeaning: spiritualOfferingsMeaning,
        spiritualActionsMeaning: spiritualActionsMeaning,
        spiritualOtherSymbolism: spiritualOtherSymbolism,
        guidanceMindset: guidanceMindset,
        guidanceAvoid: guidanceAvoid,
        completionClosure: completionClosure,
        completionIntegration: completionIntegration,
        completionBenefits: completionBenefits,
        blessings: blessings,
        festivalIds: festivalIds,
        poojaDate: poojaDate,
      );
      final created = await _dataSource.createPooja(
        pooja,
        image: pickedImage,
        audio: pickedAudio,
        video: pickedVideo,
        stepImagesByStep: stepImagesByStep,
      );
      // Insert into current list only if it belongs here.
      // For 'All': include everything except Rejected.
      final matchesAll = _filter.value == 'All' && created.status != 'Rejected';
      final matchesFilter = _filter.value == created.status;
      if (matchesAll || matchesFilter) {
        _poojas.insert(0, created);
      }
      _snackOk('Pooja submitted successfully');
      return true;
    } catch (e) {
      _error.value = _parseError(e);
      showCmsSnackbar(
        title: 'Error',
        message: 'Failed to create puja: ${_error.value}',
        isError: true,
      );
      return false;
    } finally {
      _isSubmitting.value = false;
    }
  }

  // ── Update pooja ─────────────────────────────────────────────
  Future<bool> updatePooja(
    String id,
    PoojaModel updated, {
    PickedFile? pickedImage,
    PickedFile? pickedAudio,
    PickedFile? pickedVideo,
    List<List<PickedFile>> stepImagesByStep = const [],
  }) async {
    _isSubmitting.value = true;
    _error.value = null;
    try {
      final result = await _dataSource.updatePooja(
        id,
        updated,
        image: pickedImage,
        audio: pickedAudio,
        video: pickedVideo,
        stepImagesByStep: stepImagesByStep,
      );
      final index = _poojas.indexWhere((p) => p.id == id);
      if (index != -1) {
        // If status changed and no longer matches filter, drop it
        if (_filter.value != 'All' && result.status != _filter.value) {
          _poojas.removeAt(index);
        } else {
          _poojas[index] = result;
        }
      }
      _snackOk('Puja updated successfully');
      return true;
    } catch (e) {
      _error.value = _parseError(e);
      showCmsSnackbar(
        title: 'Error',
        message: 'Failed to update puja: ${_error.value}',
        isError: true,
      );
      return false;
    } finally {
      _isSubmitting.value = false;
    }
  }

  // ── Delete pooja ─────────────────────────────────────────────
  Future<bool> deletePooja(String id) async {
    try {
      await _dataSource.deletePooja(id);
      _poojas.removeWhere((p) => p.id == id);
      _snackOk('Pooja deleted successfully');
      return true;
    } catch (e) {
      _error.value = _parseError(e);
      showCmsSnackbar(
        title: 'Error',
        message: 'Failed to delete puja: ${_error.value}',
        isError: true,
      );
      return false;
    }
  }

  // ── Approve pooja (superadmin) ───────────────────────────────
  Future<bool> approvePooja(String id) async {
    try {
      await _dataSource.approvePooja(id);
      _snackOk('Pooja approved and published');
      await loadPoojas(); // reload fresh from server
      return true;
    } catch (e) {
      _error.value = _parseError(e);
      showCmsSnackbar(
        title: 'Error',
        message: 'Failed to approve puja: ${_error.value}',
        isError: true,
      );
      return false;
    }
  }

  Future<bool> queuePooja(String id) async {
    try {
      await _dataSource.reviewPooja(id, 'QUEUED');
      _snackOk('Pooja moved to queue');
      await loadPoojas();
      return true;
    } catch (e) {
      _error.value = _parseError(e);
      showCmsSnackbar(
        title: 'Error',
        message: 'Failed to queue puja: ${_error.value}',
        isError: true,
      );
      return false;
    }
  }

  // ── Reject pooja (superadmin) ────────────────────────────────
  Future<bool> rejectPooja(String id, String reason) async {
    try {
      await _dataSource.rejectPooja(id, reason);
      showCmsSnackbar(title: 'Rejected', message: 'Pooja has been rejected');
      await loadPoojas(); // reload fresh from server
      return true;
    } catch (e) {
      _error.value = _parseError(e);
      showCmsSnackbar(
        title: 'Error',
        message: 'Failed to reject puja: ${_error.value}',
        isError: true,
      );
      return false;
    }
  }

  // ── Helpers ──────────────────────────────────────────────────
  void _snackOk(String msg) => showCmsSnackbar(title: 'Success', message: msg);

  String _parseError(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
      if (e.type == DioExceptionType.connectionTimeout)
        return 'Connection timeout';
      if (e.response?.statusCode == 400) return 'Invalid data (400)';
    }

    final msg = e.toString();
    if (msg.contains('404')) return 'Pooja not found.';
    if (msg.contains('401') || msg.contains('403')) return 'Not authorised.';
    if (msg.contains('500')) return 'Server error. Please try again.';
    if (msg.contains('SocketException') || msg.contains('connection')) {
      return 'No internet connection.';
    }
    return 'Something went wrong. Please try again.';
  }
}
