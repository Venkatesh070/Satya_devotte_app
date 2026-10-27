// lib/core/services/app_update_service.dart

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

  /// Throttling cache to avoid hammering store APIs on every frame/resume.
  static DateTime? _lastCheckTime;
  static bool _isDialogShowing = false;

  /// Checks if [storeVersion] is strictly newer than [currentVersion].
  /// Handles semantic versioning like:
  /// - `1.0.1` > `1.0.0` -> true
  /// - `1.1.0` > `1.0.9` -> true
  /// - `2.0.0` > `1.9.9` -> true
  /// - `1.0.0` == `1.0.0` -> false
  /// - `1.0.0+24` > `1.0.0+23` -> true
  static bool isVersionNewer(String currentVersion, String storeVersion) {
    if (storeVersion.trim().isEmpty) return false;
    if (currentVersion.trim().isEmpty) return true;

    try {
      final cleanCurrent = currentVersion.split('+').first.trim();
      final cleanStore = storeVersion.split('+').first.trim();

      final currentParts = cleanCurrent
          .split('.')
          .map((e) => int.tryParse(RegExp(r'\d+').firstMatch(e)?.group(0) ?? '') ?? 0)
          .toList();
      final storeParts = cleanStore
          .split('.')
          .map((e) => int.tryParse(RegExp(r'\d+').firstMatch(e)?.group(0) ?? '') ?? 0)
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

      // If semantic versions match, compare build numbers if present (e.g. 1.0.0+24 vs 1.0.0+23)
      final currentBuild = _extractBuildNumber(currentVersion);
      final storeBuild = _extractBuildNumber(storeVersion);
      if (currentBuild != null && storeBuild != null && storeBuild > currentBuild) {
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('[AppUpdateService] Error comparing versions ($currentVersion vs $storeVersion): $e');
      return false;
    }
  }

  static int? _extractBuildNumber(String fullVersion) {
    if (!fullVersion.contains('+')) return null;
    final part = fullVersion.split('+').last.trim();
    return int.tryParse(part);
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
      final fullCurrent = buildNumber.isNotEmpty ? '$currentVersion+$buildNumber' : currentVersion;

      // Testing override
      if (simulatedStoreVersion != null && simulatedStoreVersion.isNotEmpty) {
        final isNewer = isVersionNewer(fullCurrent, simulatedStoreVersion);
        return AppUpdateInfo(
          isUpdateAvailable: isNewer,
          currentVersion: fullCurrent,
          storeVersion: simulatedStoreVersion,
          releaseNotes:
              'New features, performance enhancements, and bug fixes for the best experience.',
          storeUrl: 'https://apps.apple.com/app/sathya/id123456789',
        );
      }

      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
        ),
      );

      final url = 'https://itunes.apple.com/lookup?bundleId=$bundleId';
      final response = await dio.get<dynamic>(url);

      if (response.statusCode != 200 || response.data == null) {
        debugPrint('[AppUpdateService] iTunes lookup returned status ${response.statusCode}');
        return null;
      }

      final dynamic data = response.data;
      if (data is! Map) return null;

      final results = data['results'] as List?;
      if (results == null || results.isEmpty) {
        debugPrint('[AppUpdateService] No published App Store listing found yet for $bundleId.');
        return null;
      }

      final storeData = results.first as Map;
      final storeVersion = storeData['version']?.toString() ?? '';
      final releaseNotes = storeData['releaseNotes']?.toString() ?? '';
      final trackViewUrl = storeData['trackViewUrl']?.toString() ??
          'https://apps.apple.com/app/sathya/id${storeData["trackId"]}';

      final isNewer = isVersionNewer(fullCurrent, storeVersion);
      debugPrint(
        '[AppUpdateService] iOS Check: Installed=$fullCurrent, AppStore=$storeVersion, UpdateAvailable=$isNewer',
      );

      return AppUpdateInfo(
        isUpdateAvailable: isNewer,
        currentVersion: fullCurrent,
        storeVersion: storeVersion,
        releaseNotes: releaseNotes,
        storeUrl: trackViewUrl,
      );
    } catch (e) {
      debugPrint('[AppUpdateService] Error checking iOS App Store update: $e');
      return null;
    }
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

    _lastCheckTime = DateTime.now();

    final updateInfo = await checkIosUpdate(
      simulatedStoreVersion: simulatedStoreVersion,
    );

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
