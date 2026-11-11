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
///   queries the Apple iTunes Lookup API, performs numerical version comparison,
///   and prompts the user to update via the App Store when a newer version is
///   published.
///
/// iTunes Lookup is **storefront-scoped**. Apps not listed in the US return
/// `resultCount: 0` on the default endpoint. We therefore probe the device
/// locale plus known available storefronts (and a broad fallback list) until
/// one listing is found. The marketing version is the same across storefronts;
/// the Update button opens a **country-neutral** App Store URL so Apple routes
/// the user to their local store.
class AppUpdateService {
  AppUpdateService._();

  static const String iosBundleId = 'com.sathya.app';
  static const String androidPackageName = 'com.satya_devotte_app';

  /// App Store Connect track id.
  static const String iosAppStoreId = '6815970877';

  /// Country-neutral listing URL — Apple redirects to the user's storefront.
  static const String iosStoreUrl = 'https://apps.apple.com/app/id$iosAppStoreId';

  /// Storefronts where Sathya is known to be available. Always tried early so
  /// devices in US/GB/etc. still discover the live version.
  static const List<String> _priorityLookupCountries = [
    'za',
    'in',
    'ae',
  ];

  /// Broader fallback storefronts (ISO 3166-1 alpha-2). First successful hit wins.
  static const List<String> _fallbackLookupCountries = [
    'us',
    'gb',
    'au',
    'ca',
    'nz',
    'ie',
    'sg',
    'my',
    'ph',
    'id',
    'th',
    'vn',
    'hk',
    'jp',
    'kr',
    'cn',
    'tw',
    'sa',
    'qa',
    'kw',
    'bh',
    'om',
    'eg',
    'ng',
    'ke',
    'gh',
    'tz',
    'ug',
    'mu',
    'de',
    'fr',
    'nl',
    'be',
    'ch',
    'at',
    'it',
    'es',
    'pt',
    'se',
    'no',
    'dk',
    'fi',
    'pl',
    'cz',
    'ro',
    'hu',
    'gr',
    'tr',
    'il',
    'br',
    'mx',
    'ar',
    'cl',
    'co',
    'pe',
  ];

  static const int _lookupBatchSize = 6;

  /// Throttling cache to avoid hammering store APIs on every frame/resume.
  static DateTime? _lastCheckTime;
  static bool _isDialogShowing = false;

  /// Last storefront that returned a listing — reused first on the next check.
  static String? _lastSuccessfulCountry;

