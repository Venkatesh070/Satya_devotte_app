import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';

/// One-shot location for Pooja Kit checkout only.
///
/// Called when the user taps **Use current location** on the delivery map.
/// Requests **when-in-use** permission only — never background / always-on
/// tracking, and never used outside that ecommerce flow.
class LocationService {
  Future<Position> getCurrentPosition() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw Exception('Please turn on location services and try again.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Geolocator.requestPermission() prompts for When In Use on iOS/Android.
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw Exception('Please allow location permission to continue.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission is blocked. Enable it from app settings.',
      );
    }
    // unableToDetermine / denied already handled; whileInUse and always both
    // allow a single foreground read. We never call openAppSettings to upgrade
    // to Always, and never start a position stream.

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: _foregroundOneShotSettings(),
      );
    } on TimeoutException {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) return lastKnown;
      throw Exception('Location request timed out. Please try again.');
    }
  }

  /// Foreground, one-shot settings — background updates explicitly disabled.
  LocationSettings _foregroundOneShotSettings() {
    const timeLimit = Duration(seconds: 15);
    if (!kIsWeb && Platform.isIOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.other,
        distanceFilter: 0,
        timeLimit: timeLimit,
        pauseLocationUpdatesAutomatically: true,
        showBackgroundLocationIndicator: false,
        allowBackgroundLocationUpdates: false,
      );
    }
    if (!kIsWeb && Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        timeLimit: timeLimit,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      timeLimit: timeLimit,
    );
  }
}
