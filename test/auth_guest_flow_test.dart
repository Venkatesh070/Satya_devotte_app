import 'package:flutter_test/flutter_test.dart';
import 'package:satya_devotte_app/core/services/auth_session_service.dart';
import 'package:satya_devotte_app/features/profile/presentation/controllers/profile_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
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
  });
}
