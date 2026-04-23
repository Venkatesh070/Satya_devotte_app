import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseService {
  FirebaseService({FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
      _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  Stream<bool> get authStateChanges =>
      _firebaseAuth.authStateChanges().map((user) => user != null);

  Future<void> signInWithGoogle() async {
    try {
      await _googleSignIn.signOut();
      await _googleSignIn.disconnect();
    } catch (_) {}

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw FirebaseAuthException(
          code: 'google-sign-in-cancelled',
          message: 'Google sign in was cancelled by user.',
        );
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _firebaseAuth
          .signInWithCredential(credential);

      // ======= DEBUG: Print all user data =======
      final User? user = userCredential.user;
      if (user != null) {
        print("======= GOOGLE SIGN IN SUCCESS =======");
        print("UID:            ${user.uid}");
        print("Name:           ${user.displayName}");
        print("Email:          ${user.email}");
        print("Phone:          ${user.phoneNumber}");
        print("Photo URL:      ${user.photoURL}");
        print("Email Verified: ${user.emailVerified}");
        print(
          "Is New User:    ${userCredential.additionalUserInfo?.isNewUser}",
        );
        print(
          "Provider ID:    ${userCredential.additionalUserInfo?.providerId}",
        );
        print("Profile Data:   ${userCredential.additionalUserInfo?.profile}");
        print("Access Token:   ${googleAuth.accessToken}");
        print("ID Token:       ${googleAuth.idToken}");
        print("======================================");
      }
      // ==========================================
    } catch (error) {
      try {
        await _googleSignIn.signOut();
        await _googleSignIn.disconnect();
      } catch (_) {}
      rethrow;
    }
  }

  Future<String?> getIdToken({bool forceRefresh = false}) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      return null;
    }
    return user.getIdToken(forceRefresh);
  }

  Future<void> signInWithApple() async {}

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signInWithOtp({
    required String verificationId,
    required String smsCode,
  }) async {}

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    // On Flutter Web, calling _googleSignIn.signOut() when the user did not
    // sign in with Google (e.g. email/password login) causes google_sign_in_web
    // to throw because it tries to re-initialize without a client ID in index.html.
    // Only call it when a Google account is actually signed in.
    try {
      if (_googleSignIn.currentUser != null) {
        await _googleSignIn.signOut();
      }
    } catch (_) {
      // Best-effort — never block logout over a Google sign-out failure.
    }
  }
}
