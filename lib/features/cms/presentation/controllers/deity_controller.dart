import 'package:get/get.dart';
import 'package:satya_devotte_app/features/cms/data/datasources/deity_remote_datasource.dart';
import 'package:satya_devotte_app/features/cms/models/deity_model.dart';

class DeityController extends GetxController {
  DeityController(this._dataSource);
  final DeityRemoteDataSource _dataSource;

  final _deities = <DeityModel>[].obs;
  final _isLoading = false.obs;
  final _isSubmitting = false.obs;
  final _error = RxnString();
  bool _loadInFlight = false;
  DateTime? _lastLoadedAt;
  String? _lastStatus;
  int? _lastPage;
  int? _lastLimit;

  List<DeityModel> get deities => _deities;
  bool get isLoading => _isLoading.value;
  bool get isSubmitting => _isSubmitting.value;
  String? get error => _error.value;

  Future<void> loadDeities({
    int page = 1,
    int limit = 10,
    String? status,
  }) async {
    if (_loadInFlight) return;
    final now = DateTime.now();
    final sameQuery =
        _lastStatus == status && _lastPage == page && _lastLimit == limit;
    if (sameQuery &&
        _lastLoadedAt != null &&
        now.difference(_lastLoadedAt!).inSeconds < 15) {
      return;
    }
    _loadInFlight = true;
    _isLoading.value = true;
    _error.value = null;
    try {
      final result = await _dataSource.getDeities(
        page: page,
        limit: limit,
        status: status,
      );
      _deities.assignAll(result);
      _lastLoadedAt = DateTime.now();
      _lastStatus = status;
      _lastPage = page;
      _lastLimit = limit;
    } catch (_) {
      _error.value = 'Failed to load deities';
    } finally {
      _isLoading.value = false;
      _loadInFlight = false;
    }
  }

  Future<bool> createDeity(Map<String, dynamic> payload) async {
    _isSubmitting.value = true;
    _error.value = null;
    try {
      await _dataSource.createDeity(payload);
      return true;
    } catch (_) {
      _error.value = 'Failed to create deity';
      return false;
    } finally {
      _isSubmitting.value = false;
    }
  }

  Future<bool> approveDeity(String id) async {
    try {
      await _dataSource.approveDeity(id);
      await loadDeities();
      return true;
    } catch (_) {
      _error.value = 'Failed to approve deity';
      return false;
    }
  }

  Future<bool> queueDeity(String id) async {
    try {
      await _dataSource.reviewDeity(id, 'QUEUED');
      await loadDeities();
      return true;
    } catch (_) {
      _error.value = 'Failed to queue deity';
      return false;
    }
  }

  Future<bool> rejectDeity(String id) async {
    try {
      await _dataSource.rejectDeity(id);
      await loadDeities();
      return true;
    } catch (_) {
      _error.value = 'Failed to reject deity';
      return false;
    }
  }
}
