import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService({FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;

  Future<void> sendPasswordResetEmail(String email) async {
    final normalizedEmail = email.trim().toLowerCase();

    try {
      final methods = await _firebaseAuth.fetchSignInMethodsForEmail(
        normalizedEmail,
      );

      if (methods.contains('google.com') && !methods.contains('password')) {
        throw FirebaseAuthException(
          code: 'google-sign-in-only',
          message: 'This account uses Google Sign-In',
        );
      }
      if (methods.contains('apple.com') && !methods.contains('password')) {
        throw FirebaseAuthException(
          code: 'apple-sign-in-only',
          message: 'This account uses Apple Sign-In',
        );
      }
      if (!methods.contains('password')) {
        // When methods is empty/limited due Firebase project settings
        // (e.g. Email Enumeration Protection), do not hard-fail here.
        // We'll attempt sendPasswordResetEmail and rely on Firebase's
        // explicit exception if truly invalid.
        if (methods.isNotEmpty) {
          throw FirebaseAuthException(
            code: 'password-provider-not-enabled',
            message: 'This account is not registered with email/password.',
          );
        }
      }

      await _firebaseAuth.sendPasswordResetEmail(email: normalizedEmail);
    } on FirebaseAuthException {
      rethrow;
    } catch (_) {
      throw Exception('Unable to send reset link. Please try again.');
    }
  }
}
