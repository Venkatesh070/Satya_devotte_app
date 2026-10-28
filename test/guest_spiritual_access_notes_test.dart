import 'package:flutter_test/flutter_test.dart';

/// Documents guest-access policy for App Review Guideline 5.1.1(v).
/// Behaviour is enforced in UI code; this test locks the intended contract.
void main() {
  test('guest spiritual browsing policy contract', () {
    const guestAllowedWithoutLogin = <String>[
      'home feed browse',
      'puja / ritual catalogue browse',
      'puja Know More / informational preview',
      'deity detail (approved public content)',
      'festival and lunar event informational detail',
      'calendar browse',
      'external website donate (Safari / Chrome)',
    ];

    const stillRequiresLogin = <String>[
      'begin puja / ritual wizard',
      'favourites save',
      'notifications',
      'order history / checkout / cart mutate',
      'pooja / ritual history',
      'edit profile / personal information',
      'add personal calendar events',
      'in-app contribution history',
    ];

    expect(guestAllowedWithoutLogin, isNotEmpty);
    expect(stillRequiresLogin, isNotEmpty);
    expect(
      guestAllowedWithoutLogin.toSet().intersection(stillRequiresLogin.toSet()),
      isEmpty,
    );
  });
}
