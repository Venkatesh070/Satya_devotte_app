// Orchestrates the per-donation Paystack flow:
//   • initiate → cache `DonationInitData`
//   • verify   → cache `VerifyResult`, with exponential-backoff retries
//                on transient transport errors (backend is idempotent).
import 'dart:async';

import 'package:get/get.dart';

import 'package:satya_devotte_app/features/donations/data/donation_exception.dart';
import 'package:satya_devotte_app/features/donations/data/donations_repository.dart';
import 'package:satya_devotte_app/features/donations/data/models/donation_init_data.dart';
import 'package:satya_devotte_app/features/donations/data/models/verify_result.dart';

class DonateController extends GetxController {
  DonateController(this._repo);
  final DonationsRepository _repo;

  final _initiating = false.obs;
  final _verifying = false.obs;
  final _initData = Rxn<DonationInitData>();
  final _verifyResult = Rxn<VerifyResult>();
  final _lastError = RxnString();

  bool get isInitiating => _initiating.value;
  bool get isVerifying => _verifying.value;
  DonationInitData? get initData => _initData.value;
  VerifyResult? get verifyResult => _verifyResult.value;
  String? get lastError => _lastError.value;

  /// Resets transient state so a screen entering the flow starts clean.
  void reset() {
    _initData.value = null;
    _verifyResult.value = null;
    _lastError.value = null;
    _initiating.value = false;
    _verifying.value = false;
  }

  Future<DonationInitData?> initiate({
    String? donationId,
    required num amount,
    String currency = 'ZAR',
    String? note,
    String? callbackUrl,
  }) async {
    _initiating.value = true;
    _lastError.value = null;
    try {
      final data = await _repo.initiateDonation(
        donationId: donationId,
        amount: amount,
        currency: currency,
        note: note,
        callbackUrl: callbackUrl,
      );
      _initData.value = data;
      return data;
    } on DonationException catch (e) {
      _lastError.value = e.message;
      return null;
    } catch (_) {
      _lastError.value = 'Could not start the donation. Please try again.';
      return null;
    } finally {
      _initiating.value = false;
    }
  }

  /// Verifies a reference. Retries on transient errors up to 3 attempts
  /// with backoff: 1s, 2s, 4s. Backend verify is idempotent, so retrying
  /// is always safe. Returns `null` if all attempts fail.
  Future<VerifyResult?> verify(String reference) async {
    _verifying.value = true;
    _lastError.value = null;
    const delays = [
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 4),
    ];
    try {
      DonationException? lastErr;
      for (var attempt = 0; attempt < delays.length; attempt++) {
        try {
          final result = await _repo.verifyPayment(reference);
          _verifyResult.value = result;
          return result;
        } on DonationException catch (e) {
          lastErr = e;
          // Don't retry obvious 4xx terminal failures.
          final code = e.statusCode ?? 0;
          if (code >= 400 && code < 500 && code != 408 && code != 429) {
            break;
          }
          await Future.delayed(delays[attempt]);
        }
      }
      _lastError.value =
          lastErr?.message ?? 'Could not verify the payment. Please try again.';
      return null;
    } finally {
      _verifying.value = false;
    }
  }
}
