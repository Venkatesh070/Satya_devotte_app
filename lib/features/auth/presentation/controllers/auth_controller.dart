import 'package:get/get.dart';
import 'package:satya_devotte_app/core/services/firebase_service.dart';

class AuthController extends GetxController {
  AuthController(this._firebaseService);
  final FirebaseService _firebaseService;

  final _isAuthenticated = false.obs;

  bool get isAuthenticated => _isAuthenticated.value;

  @override
  void onInit() {
    super.onInit();
    _firebaseService.authStateChanges.listen((state) {
      _isAuthenticated.value = state;
    });
  }

  Future<void> signInWithGoogle() async {
    await _firebaseService.signInWithGoogle();
    _isAuthenticated.value = true;
  }

  Future<void> signOut() async {
    await _firebaseService.signOut();
    _isAuthenticated.value = false;
  }
}