  /// Checks if [storeVersion] is strictly newer than [currentVersion].
  ///
  /// iOS App Store Lookup only exposes the marketing / sub-version
  /// (`CFBundleShortVersionString`, e.g. `1.0.1`). Compare those segments
  /// numerically. Build numbers (`+23`) are ignored here — Apple does not
  /// publish CFBundleVersion via the Lookup API.
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
          storeUrl: iosStoreUrl,
        );
      }

      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
          // iTunes serves `text/javascript`; force plain so we always jsonDecode.
          responseType: ResponseType.plain,
          headers: const {
            'Accept': 'application/json,text/javascript,*/*',
            // iTunes CDN often serves a stale version right after a release.
            'Cache-Control': 'no-cache, no-store, must-revalidate',
            'Pragma': 'no-cache',
          },
        ),
      );

      final storeData = await _lookupIosStoreListing(
        dio: dio,
        bundleId: bundleId,
      );
      if (storeData == null) {
        debugPrint(
          '[AppUpdateService] No published App Store listing found for $bundleId '
          '(tried device locale, priority + fallback storefronts).',
        );
        return null;
      }

      final storeVersion = storeData['version']?.toString() ?? '';
      final releaseNotes = storeData['releaseNotes']?.toString() ?? '';
      // Prefer country-neutral URL so Update works in every App Store region.
      final trackViewUrl = iosStoreUrl;

      final isNewer = isVersionNewer(currentVersion, storeVersion);
      debugPrint(
        '[AppUpdateService] iOS Check: Installed=$currentVersion (build $buildNumber), '
        'AppStore=$storeVersion, UpdateAvailable=$isNewer, '
        'storefront=${_lastSuccessfulCountry ?? "unknown"}',
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

  /// Builds an ordered unique country list and probes storefronts in parallel
  /// batches until a listing is found.
  static Future<Map?> _lookupIosStoreListing({
    required Dio dio,
    required String bundleId,
  }) async {
    final countries = <String>[];

    void addCountry(String? code) {
      if (code == null) return;
      final normalized = code.trim().toLowerCase();
      if (normalized.length != 2) return;
      if (countries.contains(normalized)) return;
      countries.add(normalized);
    }

    // 1) Last successful storefront (fast path after first hit).
    addCountry(_lastSuccessfulCountry);

    // 2) Known available markets — critical for users whose locale is US/GB.
    for (final c in _priorityLookupCountries) {
      addCountry(c);
    }

    // 3) Device locale.
    final localeCountry =
        WidgetsBinding.instance.platformDispatcher.locale.countryCode;
    addCountry(localeCountry);

    // 4) Broad fallbacks for any other published territory.
    for (final c in _fallbackLookupCountries) {
      addCountry(c);
    }

    for (var i = 0; i < countries.length; i += _lookupBatchSize) {
      final end = math.min(i + _lookupBatchSize, countries.length);
      final batch = countries.sublist(i, end);
      final hit = await _lookupCountryBatch(
        dio: dio,
        bundleId: bundleId,
        countries: batch,
      );
      if (hit != null) return hit;
    }

    // Last resort: country-less lookup (US index) by bundle + id.
    final byBundle = await _itunesGet(
      dio,
      'https://itunes.apple.com/lookup?bundleId=$bundleId',
    );
    if (byBundle != null) return byBundle;

    return _itunesGet(
      dio,
      'https://itunes.apple.com/lookup?id=$iosAppStoreId',
    );
  }

  /// Runs lookups for a batch of countries in parallel; returns the first hit
  /// in batch order (priority preserved).
  static Future<Map?> _lookupCountryBatch({
    required Dio dio,
    required String bundleId,
    required List<String> countries,
  }) async {
    final futures = countries.map((country) async {
      // Prefer track id — more stable than bundleId across storefronts.
      final byId = await _itunesGet(
        dio,
        'https://itunes.apple.com/$country/lookup?id=$iosAppStoreId',
      );
      if (byId != null) return MapEntry(country, byId);

      final byBundle = await _itunesGet(
        dio,
        'https://itunes.apple.com/$country/lookup?bundleId=$bundleId',
      );
      if (byBundle != null) return MapEntry(country, byBundle);

      return null;
    });

    final results = await Future.wait(futures);
    for (final entry in results) {
      if (entry == null) continue;
      _lastSuccessfulCountry = entry.key;
      debugPrint(
        '[AppUpdateService] App Store listing found via storefront=${entry.key}',
      );
      return entry.value;
    }
    return null;
  }

  static Future<Map?> _itunesGet(Dio dio, String url) async {
    try {
      // Cache-bust: Apple's lookup CDN can keep serving the previous version
      // for a while after a new App Store release (we saw 1.0.0 while ZA had
      // 1.0.1 live). A unique query param forces a fresh edge response.
      final separator = url.contains('?') ? '&' : '?';
      final bustedUrl =
          '$url${separator}_=${DateTime.now().millisecondsSinceEpoch}';

      final response = await dio.get<dynamic>(
        bustedUrl,
        options: Options(
          headers: const {
            'Cache-Control': 'no-cache, no-store, must-revalidate',
            'Pragma': 'no-cache',
          },
        ),
      );
      if (response.statusCode != 200 || response.data == null) return null;

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

    // Skip App Store update prompt while developing (flutter run / debug).
    if (kDebugMode && simulatedStoreVersion == null) {
      debugPrint('[AppUpdateService] Skipped in debug mode');
      return;
    }

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
        storeUrl: updateInfo.storeUrl ?? iosStoreUrl,
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
