import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/core/services/location_service.dart';

/// Shop (Pooja Kit) is available only when GPS places the user in South Africa.
///
/// Default is **hidden** until a successful GPS + reverse-geocode confirms `ZA`.
/// Permission denied, GPS off, timeout, or non-ZA country → Shop stays hidden.
class ShopRegionAccess extends GetxService {
  static const String southAfricaCountryCode = 'ZA';
  static const Duration _cacheTtl = Duration(minutes: 45);

  final RxBool isShopAvailable = false.obs;
  final RxBool isChecking = false.obs;

  DateTime? _lastResolvedAt;
  bool? _lastResult;

  /// Registers the service if hot-reload / late binding skipped [InitialBinding].
  static ShopRegionAccess ensureRegistered() {
    if (!Get.isRegistered<ShopRegionAccess>()) {
      Get.put<ShopRegionAccess>(ShopRegionAccess(), permanent: true);
    }
    return Get.find<ShopRegionAccess>();
  }

  static ShopRegionAccess get instance => ensureRegistered();

  /// Sync read for route guards / one-off checks. `false` until GPS confirms ZA.
  static bool get available =>
      ensureRegistered().isShopAvailable.value;

  /// Resolves physical country via one-shot foreground GPS + reverse geocode.
  Future<void> resolve({bool force = false}) async {
    if (isChecking.value) return;

    if (!force &&
        _lastResolvedAt != null &&
        _lastResult != null &&
        DateTime.now().difference(_lastResolvedAt!) < _cacheTtl) {
      isShopAvailable.value = _lastResult!;
      return;
    }

    isChecking.value = true;
    try {
      if (!Get.isRegistered<LocationService>()) {
        Get.put<LocationService>(LocationService(), permanent: true);
      }

      final position = await Get.find<LocationService>().getCurrentPosition();
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isEmpty) {
        debugPrint('[ShopRegion] No placemarks for GPS fix');
        _setResult(false);
        return;
      }

      final place = placemarks.first;
      final code = (place.isoCountryCode ?? '').trim().toUpperCase();
      final name = (place.country ?? '').trim().toLowerCase();
      final inSouthAfrica = code == southAfricaCountryCode ||
          name == 'south africa' ||
          name.contains('south africa');

      debugPrint(
        '[ShopRegion] GPS countryCode=$code country=${place.country} '
        'shopAvailable=$inSouthAfrica',
      );
      _setResult(inSouthAfrica);
    } catch (e) {
      debugPrint('[ShopRegion] GPS resolve failed: $e');
      // Physically unverified → keep Shop hidden.
      _setResult(false);
    } finally {
      isChecking.value = false;
    }
  }

  void _setResult(bool value) {
    _lastResult = value;
    _lastResolvedAt = DateTime.now();
    isShopAvailable.value = value;
  }
}
