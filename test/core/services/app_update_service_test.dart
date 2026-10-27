import 'package:flutter_test/flutter_test.dart';
import 'package:satya_devotte_app/core/services/app_update_service.dart';

void main() {
  group('AppUpdateService.isVersionNewer', () {
    test('returns true when store patch version is higher', () {
      expect(AppUpdateService.isVersionNewer('1.0.0', '1.0.1'), isTrue);
    });

    test('returns true when store minor version is higher', () {
      expect(AppUpdateService.isVersionNewer('1.0.9', '1.1.0'), isTrue);
    });

    test('returns true when store major version is higher', () {
      expect(AppUpdateService.isVersionNewer('1.9.9', '2.0.0'), isTrue);
    });

    test('returns false when versions are identical', () {
      expect(AppUpdateService.isVersionNewer('1.0.0', '1.0.0'), isFalse);
      expect(AppUpdateService.isVersionNewer('1.0.0+24', '1.0.0+24'), isFalse);
    });

    test('returns false when store version is older', () {
      expect(AppUpdateService.isVersionNewer('1.0.1', '1.0.0'), isFalse);
      expect(AppUpdateService.isVersionNewer('2.0.0', '1.9.9'), isFalse);
    });

    test('handles build numbers with same version', () {
      expect(AppUpdateService.isVersionNewer('1.0.0+23', '1.0.0+24'), isTrue);
      expect(AppUpdateService.isVersionNewer('1.0.0+25', '1.0.0+24'), isFalse);
    });

    test('handles two-part versions (e.g. 1.2 vs 1.2.1)', () {
      expect(AppUpdateService.isVersionNewer('1.2', '1.2.1'), isTrue);
      expect(AppUpdateService.isVersionNewer('1.2.1', '1.2'), isFalse);
    });

    test('handles empty or malformed strings gracefully', () {
      expect(AppUpdateService.isVersionNewer('1.0.0', ''), isFalse);
      expect(AppUpdateService.isVersionNewer('', '1.0.0'), isTrue);
    });
  });
}
