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
    bool force = false,
  }) async {
    if (_loadInFlight) return;
    final now = DateTime.now();
    final sameQuery =
        _lastStatus == status && _lastPage == page && _lastLimit == limit;
    if (!force &&
        sameQuery &&
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
