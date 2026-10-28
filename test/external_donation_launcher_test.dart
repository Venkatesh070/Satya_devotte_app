import 'package:flutter_test/flutter_test.dart';
import 'package:satya_devotte_app/core/services/external_donation_launcher.dart';

void main() {
  group('ExternalDonationLauncher', () {
    test('default donation URL is HTTPS on sathya.co.za', () {
      final uri = Uri.parse(ExternalDonationLauncher.donationPageUrl);
      expect(uri.scheme, 'https');
      expect(uri.host, anyOf('www.sathya.co.za', 'sathya.co.za'));
      expect(uri.fragment, contains('donate'));
    });

    test('validateDonationUrl accepts canonical donate URL', () {
      expect(
        ExternalDonationLauncher.validateDonationUrl(
          'https://www.sathya.co.za/#/donate',
        ),
        isNull,
      );
    });

    test('validateDonationUrl rejects http and foreign hosts', () {
      expect(
        ExternalDonationLauncher.validateDonationUrl(
          'http://www.sathya.co.za/#/donate',
        ),
        isNotNull,
      );
      expect(
        ExternalDonationLauncher.validateDonationUrl(
          'https://evil.example/#/donate',
        ),
        isNotNull,
      );
    });

    test('fragment /donate is accepted on www host', () {
      expect(
        ExternalDonationLauncher.validateDonationUrl(
          ExternalDonationLauncher.donationPageUrl,
        ),
        isNull,
      );
    });

    test('buildDonationPageUrl appends donor query on hash route', () {
      final url = ExternalDonationLauncher.buildDonationPageUrl(
        email: 'ada@example.com',
        nameFirst: 'Ada',
        nameLast: 'Lovelace',
      );
      expect(url.startsWith('https://www.sathya.co.za/#/donate?'), isTrue);
      expect(url, contains('email=ada%40example.com'));
      expect(url, contains('nameFirst=Ada'));
      expect(url, contains('nameLast=Lovelace'));
      expect(
        ExternalDonationLauncher.validateDonationUrl(url),
        isNull,
      );
    });

    test('buildDonationPageUrl omits empty donor fields', () {
      expect(
        ExternalDonationLauncher.buildDonationPageUrl(),
        ExternalDonationLauncher.donationPageUrl,
      );
    });
  });
}
