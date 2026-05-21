import 'package:get/get.dart';

/// Tracks in-flight HTTP requests for the global chakra loader overlay.
class ApiLoadingService extends GetxService {
  final _activeRequests = 0.obs;

  bool get isLoading => _activeRequests.value > 0;

  void onRequestStarted() {
    _activeRequests.value++;
  }

  void onRequestFinished() {
    if (_activeRequests.value > 0) {
      _activeRequests.value--;
    }
  }
}
