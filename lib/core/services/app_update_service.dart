// lib/core/services/app_update_service.dart

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:satya_devotte_app/shared/widgets/app_update_popup.dart';

/// Holds parsed update status comparing local installed build vs store listing.
class AppUpdateInfo {
  final bool isUpdateAvailable;
  final String currentVersion;
  final String storeVersion;
  final String? releaseNotes;
  final String? storeUrl;
  final bool isMandatory;

  const AppUpdateInfo({
    required this.isUpdateAvailable,
    required this.currentVersion,
    required this.storeVersion,
    this.releaseNotes,
    this.storeUrl,
    this.isMandatory = true,
  });

  @override
  String toString() {
    return 'AppUpdateInfo(isUpdateAvailable: $isUpdateAvailable, current: $currentVersion, store: $storeVersion, url: $storeUrl)';
  }
}

/// Service that handles version checking and platform-aware update prompting.
///
/// - On Android: Native Google Play Core (`UpdateManager.kt`) manages in-app
///   flexible/immediate updates via Play Store services.
/// - On iOS: Apple does not provide a native in-app update API. This service
///   queries the Apple iTunes Lookup API (`itunes.apple.com/lookup?bundleId=...`),
///   performs numerical version comparison, and prompts the user to update via
///   the App Store when a newer version is published.
class AppUpdateService {
  AppUpdateService._();

  static const String iosBundleId = 'com.sathya.app';
  static const String androidPackageName = 'com.satya_devotte_app';

  /// App Store Connect track id (used when bundleId lookup is storefront-empty).
  static const String iosAppStoreId = '6815970877';

  /// Storefronts where Sathya may be published. Default iTunes lookup (US) often
  /// returns `resultCount: 0` for region-limited apps — then no update popup.
  static const List<String> _iosLookupCountries = [
    'za',
    'in',
    'us',
    'gb',
    'ae',
    'au',
    'ca',
  ];

  /// Throttling cache to avoid hammering store APIs on every frame/resume.
  static DateTime? _lastCheckTime;
  static bool _isDialogShowing = false;

  /// Checks if [storeVersion] is strictly newer than [currentVersion].
  ///
  /// iOS App Store Lookup only exposes the marketing / sub-version
  /// (`CFBundleShortVersionString`, e.g. `1.0.1`). Compare those segments
  /// numerically. Build numbers (`+23`) are ignored here — Apple does not
  /// publish CFBundleVersion via the Lookup API.
  ///
  /// Examples:
  /// - `1.0.1` > `1.0.0` -> true
  /// - `1.1.0` > `1.0.9` -> true
  /// - `2.0.0` > `1.9.9` -> true
  /// - `1.0.0` == `1.0.0` -> false
  /// - `1.2` vs `1.2.1` -> true
  static bool isVersionNewer(String currentVersion, String storeVersion) {
    if (storeVersion.trim().isEmpty) return false;
    if (currentVersion.trim().isEmpty) return true;

    try {
      // Strip any Flutter-style `+build` suffix; App Store never returns it.
      final cleanCurrent = currentVersion.split('+').first.trim();
      final cleanStore = storeVersion.split('+').first.trim();

      final currentParts = cleanCurrent
          .split('.')
          .map(
            (e) =>
                int.tryParse(RegExp(r'\d+').firstMatch(e)?.group(0) ?? '') ?? 0,
          )
          .toList();
      final storeParts = cleanStore
          .split('.')
          .map(
            (e) =>
                int.tryParse(RegExp(r'\d+').firstMatch(e)?.group(0) ?? '') ?? 0,
          )
          .toList();

      final length = math.max(currentParts.length, storeParts.length);
      for (var i = 0; i < length; i++) {
        final currentSegment = i < currentParts.length ? currentParts[i] : 0;
        final storeSegment = i < storeParts.length ? storeParts[i] : 0;

        if (storeSegment > currentSegment) {
          return true;
        } else if (storeSegment < currentSegment) {
          return false;
        }
      }

      return false;
    } catch (e) {
      debugPrint(
        '[AppUpdateService] Error comparing versions ($currentVersion vs $storeVersion): $e',
      );
      return false;
    }
  }

  /// Queries the Apple iTunes Lookup API for the latest approved App Store version.
  ///
  /// Compares installed marketing / sub-version (`packageInfo.version`) against
  /// `results[0].version`. Build number is logged only; it is not part of the
  /// App Store update decision.
  ///
  /// Set [simulatedStoreVersion] for debugging/testing the update prompt.
  static Future<AppUpdateInfo?> checkIosUpdate({
    String bundleId = iosBundleId,
    String? simulatedStoreVersion,
  }) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version.trim().isNotEmpty
          ? packageInfo.version.trim()
          : '1.0.0';
      final buildNumber = packageInfo.buildNumber.trim();

