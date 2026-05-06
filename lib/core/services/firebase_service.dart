import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseService {
  static const String _defaultWebGoogleClientId =
      '1053803605697-a4fp6shgdolcbrmag6iteadjaf1du6ug.apps.googleusercontent.com';

  FirebaseService({FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
      _googleSignIn =
          googleSignIn ??
          (kIsWeb
              ? GoogleSignIn(
                  clientId: const String.fromEnvironment(
                    'GOOGLE_WEB_CLIENT_ID',
                    defaultValue: _defaultWebGoogleClientId,
                  ),
                )
              : GoogleSignIn());

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  Stream<bool> get authStateChanges =>
      _firebaseAuth.authStateChanges().map((user) => user != null);

  Future<void> signInWithGoogle() async {
    // On web, force signOut/disconnect right before signIn can destabilize
    // popup flow and increase popup_closed errors.
    if (!kIsWeb) {
      try {
        await _googleSignIn.signOut();
        await _googleSignIn.disconnect();
      } catch (_) {}
    }

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

  Map<String, dynamic>? getCurrentUserProfileDetails() {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;

    final fullName = (user.displayName ?? '').trim();
    final nameParts = fullName.isEmpty
        ? const <String>[]
        : fullName.split(RegExp(r'\s+'));
    final firstName = nameParts.isEmpty ? '' : nameParts.first;
    final lastName = nameParts.length <= 1 ? '' : nameParts.sublist(1).join(' ');
    final providerIds = user.providerData
        .map((p) => p.providerId)
        .where((p) => p.trim().isNotEmpty)
        .toList();

    return <String, dynamic>{
      'firebaseUid': user.uid,
      'email': user.email ?? '',
      'fullName': fullName,
      'firstName': firstName,
      'lastName': lastName,
      'gender': null, // Not reliably available from Firebase auth profile.
      'photoUrl': user.photoURL ?? '',
      'phoneNumber': user.phoneNumber ?? '',
      'emailVerified': user.emailVerified,
      'providers': providerIds,
    };
  }

  Future<void> signInWithApple() async {}

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim();
    // Pre-check providers so Google-only accounts don't first trigger a
    // failed signInWithPassword call on web.
    final methods = await _firebaseAuth.fetchSignInMethodsForEmail(
      normalizedEmail,
    );
    final isGoogleOnly =
        methods.contains('google.com') && !methods.contains('password');
    if (isGoogleOnly) {
      await _signInWithGoogleAndLinkEmailPassword(
        email: normalizedEmail,
        password: password,
      );
      return;
    }

    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      return;
    } on FirebaseAuthException catch (e) {
      // If the account is Google-only, allow linking email/password on-the-fly.
      final canAttemptLink =
          e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential';
      if (!canAttemptLink) rethrow;

      final fallbackMethods = await _firebaseAuth.fetchSignInMethodsForEmail(
        normalizedEmail,
      );
      // Some Firebase projects return empty methods depending on account
      // enumeration protection settings. In that case, still try Google flow.
      final hasGoogleProvider = fallbackMethods.contains('google.com');
      final hasPasswordProvider = fallbackMethods.contains('password');
      if (!hasGoogleProvider && hasPasswordProvider) rethrow;

      await _signInWithGoogleAndLinkEmailPassword(
        email: normalizedEmail,
        password: password,
      );
    }
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

  Future<void> _signInWithGoogleAndLinkEmailPassword({
    required String email,
    required String password,
  }) async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'google-sign-in-cancelled',
        message: 'Google sign in was cancelled by user.',
      );
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    final user = userCredential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Unable to resolve Google user for linking.',
      );
    }

    final signedInEmail = (user.email ?? '').trim().toLowerCase();
    if (signedInEmail.isEmpty || signedInEmail != email.toLowerCase()) {
      throw FirebaseAuthException(
        code: 'google-account-mismatch',
        message: 'Signed-in Google account does not match entered email.',
      );
    }

    final emailCredential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    try {
      await user.linkWithCredential(emailCredential);
    } on FirebaseAuthException catch (e) {
      if (e.code != 'provider-already-linked' &&
          e.code != 'credential-already-in-use' &&
          e.code != 'email-already-in-use') {
        rethrow;
      }
    }
  }
}
