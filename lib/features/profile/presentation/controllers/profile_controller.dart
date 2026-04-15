import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/core/services/auth_session_service.dart';
import 'package:satya_devotte_app/features/profile/domain/repositories/profile_repository.dart';

class ProfileController extends GetxController {
  ProfileController(this._profileRepository, this._authSessionService);

  final ProfileRepository _profileRepository;
  final AuthSessionService _authSessionService;

  final _isLoading = false.obs;
  final _profile = Rxn<Map<String, dynamic>>();
  final _error = RxnString();
  final _sessionUser = Rxn<Map<String, dynamic>>();

  bool get isLoading => _isLoading.value;
  Map<String, dynamic>? get profile => _profile.value;
  String? get error => _error.value;
  Map<String, dynamic>? get sessionUser => _sessionUser.value;

  @override
  void onInit() {
    super.onInit();
    loadSessionUser();
    loadProfile();
  }

  Future<void> loadSessionUser() async {
    final user = await _authSessionService.getUserData();
    _sessionUser.value = user;
  }

  Future<void> loadProfile() async {
    _isLoading.value = true;
    _error.value = null;
    try {
      final data = await _profileRepository.getProfile();
      _profile.value = data;
    } catch (error) {
      if (error is DioException && error.response?.statusCode == 401) {
        _error.value = 'Session expired. Please login again.';
      } else {
        _error.value = 'Failed to load profile.';
      }
    } finally {
      _isLoading.value = false;
    }
  }
}
