class FirebaseService {
  final Stream<bool> authStateChanges = const Stream<bool>.empty();

  Future<void> signInWithGoogle() async {}

  Future<void> signInWithApple() async {}

  Future<void> signInWithOtp({
    required String verificationId,
    required String smsCode,
  }) async {}

  Future<void> signOut() async {}
}
