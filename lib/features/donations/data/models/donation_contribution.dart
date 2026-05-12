// One row of the signed-in user's contribution history.
//
// Source: GET /api/v1/donations/contributions/my.
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
    this.createdAt,
    this.note,
  });

  final String id;
  final String contributionNumber;
  final num amount;
  final String currency;
  final ContributionStatus status;
  final String donationId;
  final String donationTitle;
  final String? reference;
  final DateTime? createdAt;
  final String? note;

  static String _str(dynamic v) => (v ?? '').toString().trim();

  factory DonationContribution.fromJson(Map<String, dynamic> json) {
    final donation = json['donation'];
    final donationMap =
        donation is Map<String, dynamic> ? donation : const <String, dynamic>{};
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
      reference: () {
        final s = _str(json['reference']);
        return s.isEmpty ? null : s;
      }(),
      createdAt: () {
        final s = _str(json['createdAt']);
        return s.isEmpty ? null : DateTime.tryParse(s);
      }(),
      note: () {
        final s = _str(json['note']);
        return s.isEmpty ? null : s;
      }(),
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
