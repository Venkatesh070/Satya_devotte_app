import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/core/services/auth_session_service.dart';
import 'package:satya_devotte_app/core/services/firebase_service.dart';
import 'package:satya_devotte_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:satya_devotte_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:satya_devotte_app/features/profile/presentation/controllers/profile_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeUser extends Fake implements User {
  @override
  String get uid => 'fake-uid-123';
}

class FakeFirebaseService extends Fake implements FirebaseService {
  FakeFirebaseService({this.mockUser});

  final User? mockUser;
  final _authStateStreamController = StreamController<bool>.broadcast();
  bool signOutCalled = false;

  @override
  Stream<bool> get authStateChanges => _authStateStreamController.stream;

  @override
  User? get currentUser => mockUser;

  @override
  Future<void> signOut() async {
    signOutCalled = true;
  }

  void emitAuthState(bool state) {
    _authStateStreamController.add(state);
  }
}

class FakeAuthRepository extends Fake implements AuthRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Get.reset();
    Get.testMode = true;
  });

  group('Guest session and profile isolation', () {
    test('displayNameFromUserMap defaults to Guest User when null or empty', () {
      expect(ProfileController.displayNameFromUserMap(null), 'Guest User');
      expect(ProfileController.displayNameFromUserMap({}), 'Guest User');
    });

    test('AuthSessionService clear removes stored session tokens and user data', () async {
      final sessionService = AuthSessionService();
      await sessionService.setSession(
        accessToken: 'mock-token',
        refreshToken: 'mock-refresh',
        userData: {'fullName': 'Google Devotee', 'email': 'devotee@gmail.com'},
      );

      expect(sessionService.accessToken, 'mock-token');
      expect(sessionService.userData?['fullName'], 'Google Devotee');

      await sessionService.clear();

      expect(sessionService.accessToken, isNull);
      expect(sessionService.refreshToken, isNull);
      expect(sessionService.userData, isNull);

      final reloadedUserData = await sessionService.getUserData();
      expect(reloadedUserData, isNull);
    });

    test('isRegistered flag is correctly identified for profile registration state', () async {
      final sessionService = AuthSessionService();

      // New Google user who has not completed profile setup
      await sessionService.setSession(
        accessToken: 'mock-token',
        refreshToken: 'mock-refresh',
        userData: {'fullName': 'New Google User', 'email': 'new@gmail.com', 'isRegistered': false},
      );
      expect(sessionService.userData?['isRegistered'], false);

      // Existing devotee who has completed profile
      await sessionService.setSession(
        accessToken: 'mock-token',
        refreshToken: 'mock-refresh',
        userData: {'fullName': 'Existing Devotee', 'email': 'devotee@gmail.com', 'isRegistered': true},
      );
      expect(sessionService.userData?['isRegistered'], true);
    });

    test('AuthController treats user as guest when backend accessToken is missing even if Firebase is active', () async {
      final fakeFirebase = FakeFirebaseService();
      final fakeRepo = FakeAuthRepository();
      final sessionService = AuthSessionService();

      final controller = AuthController(fakeFirebase, fakeRepo, sessionService);
      controller.onInit();

      // Initially no backend session
      expect(controller.isAuthenticated, false);
      expect(controller.isGuest, true);

      // Simulate Firebase emitting authenticated state (e.g. from Keychain) without backend session
      fakeFirebase.emitAuthState(true);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Must remain guest because accessToken is null
      expect(controller.isAuthenticated, false);
      expect(controller.isGuest, true);

      // Now establish valid backend session and simulate auth state
      await sessionService.setSession(
        accessToken: 'valid-jwt-token',
        refreshToken: 'valid-refresh-token',
        userData: {'fullName': 'Verified Devotee'},
      );
      fakeFirebase.emitAuthState(true);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(controller.isAuthenticated, true);
      expect(controller.isGuest, false);
    });

    test('loadSavedSession cleans up orphan Firebase session when local session storage is empty', () async {
      final fakeUser = FakeUser();
      final fakeFirebase = FakeFirebaseService(mockUser: fakeUser);
      final fakeRepo = FakeAuthRepository();
      final sessionService = AuthSessionService();

      final controller = AuthController(fakeFirebase, fakeRepo, sessionService);

      // Trigger session load on empty preferences with orphan Firebase user
      await controller.loadSavedSession();

      expect(controller.isAuthenticated, false);
      expect(controller.isGuest, true);
      expect(fakeFirebase.signOutCalled, true);
    });

    test('Onboarding tracking: defaults to false on first install, persists on continueAsGuest', () async {
      final sessionService = AuthSessionService();

      // First install: empty preferences
      expect(await sessionService.checkHasSeenOnboarding(), false);
      expect(sessionService.hasSeenOnboarding, false);

      final fakeFirebase = FakeFirebaseService();
      final fakeRepo = FakeAuthRepository();
      final controller = AuthController(fakeFirebase, fakeRepo, sessionService);

      // User picks continueAsGuest
      await controller.continueAsGuest();

      expect(sessionService.hasSeenOnboarding, true);
      expect(await sessionService.checkHasSeenOnboarding(), true);
    });
  });
}

