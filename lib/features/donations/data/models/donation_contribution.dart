// One row of a contribution.
//
// Sources:
//   • GET /api/v1/donations/contributions/my   (user-facing)
//   • GET /api/v1/donations/contributions/all  (admin / super-admin)
//
// The admin endpoint populates the contributor under `user` — those
// fields are optional here so the same model serves both views.
import 'package:intl/intl.dart';

enum ContributionStatus { paid, pending, failed }

ContributionStatus _statusFromString(String? s) {
  switch ((s ?? '').toUpperCase()) {
    case 'PAID':
    case 'SUCCESS':
      return ContributionStatus.paid;
    case 'FAILED':
    case 'ABANDONED':
      return ContributionStatus.failed;
    default:
      return ContributionStatus.pending;
  }
}

class DonationContribution {
  const DonationContribution({
    required this.id,
    required this.contributionNumber,
    required this.amount,
    required this.currency,
    required this.status,
    required this.donationId,
    required this.donationTitle,
    this.reference,
    this.transactionId,
    this.createdAt,
    this.note,
    this.donorId,
    this.donorName,
    this.donorEmail,
  });

  final String id;
  final String contributionNumber;
  final num amount;
  final String currency;
  final ContributionStatus status;
  final String donationId;
  final String donationTitle;
  final String? reference;
  /// Gateway / processor transaction id (e.g. Paystack transaction id).
  final String? transactionId;
  final DateTime? createdAt;
  final String? note;

  /// Populated only on the admin `/contributions/all` response.
  final String? donorId;
  final String? donorName;
  final String? donorEmail;

  static String _str(dynamic v) => (v ?? '').toString().trim();

  static String? _nullableStr(dynamic v) {
    final s = _str(v);
    return s.isEmpty ? null : s;
  }

  factory DonationContribution.fromJson(Map<String, dynamic> json) {
    final donation = json['donation'];
    final donationMap =
        donation is Map<String, dynamic> ? donation : const <String, dynamic>{};
    final user = json['user'];
    final userMap = user is Map<String, dynamic>
        ? user
        : const <String, dynamic>{};
    final paymentStatus = _str(json['paymentStatus']).isNotEmpty
        ? _str(json['paymentStatus'])
        : _str(json['status']);
    return DonationContribution(
      id: _str(json['_id'] ?? json['id']),
      contributionNumber: _str(json['contributionNumber']),
      amount: (json['amount'] is num)
          ? json['amount'] as num
          : num.tryParse(_str(json['amount'])) ?? 0,
      currency: _str(json['currency']).isEmpty
          ? 'ZAR'
          : _str(json['currency']),
      status: _statusFromString(paymentStatus),
      donationId: _str(donationMap['_id'] ??
          donationMap['id'] ??
          json['donationId']),
      donationTitle: _str(donationMap['title'] ?? donationMap['name']),
      reference: _nullableStr(
        json['reference'] ?? json['paystackReference'],
      ),
      transactionId: _nullableStr(json['transactionId']),
      createdAt: () {
        final s = _str(json['createdAt']);
        return s.isEmpty ? null : DateTime.tryParse(s);
      }(),
      note: _nullableStr(json['note']),
      // Admin-only fields. Tolerate either a flat string id (`user: "abc"`)
      // or a populated object, and accept multiple common name keys.
      donorId: user is String
          ? _nullableStr(user)
          : _nullableStr(userMap['_id'] ?? userMap['id'] ?? json['userId']),
      donorName: _nullableStr(
        userMap['displayName'] ??
            userMap['name'] ??
            userMap['fullName'] ??
            (() {
              final fn = _str(userMap['firstName']);
              final ln = _str(userMap['lastName']);
              final joined = [fn, ln].where((s) => s.isNotEmpty).join(' ');
              return joined.isEmpty ? null : joined;
            }()),
      ),
      donorEmail: _nullableStr(userMap['email']),
    );
  }

  String get formattedAmount {
    final f = NumberFormat.currency(
      name: currency,
      symbol: '${currency == 'ZAR' ? 'R' : currency} ',
      decimalDigits: amount.truncateToDouble() == amount ? 0 : 2,
    );
    return f.format(amount);
  }

  String get formattedDate {
    if (createdAt == null) return '';
    return DateFormat('d MMM yyyy, h:mm a').format(createdAt!.toLocal());
  }
}
