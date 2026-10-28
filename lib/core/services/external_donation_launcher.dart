import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:satya_devotte_app/config/env/app_env.dart';
import 'package:satya_devotte_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:satya_devotte_app/features/profile/presentation/controllers/profile_controller.dart';

/// Opens the public Sathya website donation page in the system browser.
///
/// Used for App Store Guideline 3.2.2(iv): donations are not processed inside
/// the app. PayFast checkout happens on the website / PayFast hosted pages.
class ExternalDonationLauncher {
  ExternalDonationLauncher._();

  /// Override with `--dart-define=DONATION_WEBSITE_URL=https://www.sathya.co.za/#/donate`
  static const String _configuredUrl = String.fromEnvironment(
    'DONATION_WEBSITE_URL',
    defaultValue: '',
  );

  static const String _defaultProdUrl = 'https://www.sathya.co.za/#/donate';

  static const Set<String> _allowedHosts = {
    'www.sathya.co.za',
    'sathya.co.za',
  };

  static String get donationPageUrl {
    final raw = _configuredUrl.trim().isNotEmpty
        ? _configuredUrl.trim()
        : _defaultProdUrl;
    return raw;
  }

  /// Prefill query keys understood by the landing `/donate` page.
  static String buildDonationPageUrl({
    String? email,
    String? nameFirst,
    String? nameLast,
  }) {
    final base = donationPageUrl;
    final params = <String, String>{};
    final e = email?.trim() ?? '';
    final first = nameFirst?.trim() ?? '';
    final last = nameLast?.trim() ?? '';
    if (e.isNotEmpty) params['email'] = e;
    if (first.isNotEmpty) params['nameFirst'] = first;
    if (last.isNotEmpty) params['nameLast'] = last;
    if (params.isEmpty) return base;

    final query = params.entries
        .map(
          (entry) =>
              '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value)}',
        )
        .join('&');

    if (base.contains('#')) {
      final origin = base.substring(0, base.indexOf('#'));
      var hashRoute = base.substring(base.indexOf('#') + 1);
      if (hashRoute.isEmpty) hashRoute = '/donate';
      if (!hashRoute.startsWith('/')) hashRoute = '/$hashRoute';
      final pathOnly = hashRoute.split('?').first;
      return '$origin#$pathOnly?$query';
    }

    final uri = Uri.parse(base);
    return uri.replace(queryParameters: {
      ...uri.queryParameters,
      ...params,
    }).toString();
  }

  /// Pulls email / name from the signed-in session when available.
  static ({String? email, String? nameFirst, String? nameLast})
      donorDetailsFromAppSession() {
    if (!Get.isRegistered<AuthController>()) {
      return (email: null, nameFirst: null, nameLast: null);
    }
    final auth = Get.find<AuthController>();
    if (auth.isGuest) {
      return (email: null, nameFirst: null, nameLast: null);
    }

    Map<String, dynamic>? user = auth.sessionUser;
    if (Get.isRegistered<ProfileController>()) {
      final profileUser = Get.find<ProfileController>().resolvedUser;
      if (profileUser != null && profileUser.isNotEmpty) {
        user = {...?user, ...profileUser};
      }
    }

    final email = user?['email']?.toString().trim();
    final firstName = user?['firstName']?.toString().trim();
    final lastName = user?['lastName']?.toString().trim();

    if ((firstName != null && firstName.isNotEmpty) ||
        (lastName != null && lastName.isNotEmpty)) {
      return (
        email: (email != null && email.isNotEmpty) ? email : null,
        nameFirst: (firstName != null && firstName.isNotEmpty) ? firstName : null,
        nameLast: (lastName != null && lastName.isNotEmpty) ? lastName : null,
      );
    }

    final fullName = ProfileController.displayNameFromUserMap(user).trim();
    if (fullName.isEmpty ||
        fullName == 'User' ||
        fullName == 'Guest User' ||
        fullName == 'Devotee') {
      return (
        email: (email != null && email.isNotEmpty) ? email : null,
        nameFirst: null,
        nameLast: null,
      );
    }

    final parts = fullName.split(RegExp(r'\s+'));
    return (
      email: (email != null && email.isNotEmpty) ? email : null,
      nameFirst: parts.isNotEmpty ? parts.first : null,
      nameLast: parts.length > 1 ? parts.sublist(1).join(' ') : null,
    );
  }

  static bool _isLocalDevHost(String host) {
    final h = host.toLowerCase();
    if (h == 'localhost' || h == '127.0.0.1' || h == '10.0.2.2') {
      return true;
    }
    // Private LAN used when testing from a physical device.
    if (h.startsWith('192.168.') || h.startsWith('10.')) return true;
    final m = RegExp(r'^172\.(1[6-9]|2\d|3[0-1])\.').firstMatch(h);
    return m != null;
  }

  /// Returns null when the URL is safe to open; otherwise an error message.
  static String? validateDonationUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return 'Donation link is invalid.';

    final host = uri.host.toLowerCase();
    final scheme = uri.scheme.toLowerCase();
    final localDev = !AppEnv.isProduction && _isLocalDevHost(host);

    if (localDev) {
      if (scheme != 'http' && scheme != 'https') {
        return 'Donation link must use HTTP(S).';
      }
    } else {
      if (scheme != 'https') {
        return 'Donation link must use HTTPS.';
      }
      if (!_allowedHosts.contains(host)) {
        return 'Donation link is not on the Sathya website.';
      }
    }

    final pathAndFragment = '${uri.path}#${uri.fragment}'.toLowerCase();
    final looksLikeDonate = pathAndFragment.contains('donate') ||
        uri.path.toLowerCase().contains('donate') ||
        uri.fragment.toLowerCase().contains('donate');
    if (!looksLikeDonate && AppEnv.isProduction) {
      return 'Donation link does not point to the donate page.';
    }
    return null;
  }

  static Future<bool> openDonationPage({
    String? email,
    String? nameFirst,
    String? nameLast,
  }) async {
    final fromSession = donorDetailsFromAppSession();
    final url = buildDonationPageUrl(
      email: email ?? fromSession.email,
      nameFirst: nameFirst ?? fromSession.nameFirst,
      nameLast: nameLast ?? fromSession.nameLast,
    );
    final error = validateDonationUrl(url);
    if (error != null) {
      if (kDebugMode) {
        debugPrint('[ExternalDonationLauncher] blocked: $error ($url)');
      }
      return false;
    }

    final uri = Uri.parse(url);
    if (kDebugMode) {
      debugPrint('[ExternalDonationLauncher] opening $uri');
    }

    // Do not rely on canLaunchUrl alone — on Android 11+ it often returns
    // false when VIEW/https package visibility queries are missing or stale.
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[ExternalDonationLauncher] externalApplication failed: $e',
        );
      }
    }

    try {
      return await launchUrl(uri, mode: LaunchMode.platformDefault);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ExternalDonationLauncher] platformDefault failed: $e');
      }
      return false;
    }
  }
}
