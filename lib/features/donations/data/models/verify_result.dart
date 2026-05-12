// Response payload of GET /api/v1/payments/verify/:reference.
//
// Backend is idempotent — calling verify twice for the same reference yields
// `alreadyPaid: true` on the second call and the same payload, so the
// frontend can replay this freely.
import 'donation_contribution.dart';

enum VerifyStatus { success, failed, abandoned, unknown }

VerifyStatus _statusFromString(String? s) {
  switch ((s ?? '').toLowerCase()) {
    case 'success':
      return VerifyStatus.success;
    case 'failed':
      return VerifyStatus.failed;
    case 'abandoned':
      return VerifyStatus.abandoned;
    default:
      return VerifyStatus.unknown;
  }
}

class VerifyResult {
  const VerifyResult({
    required this.status,
    required this.alreadyPaid,
    required this.reference,
    this.amount,
    this.currency,
    this.contribution,
  });

  final VerifyStatus status;
  final bool alreadyPaid;
  final String reference;
  final num? amount;
  final String? currency;
  final DonationContribution? contribution;

  bool get isPaid => status == VerifyStatus.success;

  static String _str(dynamic v) => (v ?? '').toString().trim();

  factory VerifyResult.fromJson(
    Map<String, dynamic> raw, {
    String? fallbackReference,
  }) {
    final root = (raw['data'] is Map<String, dynamic>)
        ? raw['data'] as Map<String, dynamic>
        : raw;

    final payment = root['payment'];
    final paymentMap =
        payment is Map<String, dynamic> ? payment : const <String, dynamic>{};

    final contribRaw = root['contribution'];
    final contribution = contribRaw is Map<String, dynamic>
        ? DonationContribution.fromJson(contribRaw)
        : null;

    return VerifyResult(
      status: _statusFromString(_str(root['status'])),
      alreadyPaid: root['alreadyPaid'] == true,
      reference: _str(root['reference']).isNotEmpty
          ? _str(root['reference'])
          : _str(paymentMap['reference']).isNotEmpty
              ? _str(paymentMap['reference'])
              : (fallbackReference ?? ''),
      amount: () {
        final v = paymentMap['amount'] ?? root['amount'];
        if (v is num) return v;
        return num.tryParse(_str(v));
      }(),
      currency: () {
        final s = _str(paymentMap['currency'] ?? root['currency']);
        return s.isEmpty ? null : s;
      }(),
      contribution: contribution,
    );
  }
}