      // Testing override
      if (simulatedStoreVersion != null && simulatedStoreVersion.isNotEmpty) {
        final isNewer = isVersionNewer(currentVersion, simulatedStoreVersion);
        return AppUpdateInfo(
          isUpdateAvailable: isNewer,
          currentVersion: currentVersion,
          storeVersion: simulatedStoreVersion,
          releaseNotes:
              'New features, performance enhancements, and bug fixes for the best experience.',
          storeUrl: 'https://apps.apple.com/app/id6815970877',
        );
      }

      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
        ),
      );

      final storeData = await _lookupIosStoreListing(
        dio: dio,
        bundleId: bundleId,
      );
      if (storeData == null) {
        debugPrint(
          '[AppUpdateService] No published App Store listing found for $bundleId '
          '(tried device locale + ${_iosLookupCountries.join(", ")}).',
        );
        return null;
      }

      final storeVersion = storeData['version']?.toString() ?? '';
      final releaseNotes = storeData['releaseNotes']?.toString() ?? '';
      final trackViewUrl =
          storeData['trackViewUrl']?.toString() ??
          'https://apps.apple.com/app/sathya/id${storeData["trackId"] ?? iosAppStoreId}';

      final isNewer = isVersionNewer(currentVersion, storeVersion);
      debugPrint(
        '[AppUpdateService] iOS Check: Installed=$currentVersion (build $buildNumber), '
        'AppStore=$storeVersion, UpdateAvailable=$isNewer',
      );

      return AppUpdateInfo(
        isUpdateAvailable: isNewer,
        currentVersion: currentVersion,
        storeVersion: storeVersion,
        releaseNotes: releaseNotes,
        storeUrl: trackViewUrl,
      );
    } catch (e) {
      debugPrint('[AppUpdateService] Error checking iOS App Store update: $e');
      return null;
    }
  }

  /// iTunes Lookup is storefront-scoped. Apps only listed in ZA/IN/etc. return
  /// empty `results` on the default (US) endpoint — so we try several countries.
  static Future<Map?> _lookupIosStoreListing({
    required Dio dio,
    required String bundleId,
  }) async {
    final countries = <String>{};

    final localeCountry =
        WidgetsBinding.instance.platformDispatcher.locale.countryCode;
    if (localeCountry != null && localeCountry.trim().length == 2) {
      countries.add(localeCountry.trim().toLowerCase());
    }
    countries.addAll(_iosLookupCountries);

    for (final country in countries) {
      final byBundle = await _itunesGet(
        dio,
        'https://itunes.apple.com/$country/lookup?bundleId=$bundleId',
      );
      if (byBundle != null) return byBundle;

      final byId = await _itunesGet(
        dio,
        'https://itunes.apple.com/$country/lookup?id=$iosAppStoreId',
      );
      if (byId != null) return byId;
    }

    // Last resort: country-less lookup (US index).
    return _itunesGet(
      dio,
      'https://itunes.apple.com/lookup?bundleId=$bundleId',
    );
  }

  static Future<Map?> _itunesGet(Dio dio, String url) async {
    try {
      final response = await dio.get<dynamic>(url);
      if (response.statusCode != 200 || response.data == null) return null;

      // iTunes serves `Content-Type: text/javascript`, so Dio often returns a
      // String body — not a decoded Map. Parse JSON explicitly.
      final payload = _asJsonMap(response.data);
      if (payload == null) return null;

      final results = payload['results'];
      if (results is! List || results.isEmpty) return null;
      final first = results.first;
      if (first is Map<String, dynamic>) return first;
      if (first is Map) return Map<String, dynamic>.from(first);
      return null;
    } catch (e) {
      debugPrint('[AppUpdateService] iTunes lookup failed ($url): $e');
      return null;
    }
  }

  static Map<String, dynamic>? _asJsonMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String) {
      final trimmed = data.trim();
      if (trimmed.isEmpty) return null;
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Automatically checks for updates and displays the update dialog if a newer
  /// version is available.
  ///
  /// - Only runs on iOS (Android updates are handled by Google Play native `UpdateManager.kt`).
  /// - Throttled to once every 2 hours unless [forceCheck] is true.
  static Future<void> checkAndPromptIfAvailable(
    BuildContext context, {
    bool isMandatory = true,
    bool forceCheck = false,
    String? simulatedStoreVersion,
  }) async {
    if (kIsWeb) return;

    // Android has native In-App Updates in MainActivity.kt
    if (!Platform.isIOS && simulatedStoreVersion == null) {
      return;
    }

    if (!forceCheck && _lastCheckTime != null) {
      final diff = DateTime.now().difference(_lastCheckTime!);
      if (diff.inHours < 2) {
        return;
      }
    }

    final updateInfo = await checkIosUpdate(
      simulatedStoreVersion: simulatedStoreVersion,
    );

    // Only throttle after a successful store lookup. Empty storefront results
    // must not block retries for 2 hours.
    if (updateInfo != null) {
      _lastCheckTime = DateTime.now();
    }

    if (updateInfo == null || !updateInfo.isUpdateAvailable) {
      return;
    }

    if (!context.mounted || _isDialogShowing) return;
    _isDialogShowing = true;

    try {
      await showAppUpdateDialog(
        context,
        appName: 'Sathya',
        releaseNotes: updateInfo.releaseNotes,
        storeUrl: updateInfo.storeUrl,
        isMandatory: isMandatory,
      );
    } finally {
      _isDialogShowing = false;
    }
  }

  /// Convenience method for testing and verifying the update popup immediately
  /// on a physical device or simulator.
  /// Simulates that the App Store has a higher version (e.g. `2.0.0`).
  static Future<void> testTriggerPopup(
    BuildContext context, {
    String simulatedVersion = '2.0.0',
    bool isMandatory = true,
  }) async {
    await checkAndPromptIfAvailable(
      context,
      forceCheck: true,
      simulatedStoreVersion: simulatedVersion,
      isMandatory: isMandatory,
    );
  }
}
