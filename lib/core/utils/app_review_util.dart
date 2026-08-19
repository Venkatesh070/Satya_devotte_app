import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:satya_devotte_app/core/utils/toast_util.dart';

class AppReviewUtil {
  static const String _kReviewRequestedKey = 'has_requested_in_app_review';

  /// Prompts the user with the native in-app review bottom-sheet dialog on first attempt.
  /// On subsequent taps (after quota is reached or review is submitted), it opens
  /// the store listing directly so the review button always acts as expected.
  static Future<void> requestInAppReview({String? appStoreId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasRequested = prefs.getBool(_kReviewRequestedKey) ?? false;

      if (!hasRequested) {
        final InAppReview inAppReview = InAppReview.instance;
        if (await inAppReview.isAvailable()) {
          await prefs.setBool(_kReviewRequestedKey, true);
          await inAppReview.requestReview();
          return;
        }
      }
    } catch (e) {
      debugPrint('InAppReview request error: $e');
    }

    // Subsequent taps or fallback: open store listing page
    await openStoreReview(appStoreId: appStoreId);
  }



  /// Opens the App Store or Play Store listing page for reviewing the app.
  static Future<void> openStoreReview({String? appStoreId}) async {
    final InAppReview inAppReview = InAppReview.instance;

    try {
      if (await inAppReview.isAvailable()) {
        await inAppReview.openStoreListing(
          appStoreId: appStoreId,
        );
        return;
      }
    } catch (e) {
      debugPrint('InAppReview openStoreListing error: $e');
    }

    // Fallback store launcher using url_launcher
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      // If running under dev package ID (com.developer.sathya), use prod package ID for Play Store link
      String packageName = packageInfo.packageName.isNotEmpty
          ? packageInfo.packageName
          : 'com.satya_devotte_app';
          
      if (packageName == 'com.developer.sathya') {
        packageName = 'com.satya_devotte_app';
      }

      if (kIsWeb) {
        final webUrl = Uri.parse(
          'https://play.google.com/store/apps/details?id=$packageName',
        );
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      } else if (Platform.isAndroid) {
        final marketUri = Uri.parse('market://details?id=$packageName');
        final webUri = Uri.parse(
          'https://play.google.com/store/apps/details?id=$packageName',
        );

        if (await canLaunchUrl(marketUri)) {
          await launchUrl(marketUri, mode: LaunchMode.externalApplication);
        } else {
          await launchUrl(webUri, mode: LaunchMode.externalApplication);
        }
      } else if (Platform.isIOS) {
        final id = appStoreId ?? '';
        final iosUri = id.isNotEmpty
            ? Uri.parse(
                'itms-apps://itunes.apple.com/app/id$id?action=write-review',
              )
            : Uri.parse(
                'https://apps.apple.com/app',
              );
        if (await canLaunchUrl(iosUri)) {
          await launchUrl(iosUri, mode: LaunchMode.externalApplication);
        } else {
          ToastUtil.showInfo('Could not open App Store review page.');
        }
      } else {
        final webUri = Uri.parse(
          'https://play.google.com/store/apps/details?id=$packageName',
        );
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error opening store review: $e');
      ToastUtil.showInfo('Could not open store review page. Please try again.');
    }
  }

}



